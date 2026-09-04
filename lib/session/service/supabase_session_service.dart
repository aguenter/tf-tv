import 'dart:async';
import 'dart:developer' as dev;

import 'package:supabase/supabase.dart' hide Session;

import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/session.dart';
import '../model/vote.dart';
import 'session_service.dart';

class SupabaseSessionService implements SessionService {
  SupabaseSessionService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;
  final _controller = StreamController<SessionUpdate>.broadcast();
  Session? _session;
  RealtimeChannel? _channel;

  // Cached workout data — loaded once on first phase change per workout.
  String? _cachedWorkoutId;
  String? _cachedWorkoutName;
  List<Exercise> _cachedExercises = [];

  @override
  Stream<SessionUpdate> get updates => _controller.stream;

  @override
  Session? get session => _session;

  @override
  Future<Session> createSession() async {
    await _unsubscribe();
    _clearWorkoutCache();

    final sessionId =
        await _client.rpc<String>('create_session');

    dev.log('Session created: $sessionId', name: 'Realtime');
    // ignore: avoid_print
    print('TEAMFIT_SESSION_ID=$sessionId');

    _session = Session(
      id: sessionId,
      status: SessionStatus.waiting,
    );

    await _subscribe(sessionId);
    return _session!;
  }

  @override
  Future<void> advancePhase() async {
    if (_session == null) return;
    await _client.rpc('advance_phase', params: {
      'p_session_id': _session!.id,
    });
  }

  @override
  Future<void> endSession() async {
    if (_session == null) return;
    await _client.rpc('end_session', params: {
      'p_session_id': _session!.id,
    });
  }

  Future<void> _subscribe(String sessionId) async {
    _channel = _client.channel('session:$sessionId');

    _channel!.onPresenceSync((payload) {
      dev.log('Presence sync fired', name: 'Realtime');
      _fetchParticipants(sessionId);
    });

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (payload) {
        dev.log('Postgres INSERT on participants: ${payload.newRecord}',
            name: 'Realtime');
        _fetchParticipants(sessionId);
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'sessions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: sessionId,
      ),
      callback: (payload) {
        dev.log('Postgres UPDATE on sessions: ${payload.newRecord}',
            name: 'Realtime');
        _onSessionChanged(payload.newRecord);
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'votes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (payload) {
        dev.log('Postgres change on votes: ${payload.newRecord}',
            name: 'Realtime');
        _fetchVotes(sessionId);
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'results',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: sessionId,
      ),
      callback: (payload) {
        dev.log('Postgres change on results: ${payload.newRecord}',
            name: 'Realtime');
        _onResultChanged(payload.newRecord, sessionId);
      },
    );

    _channel!.subscribe((status, [error]) async {
      dev.log('Channel status: $status (error: $error)', name: 'Realtime');
      if (status == RealtimeSubscribeStatus.subscribed) {
        dev.log('Subscribed — tracking TV presence', name: 'Realtime');
        await _channel!.track({'device': 'tv'});
        // ignore: avoid_print
        print('TEAMFIT_READY');
      }
    });
  }

  Future<void> _fetchParticipants(String sessionId) async {
    dev.log('Fetching participants for $sessionId', name: 'Realtime');
    final rows = await _client
        .from('participants')
        .select()
        .eq('session_id', sessionId)
        .order('joined_at');

    final participants = rows.map<Participant>((row) {
      return Participant(
        id: row['id'] as String,
        displayName: row['display_name'] as String,
        initials: row['initials'] as String,
        role: row['role'] == 'trainer'
            ? ParticipantRole.trainer
            : ParticipantRole.participant,
      );
    }).toList();

    dev.log('Emitting ParticipantsChanged: ${participants.length} participants',
        name: 'Realtime');
    _controller.add(ParticipantsChanged(participants));
  }

  Future<void> _fetchVotes(String sessionId) async {
    dev.log('Fetching votes for $sessionId', name: 'Realtime');

    final rows = await _client
        .from('votes')
        .select('participant_id, workout_id')
        .eq('session_id', sessionId);

    final sessionRows = await _client
        .from('sessions')
        .select('trainer_participant_id')
        .eq('id', sessionId)
        .limit(1);

    final trainerId = sessionRows.isNotEmpty
        ? sessionRows.first['trainer_participant_id'] as String?
        : null;

    final Map<String, List<String>> votesByWorkout = {};
    String? trainerWorkoutId;

    for (final row in rows) {
      final workoutId = row['workout_id'] as String;
      final participantId = row['participant_id'] as String;
      votesByWorkout.putIfAbsent(workoutId, () => []).add(participantId);
      if (participantId == trainerId) {
        trainerWorkoutId = workoutId;
      }
    }

    final votes = votesByWorkout.entries
        .map((e) => Vote(workoutId: e.key, participantIds: e.value))
        .toList();

    dev.log('Emitting VotesChanged: ${votes.length} workouts voted on',
        name: 'Realtime');
    _controller.add(VotesChanged(
      votes: votes,
      trainerWorkoutId: trainerWorkoutId,
    ));
  }

  Future<void> _onSessionChanged(Map<String, dynamic> record) async {
    final status = record['status'] as String?;
    dev.log('_onSessionChanged: status=$status, record=$record',
        name: 'Realtime');

    if (status == 'ended') {
      _controller.add(const SessionEnded());
      return;
    }

    if (status == 'selecting') {
      dev.log('Emitting SelectionStarted', name: 'Realtime');
      _controller.add(const SelectionStarted());
      return;
    }

    final phase = record['phase'] as String?;
    if (phase == null) return;

    final sessionPhase = SessionPhase.values.firstWhere(
      (p) => p.name == phase,
      orElse: () => SessionPhase.countdown,
    );

    // Fetch workout context for exercise-driven phases.
    String? workoutName;
    Exercise? exercise;

    if (_session != null) {
      final workoutId = record['workout_id'] as String?;
      final exerciseIndex = record['current_exercise_index'] as int?;

      // Try record first; fall back to DB query if fields are missing.
      String? resolvedWorkoutId = workoutId;
      int resolvedIndex = exerciseIndex ?? 0;

      if (resolvedWorkoutId == null) {
        final sessionRows = await _client
            .from('sessions')
            .select('workout_id, current_exercise_index')
            .eq('id', _session!.id)
            .limit(1);
        if (sessionRows.isNotEmpty) {
          resolvedWorkoutId = sessionRows.first['workout_id'] as String?;
          resolvedIndex =
              sessionRows.first['current_exercise_index'] as int? ?? 0;
        }
      }

      if (resolvedWorkoutId != null) {
        await _ensureWorkoutCached(resolvedWorkoutId);
        workoutName = _cachedWorkoutName;
        if (resolvedIndex < _cachedExercises.length) {
          exercise = _cachedExercises[resolvedIndex];
        }
      }
    }

    dev.log(
        'Emitting PhaseChanged: $sessionPhase, workout=$workoutName, exercise=${exercise?.name}',
        name: 'Realtime');
    _controller.add(PhaseChanged(
      phase: sessionPhase,
      workoutName: workoutName,
      exercise: exercise,
    ));
  }

  Future<void> _ensureWorkoutCached(String workoutId) async {
    if (_cachedWorkoutId == workoutId) return;

    _cachedWorkoutId = workoutId;

    final workoutRows = await _client
        .from('workouts')
        .select('name')
        .eq('id', workoutId)
        .limit(1);
    _cachedWorkoutName =
        workoutRows.isNotEmpty ? workoutRows.first['name'] as String : null;

    final exerciseRows = await _client
        .from('exercises')
        .select()
        .eq('workout_id', workoutId)
        .order('sort_order', ascending: true);
    _cachedExercises =
        exerciseRows.map<Exercise>((row) => Exercise.fromRow(row)).toList();

    dev.log(
        'Cached workout "$_cachedWorkoutName" with ${_cachedExercises.length} exercises',
        name: 'Realtime');
  }

  Future<void> _onResultChanged(
    Map<String, dynamic> record,
    String sessionId,
  ) async {
    final participantId = record['participant_id'] as String?;
    final value = record['value'];
    if (participantId == null || value == null) return;

    final rows = await _client
        .from('participants')
        .select()
        .eq('id', participantId)
        .limit(1);

    if (rows.isEmpty) return;
    final row = rows.first;

    _controller.add(ResultSubmitted(
      participant: Participant(
        id: row['id'] as String,
        displayName: row['display_name'] as String,
        initials: row['initials'] as String,
        role: row['role'] == 'trainer'
            ? ParticipantRole.trainer
            : ParticipantRole.participant,
      ),
      value: value as int,
    ));
  }

  void _clearWorkoutCache() {
    _cachedWorkoutId = null;
    _cachedWorkoutName = null;
    _cachedExercises = [];
  }

  Future<void> _unsubscribe() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    _controller.close();
  }
}
