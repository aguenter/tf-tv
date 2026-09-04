import 'package:equatable/equatable.dart';

import 'exercise.dart';

/// Ein eingetragenes Ergebnis für eine Übung (results-Tabelle).
class Result extends Equatable {
  const Result({
    required this.participantId,
    required this.exerciseId,
    required this.value,
  });

  final String participantId;
  final String exerciseId;

  /// Eingetragener Wert (z. B. Anzahl Wiederholungen).
  final int value;

  @override
  List<Object?> get props => [participantId, exerciseId, value];
}

/// Aggregierte Challenge-Ergebnisse einer Session – die Basis für T6.
///
/// Summiert alle [Result]-Einträge je Teilnehmer (über alle
/// Challenge-Übungen) sowie die Team-Gesamtsumme.
class ResultSummary extends Equatable {
  const ResultSummary({
    required this.byParticipant,
    required this.teamTotal,
  });

  /// Summe aller Challenge-Ergebnisse je Teilnehmer-ID.
  final Map<String, int> byParticipant;

  /// Summe aller Einzelergebnisse (Team-Gesamtsumme).
  final int teamTotal;

  /// Aggregiert eine Liste von [results].
  factory ResultSummary.from(List<Result> results) {
    final byParticipant = <String, int>{};
    var teamTotal = 0;
    for (final result in results) {
      byParticipant[result.participantId] =
          (byParticipant[result.participantId] ?? 0) + result.value;
      teamTotal += result.value;
    }
    return ResultSummary(byParticipant: byParticipant, teamTotal: teamTotal);
  }

  @override
  List<Object?> get props => [byParticipant, teamTotal];
}

/// Aggregiertes Ergebnis **einer** Challenge-Übung – die Basis für die
/// beiden Balken-Diagramme auf T6.
///
/// Bündelt sowohl die Team-Gesamtleistung ([teamTotal]) als auch den besten
/// Einzelwert ([topValue]) samt der zugehörigen Teilnehmer-ID
/// ([topParticipantId]) für genau diese Übung.
class ExerciseResult extends Equatable {
  const ExerciseResult({
    required this.exercise,
    required this.teamTotal,
    required this.topParticipantId,
    required this.topValue,
  });

  final Exercise exercise;

  /// Summe aller Einzelergebnisse dieser Übung (ein Balken im Team-Diagramm).
  final int teamTotal;

  /// Teilnehmer-ID mit dem höchsten Einzelwert dieser Übung, oder `null`,
  /// falls niemand ein Ergebnis eingetragen hat.
  ///
  /// Race-Condition: Bei Gleichstand gewinnt, wer sein Ergebnis **zuerst**
  /// eingetragen hat (siehe [ChallengeResults.aggregate]).
  final String? topParticipantId;

  /// Höchster Einzelwert dieser Übung (0, falls keine Eingabe).
  final int topValue;

  @override
  List<Object?> get props => [exercise, teamTotal, topParticipantId, topValue];
}

/// Aggregierte Challenge-Ergebnisse **je Übung** – die Basis für die zwei
/// Diagramme auf T6 (Team-Leistung + Einzel-Bestleistung).
class ChallengeResults extends Equatable {
  const ChallengeResults({required this.perExercise});

  /// Ein Eintrag je Challenge-Übung, in der Übungs-Reihenfolge.
  final List<ExerciseResult> perExercise;

  /// Aggregiert [results] entlang der Übungs-Reihenfolge [exercises].
  ///
  /// [results] muss in Eintrags-Reihenfolge vorliegen (erstes eingetragenes
  /// Ergebnis zuerst) – so gewinnt bei Gleichstand des Bestwerts der zuerst
  /// eingetragene Teilnehmer (strikt `>` beim Vergleich).
  factory ChallengeResults.aggregate(
    List<Exercise> exercises,
    List<Result> results,
  ) {
    final perExercise = <ExerciseResult>[];
    for (final exercise in exercises) {
      var teamTotal = 0;
      String? topParticipantId;
      var topValue = 0;
      var hasEntry = false;
      for (final result in results) {
        if (result.exerciseId != exercise.id) continue;
        teamTotal += result.value;
        // Strikt >: der zuerst eingetragene Teilnehmer behält den Bestwert.
        if (!hasEntry || result.value > topValue) {
          topValue = result.value;
          topParticipantId = result.participantId;
        }
        hasEntry = true;
      }
      perExercise.add(
        ExerciseResult(
          exercise: exercise,
          teamTotal: teamTotal,
          topParticipantId: topParticipantId,
          topValue: topValue,
        ),
      );
    }
    return ChallengeResults(perExercise: perExercise);
  }

  @override
  List<Object?> get props => [perExercise];
}
