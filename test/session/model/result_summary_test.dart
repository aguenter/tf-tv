import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/model/result.dart';

import '../../helpers/test_fixtures.dart';

/// Unit-Tests für die Ergebnis-Aggregation (Basis für T6).
///
/// [ResultSummary.from] summiert alle Challenge-Ergebnisse je Teilnehmer
/// (über alle Übungen) sowie die Team-Gesamtsumme.

void main() {
  group('ResultSummary', () {
    test('leere Liste → leere Aggregation, Team-Summe 0', () {
      final summary = ResultSummary.from(const []);
      expect(summary.byParticipant, isEmpty);
      expect(summary.teamTotal, 0);
    });

    test('mehrere Ergebnisse desselben Teilnehmers werden summiert', () {
      final summary = ResultSummary.from(const [
        Result(participantId: 'p-trainer', exerciseId: 'liegestuetze', value: 14),
        Result(participantId: 'p-trainer', exerciseId: 'kniebeugen', value: 16),
        Result(participantId: 'p-trainer', exerciseId: 'situps', value: 18),
      ]);
      expect(summary.byParticipant, {'p-trainer': 48});
      expect(summary.teamTotal, 48);
    });

    test('mehrere Teilnehmer: Summen je Person + Team-Gesamtsumme', () {
      final summary = ResultSummary.from(const [
        Result(participantId: 'p-trainer', exerciseId: 'liegestuetze', value: 14),
        Result(participantId: 'p-lena', exerciseId: 'liegestuetze', value: 10),
        Result(participantId: 'p-jon', exerciseId: 'liegestuetze', value: 7),
        Result(participantId: 'p-lena', exerciseId: 'kniebeugen', value: 12),
      ]);
      expect(summary.byParticipant, {
        'p-trainer': 14,
        'p-lena': 22, // 10 + 12 über zwei Übungen
        'p-jon': 7,
      });
      expect(summary.teamTotal, 43); // 14 + 10 + 7 + 12
    });

    test('Ergebnis mit Wert 0 wird gezählt, aber ändert keine Summe', () {
      final summary = ResultSummary.from(const [
        Result(participantId: 'p-lena', exerciseId: 'situps', value: 0),
      ]);
      expect(summary.byParticipant, {'p-lena': 0});
      expect(summary.teamTotal, 0);
    });
  });

  group('ChallengeResults.aggregate', () {
    test('ein Balken pro Übung, in Übungs-Reihenfolge', () {
      final aggregate = ChallengeResults.aggregate(
        const [pushupExercise, squatExercise, situpExercise],
        const [
          Result(participantId: 'p-trainer', exerciseId: 'liegestuetze', value: 8),
          Result(participantId: 'p-lena', exerciseId: 'liegestuetze', value: 12),
          Result(participantId: 'p-jon', exerciseId: 'kniebeugen', value: 20),
        ],
      );

      expect(
        aggregate.perExercise.map((e) => e.exercise).toList(),
        [pushupExercise, squatExercise, situpExercise],
      );
      // Team-Summe je Übung.
      expect(aggregate.perExercise[0].teamTotal, 20); // 8 + 12
      expect(aggregate.perExercise[1].teamTotal, 20); // 20
      expect(aggregate.perExercise[2].teamTotal, 0); // niemand eingetragen
    });

    test('Bestwert je Übung wird korrekt ermittelt', () {
      final aggregate = ChallengeResults.aggregate(
        const [pushupExercise],
        const [
          Result(participantId: 'p-trainer', exerciseId: 'liegestuetze', value: 8),
          Result(participantId: 'p-lena', exerciseId: 'liegestuetze', value: 12),
          Result(participantId: 'p-jon', exerciseId: 'liegestuetze', value: 5),
        ],
      );

      final pushups = aggregate.perExercise.single;
      expect(pushups.topParticipantId, 'p-lena');
      expect(pushups.topValue, 12);
    });

    test('Gleichstand: der zuerst eingetragene Teilnehmer gewinnt', () {
      final aggregate = ChallengeResults.aggregate(
        const [pushupExercise],
        const [
          // Jon trägt 15 zuerst ein, Lena danach ebenfalls 15.
          Result(participantId: 'p-jon', exerciseId: 'liegestuetze', value: 15),
          Result(participantId: 'p-lena', exerciseId: 'liegestuetze', value: 15),
        ],
      );

      expect(aggregate.perExercise.single.topParticipantId, 'p-jon');
      expect(aggregate.perExercise.single.topValue, 15);
    });

    test('Übung ohne Eingabe: Team-Summe 0, kein Top-Teilnehmer', () {
      final aggregate = ChallengeResults.aggregate(
        const [situpExercise],
        const [],
      );

      final situps = aggregate.perExercise.single;
      expect(situps.teamTotal, 0);
      expect(situps.topParticipantId, isNull);
      expect(situps.topValue, 0);
    });
  });
}
