import 'package:equatable/equatable.dart';

import '../model/exercise.dart';
import '../model/participant.dart';
import '../model/result.dart';
import '../model/vote.dart';
import '../model/workout.dart';

// Sealed, damit der Switch in der SessionView alle Zustände abdeckt.
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Die Session wird angelegt (Loading).
class SessionCreatingState extends SessionState {
  const SessionCreatingState();
}

/// T1 – Start-Screen: QR-Code + Live-Zähler + Teilnehmer-Badges.
class SessionWaitingState extends SessionState {
  const SessionWaitingState({
    required this.sessionId,
    this.participants = const [],
  });

  final String sessionId;
  final List<Participant> participants;

  int get participantCount => participants.length;

  @override
  List<Object?> get props => [sessionId, participants];
}

/// T2 – Workout-Auswahl (Live-Spiegel & Voting).
class SessionSelectionState extends SessionState {
  const SessionSelectionState({
    required this.workouts,
    required this.votes,
    required this.participants,
    this.trainerWorkoutId,
  });

  final List<Workout> workouts;
  final List<Vote> votes;
  final List<Participant> participants;

  /// Workout, das der Trainer ausgewählt hat (Hervorhebung auf T2).
  final String? trainerWorkoutId;

  @override
  List<Object?> get props => [workouts, votes, participants, trainerWorkoutId];
}

/// T3 – Countdown.
class SessionCountdownState extends SessionState {
  const SessionCountdownState({
    required this.workoutName,
    required this.secondsRemaining,
  });

  final String workoutName;
  final int secondsRemaining;

  @override
  List<Object?> get props => [workoutName, secondsRemaining];
}

/// T4 – Warm-up.
class SessionWarmupState extends SessionState {
  const SessionWarmupState({
    required this.exercise,
    required this.secondsRemaining,
  });

  final Exercise exercise;
  final int secondsRemaining;

  @override
  List<Object?> get props => [exercise, secondsRemaining];
}

/// T5 – Übungsanzeige (Timer läuft, kein Input).
class SessionExerciseState extends SessionState {
  const SessionExerciseState({
    required this.exercise,
    required this.secondsRemaining,
  });

  SessionExerciseState copyWith({int? secondsRemaining}) {
    return SessionExerciseState(
      exercise: exercise,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }

  final Exercise exercise;
  final int secondsRemaining;

  @override
  List<Object?> get props => [exercise, secondsRemaining];
}

/// T5b – Pause/Eingabe: Ergebnisse sammeln, visuell unterschiedlich.
class SessionRestState extends SessionState {
  const SessionRestState({
    required this.exercise,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.participants,
    required this.submittedParticipantIds,
  });

  SessionRestState copyWith({
    int? secondsRemaining,
    Set<String>? submittedParticipantIds,
  }) {
    return SessionRestState(
      exercise: exercise,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalSeconds: totalSeconds,
      participants: participants,
      submittedParticipantIds:
          submittedParticipantIds ?? this.submittedParticipantIds,
    );
  }

  final Exercise exercise;
  final int secondsRemaining;
  final int totalSeconds;
  final List<Participant> participants;
  final Set<String> submittedParticipantIds;

  @override
  List<Object?> get props => [
        exercise,
        secondsRemaining,
        totalSeconds,
        participants,
        submittedParticipantIds,
      ];
}

/// T6 – Ergebnis-Screen.
class SessionResultState extends SessionState {
  const SessionResultState({
    required this.participants,
    required this.resultsByParticipant,
    required this.teamTotal,
    required this.exerciseResults,
  });

  final List<Participant> participants;

  /// Summe aller Challenge-Ergebnisse je Teilnehmer-ID.
  final Map<String, int> resultsByParticipant;

  /// Summe aller Einzelergebnisse.
  final int teamTotal;

  /// Aggregiert je Challenge-Übung: Team-Leistung + Einzel-Bestleistung.
  /// Basis der beiden Balken-Diagramme auf T6.
  final List<ExerciseResult> exerciseResults;

  @override
  List<Object?> get props =>
      [participants, resultsByParticipant, teamTotal, exerciseResults];
}

/// T7 – Abschluss/Reset.
class SessionEndedState extends SessionState {
  const SessionEndedState();
}
