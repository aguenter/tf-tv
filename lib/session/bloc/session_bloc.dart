import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/shared/constants.dart';
import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/result.dart';
import '../model/session.dart';
import '../model/vote.dart';
import '../model/workout.dart';
import '../service/session_service.dart';
import '../service/workout_service.dart';
import 'session_event.dart';
import 'session_phase_clock.dart';
import 'session_state.dart';

/// Zustandsmaschine für den Session-Lebenszyklus T1–T7 (siehe
/// doc/3-TV.md).
///
/// Der Bloc ist der Session-Treiber: Er reagiert auf [SessionUpdateReceived]
/// (in Produktion: Supabase Realtime; im Skeleton: lokale Simulation) und
/// betreibt die Phasen über [SessionPhaseClock]. Timer-Abläufe werden als
/// Tick-Events ([CountdownTick], [ExerciseTick]) eingereiht – in bloc 9.x
/// darf der Handler-`Emitter` nur während des laufenden Handlers verwendet
/// werden, daher passieren alle Zustandsänderungen in Event-Handlern.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required SessionService sessionService,
    required WorkoutService workoutService,
  }) : _sessionService = sessionService,
       _workoutService = workoutService,
       super(const SessionCreatingState()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionUpdateReceived>(_onUpdateReceived);
    // Ticks und Wiedererscheinen laufen in dieselbe Neuberechnung: Die
    // Restzeit ergibt sich stets aus dem Ziel-Zeitpunkt, nicht aus einem
    // Herunterzählen – so korrigieren sich verschluckte Ticks (Hintergrund-
    // Throttling) von selbst.
    on<CountdownTick>(_recomputeRemaining);
    on<ExerciseTick>(_recomputeRemaining);
    on<LifecycleResumed>(_recomputeRemaining);
    _clock = SessionPhaseClock(this, sessionService);
    _sessionSubscription = _sessionService.updates.listen(
      (update) => add(SessionUpdateReceived(update)),
    );
  }

  final SessionService _sessionService;
  final WorkoutService _workoutService;
  late final SessionPhaseClock _clock;
  late final StreamSubscription<SessionUpdate> _sessionSubscription;

  List<Participant> _participants = [];
  List<Vote> _votes = [];
  String? _trainerWorkoutId;
  List<Workout> _workouts = [];
  List<Result> _results = [];

  /// Ziel-Zeitpunkt der laufenden Timer-Phase (T3–T5b). `null`, sobald keine
  /// Phase mit Timer aktiv ist oder die Phase abgelaufen ist. Die Restzeit
  /// wird stets hieraus berechnet ([_remainingSeconds]), damit sie auch nach
  /// Hintergrund-Throttling korrekt bleibt.
  DateTime? _phaseDeadline;

  /// Challenge-Übungen in Ausführungs-Reihenfolge (ohne Warm-up) – Basis für
  /// die je-Übung-Aggregation auf T6.
  final List<Exercise> _challengeExercises = [];

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    _clock.cancelAll();
    _participants = [];
    _votes = [];
    _trainerWorkoutId = null;
    _results = [];
    _challengeExercises.clear();

    final session = await _sessionService.createSession();
    if (emit.isDone) return; // Handler wurde inzwischen abgebrochen (Close).

    emit(
      SessionWaitingState(sessionId: session.id, participants: _participants),
    );
  }

  Future<void> _onUpdateReceived(
    SessionUpdateReceived event,
    Emitter<SessionState> emit,
  ) async {
    final update = event.update;
    if (update is ParticipantsChanged) {
      _participants = update.participants;

      if (state is SessionWaitingState) {
        emit(
          SessionWaitingState(
            sessionId: (state as SessionWaitingState).sessionId,
            participants: _participants,
          ),
        );
      } else if (state is SessionSelectionState) {
        emit(
          SessionSelectionState(
            workouts: _workouts,
            votes: _votes,
            participants: update.participants,
            trainerWorkoutId: _trainerWorkoutId,
          ),
        );
      }
    } else if (update is SelectionStarted) {
      if (state is SessionWaitingState) {
        await _enterSelection(emit);
      }
    } else if (update is VotesChanged) {
      _votes = update.votes;
      _trainerWorkoutId = update.trainerWorkoutId;
      if (state is SessionSelectionState) {
        emit(
          SessionSelectionState(
            workouts: _workouts,
            votes: update.votes,
            participants: _participants,
            trainerWorkoutId: update.trainerWorkoutId,
          ),
        );
      }
    } else if (update is PhaseChanged) {
      _onPhaseChanged(update, emit);
    } else if (update is ResultSubmitted) {
      _onResultSubmitted(update, emit);
    } else if (update is SessionEnded) {
      _enterEnd(emit);
    }
  }

  // ------------------------------------------------------------------
  // Phasenübergänge (Session-Treiber)
  // ------------------------------------------------------------------

  void _onPhaseChanged(PhaseChanged update, Emitter<SessionState> emit) {
    switch (update.phase) {
      case SessionPhase.countdown:
        _startCountdown(update.workoutName ?? '', emit);
      case SessionPhase.warmup:
        final exercise = update.exercise;
        if (exercise != null) {
          _startWarmup(exercise, emit);
        }
      case SessionPhase.exercise:
        final exercise = update.exercise;
        if (exercise != null) {
          _startExerciseDisplay(exercise, emit);
        }
      case SessionPhase.rest:
        final exercise = update.exercise;
        if (exercise != null) {
          _startRest(exercise, emit);
        }
      case SessionPhase.result:
        _enterResult(emit);
    }
  }

  void _startCountdown(String workoutName, Emitter<SessionState> emit) {
    _clock.cancelAll();
    _armPhaseDeadline(AppConstants.countdownSeconds);
    emit(
      SessionCountdownState(
        workoutName: workoutName,
        secondsRemaining: AppConstants.countdownSeconds,
      ),
    );
    _clock.startCountdown();
  }

  void _startWarmup(Exercise exercise, Emitter<SessionState> emit) {
    _clock.cancelAll();
    _armPhaseDeadline(exercise.executionSeconds);
    emit(
      SessionWarmupState(
        exercise: exercise,
        secondsRemaining: exercise.executionSeconds,
      ),
    );
    _clock.startExercise();
  }

  void _startExerciseDisplay(Exercise exercise, Emitter<SessionState> emit) {
    _clock.cancelAll();
    _trackChallengeExercise(exercise);
    _armPhaseDeadline(exercise.executionSeconds);
    emit(
      SessionExerciseState(
        exercise: exercise,
        secondsRemaining: exercise.executionSeconds,
      ),
    );
    _clock.startExercise();
  }

  void _startRest(Exercise exercise, Emitter<SessionState> emit) {
    _clock.cancelAll();
    _trackChallengeExercise(exercise);
    final seconds = exercise.inputWindowSeconds;
    _armPhaseDeadline(seconds);
    emit(
      SessionRestState(
        exercise: exercise,
        secondsRemaining: seconds,
        totalSeconds: seconds,
        participants: _participants,
        submittedParticipantIds: const {},
      ),
    );
    _clock.startExercise();
  }

  /// Merkt sich eine Challenge-Übung (ohne Duplikate) in Ausführungs-
  /// Reihenfolge – Grundlage für die je-Übung-Aggregation auf T6.
  void _trackChallengeExercise(Exercise exercise) {
    final alreadyTracked = _challengeExercises.any(
      (tracked) => tracked.id == exercise.id,
    );
    if (!alreadyTracked) {
      _challengeExercises.add(exercise);
    }
  }

  /// T6 – Ergebnis-Screen; nach der Anzeigedauer wird die Session beendet.
  void _enterResult(Emitter<SessionState> emit) {
    final summary = ResultSummary.from(_results);
    final challengeResults = ChallengeResults.aggregate(
      _challengeExercises,
      _results,
    );
    _clock.cancelAll();
    emit(
      SessionResultState(
        participants: _participants,
        resultsByParticipant: summary.byParticipant,
        teamTotal: summary.teamTotal,
        exerciseResults: challengeResults.perExercise,
      ),
    );
    // doc/1-Backend-Realtime.md, Abschnitt 4, Schritt 9.
    _clock.armEndAfter(AppConstants.resultDisplaySeconds);
  }

  /// T7 – Abschluss; nach der Anzeigedauer zurück zu T1 (neue Session).
  void _enterEnd(Emitter<SessionState> emit) {
    _clock.cancelAll();
    emit(const SessionEndedState());
    _clock.armNewSessionAfter(AppConstants.endScreenSeconds);
  }

  // ------------------------------------------------------------------
  // Phasen-Timer (Restzeit aus Ziel-Zeitpunkt)
  // ------------------------------------------------------------------

  /// Legt den Ziel-Zeitpunkt der aktuellen Timer-Phase fest.
  ///
  /// [clock] statt `DateTime.now()`: In Tests (`fakeAsync`) läuft die simulierte
  /// Zeit über das `clock`-Paket, sodass `async.elapse` sowohl Timer als auch
  /// diese Berechnung vorspult.
  void _armPhaseDeadline(int seconds) {
    _phaseDeadline = clock.now().add(Duration(seconds: seconds));
  }

  /// Verbleibende ganze Sekunden bis zum Ziel-Zeitpunkt (aufgerundet, damit die
  /// Startsekunde die volle Dauer anzeigt). 0, wenn keine Phase läuft oder die
  /// Zeit abgelaufen ist.
  int _remainingSeconds() {
    final deadline = _phaseDeadline;
    if (deadline == null) return 0;
    final ms = deadline.difference(clock.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  /// Rechnet die Restzeit der laufenden Timer-Phase neu und emittiert sie.
  ///
  /// Gemeinsamer Handler für [CountdownTick], [ExerciseTick] und
  /// [LifecycleResumed]. Da die Restzeit aus [_phaseDeadline] stammt, gleicht
  /// jeder Aufruf verschluckte Ticks (Hintergrund-Throttling) automatisch aus.
  /// Bei 0 ruft der TV als Session-Treiber genau einmal `advancePhase()` auf –
  /// [_phaseDeadline] wird auf `null` gesetzt, damit ein Folge-Event nicht
  /// erneut auslöst.
  void _recomputeRemaining(SessionEvent event, Emitter<SessionState> emit) {
    final current = state;
    final isTimedPhase =
        current is SessionCountdownState ||
        current is SessionWarmupState ||
        current is SessionExerciseState ||
        current is SessionRestState;
    if (!isTimedPhase || _phaseDeadline == null) return;

    final remaining = _remainingSeconds();
    if (remaining <= 0) {
      _phaseDeadline = null;
      _clock.stopPhaseTimer();
      unawaited(_sessionService.advancePhase());
      return;
    }

    switch (current) {
      case SessionCountdownState():
        emit(
          SessionCountdownState(
            workoutName: current.workoutName,
            secondsRemaining: remaining,
          ),
        );
      case SessionWarmupState():
        emit(
          SessionWarmupState(
            exercise: current.exercise,
            secondsRemaining: remaining,
          ),
        );
      case SessionExerciseState():
        emit(current.copyWith(secondsRemaining: remaining));
      case SessionRestState():
        emit(current.copyWith(secondsRemaining: remaining));
      default:
        break;
    }
  }

  // ------------------------------------------------------------------
  // Eingaben der Teilnehmer (T5)
  // ------------------------------------------------------------------

  void _onResultSubmitted(ResultSubmitted update, Emitter<SessionState> emit) {
    final current = state;
    if (current is! SessionRestState) return;

    _results.removeWhere(
      (result) =>
          result.participantId == update.participant.id &&
          result.exerciseId == current.exercise.id,
    );
    _results.add(
      Result(
        participantId: update.participant.id,
        exerciseId: current.exercise.id,
        value: update.value,
      ),
    );

    final submitted = {
      ...current.submittedParticipantIds,
      update.participant.id,
    };
    emit(current.copyWith(submittedParticipantIds: submitted));
  }

  // ------------------------------------------------------------------
  // T2 – Workout-Auswahl
  // ------------------------------------------------------------------

  Future<void> _enterSelection(Emitter<SessionState> emit) async {
    final workouts = await _workoutService.fetchCatalog();
    if (emit.isDone) return; // Handler wurde inzwischen abgebrochen.
    if (state is! SessionWaitingState && state is! SessionCreatingState) {
      return; // Inzwischen ist eine Phase gestartet.
    }
    _workouts = workouts;
    emit(
      SessionSelectionState(
        workouts: workouts,
        votes: _votes,
        participants: _participants,
        trainerWorkoutId: _trainerWorkoutId,
      ),
    );
  }

  @override
  Future<void> close() {
    _clock.cancelAll();
    _sessionSubscription.cancel();
    _sessionService.dispose();
    return super.close();
  }
}
