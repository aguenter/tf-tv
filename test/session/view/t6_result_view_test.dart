import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/model/result.dart';
import 'package:tv/session/view/t6_result_view.dart';
import 'package:tv/session/widget/initials_badge.dart';

import '../../helpers/test_fixtures.dart';

/// Baut den T6-Screen in einem MaterialApp (dunkles Kiosk-Theme).
Future<void> pumpT6(
  WidgetTester tester, {
  required int teamTotal,
  required List<ExerciseResult> exerciseResults,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: T6ResultView(
        participants: allParticipants,
        teamTotal: teamTotal,
        exerciseResults: exerciseResults,
      ),
    ),
  );
}

void main() {
  group('T6 – Ergebnis', () {
    // Zwei Challenge-Übungen mit klaren Bestleistungen.
    const exerciseResults = [
      ExerciseResult(
        exercise: pushupExercise,
        teamTotal: 25, // 8 + 12 + 5
        topParticipantId: 'p-lena',
        topValue: 12,
      ),
      ExerciseResult(
        exercise: squatExercise,
        teamTotal: 40,
        topParticipantId: 'p-trainer',
        topValue: 20,
      ),
    ];

    testWidgets('zeigt Team-Summe + beide Abschnitte', (tester) async {
      await pumpT6(tester, teamTotal: 65, exerciseResults: exerciseResults);

      expect(find.text('TEAM RESULT'), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
      expect(find.text('REPS'), findsOneWidget);

      // Die zwei Diagramm-Abschnitte.
      expect(find.text('TEAM PER EXERCISE'), findsOneWidget);
      expect(find.text('TOP PER EXERCISE'), findsOneWidget);
    });

    testWidgets('ein Balken je Übung in beiden Diagrammen', (tester) async {
      await pumpT6(tester, teamTotal: 65, exerciseResults: exerciseResults);

      // 2 Übungen × 2 Diagramme = 4 Balken.
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));

      // Übungsnamen erscheinen in beiden Diagrammen (je 2×).
      expect(find.text('Push-ups'), findsNWidgets(2));
      expect(find.text('Squats'), findsNWidgets(2));
    });

    testWidgets('Top-Diagramm zeigt nur Badges, keine vollen Namen',
        (tester) async {
      await pumpT6(tester, teamTotal: 65, exerciseResults: exerciseResults);

      // Badges der Bestleistenden (Lena, Max) – keine Klarnamen.
      expect(find.byType(InitialsBadge), findsNWidgets(2));
      expect(find.text('LL'), findsOneWidget); // Lena, Push-ups
      expect(find.text('MM'), findsOneWidget); // Max, Squats

      expect(find.text('Lena Lorenz'), findsNothing);
      expect(find.text('Max Mustermann'), findsNothing);
    });

    testWidgets('Team-Balken normalisiert auf den größten Team-Wert',
        (tester) async {
      await pumpT6(tester, teamTotal: 65, exerciseResults: exerciseResults);

      final fractions = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((bar) => bar.value)
          .toList();

      // Reihenfolge: Team(Push-ups), Team(Squats), Top(Push-ups), Top(Squats).
      expect(fractions[0], closeTo(25 / 40, 0.001)); // Push-ups Team
      expect(fractions[1], 1.0); // Squats Team = Max
      expect(fractions[2], closeTo(12 / 20, 0.001)); // Push-ups Top
      expect(fractions[3], 1.0); // Squats Top = Max
    });

    testWidgets('Übung ohne Eingabe: „–“-Badge, Balken auf 0', (tester) async {
      const withEmpty = [
        ExerciseResult(
          exercise: pushupExercise,
          teamTotal: 10,
          topParticipantId: 'p-jon',
          topValue: 10,
        ),
        ExerciseResult(
          exercise: situpExercise,
          teamTotal: 0,
          topParticipantId: null,
          topValue: 0,
        ),
      ];

      await pumpT6(tester, teamTotal: 10, exerciseResults: withEmpty);

      expect(find.text('–'), findsOneWidget); // Platzhalter-Badge
    });
  });
}
