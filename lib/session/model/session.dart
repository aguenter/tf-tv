import 'package:equatable/equatable.dart';

/// Status einer Session (sessions.status).
enum SessionStatus { waiting, selecting, running, ended }

/// Aktuelle Phase einer Session (sessions.phase).
enum SessionPhase { countdown, warmup, exercise, rest, result }

/// Eine Workout-Session – der Lebenszyklus eines Realtime-Channels
/// (siehe doc/1-Backend-Realtime.md, Abschnitt 2).
class Session extends Equatable {
  const Session({
    required this.id,
    required this.status,
    this.phase,
    this.workoutId,
  });

  Session copyWith({
    SessionStatus? status,
    SessionPhase? phase,
    String? workoutId,
  }) {
    return Session(
      id: id,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      workoutId: workoutId ?? this.workoutId,
    );
  }

  final String id;
  final SessionStatus status;
  final SessionPhase? phase;
  final String? workoutId;

  @override
  List<Object?> get props => [id, status, phase, workoutId];
}
