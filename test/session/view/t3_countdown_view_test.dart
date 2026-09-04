import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/view/t3_countdown_view.dart';

/// Baut den T3-Screen in einem MaterialApp (dunkles Kiosk-Theme).
Future<void> pumpT3(WidgetTester tester, {required int secondsRemaining}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: T3CountdownView(
        workoutName: 'Ganzkörper-Blitz',
        secondsRemaining: secondsRemaining,
      ),
    ),
  );
}

void main() {
  group('T3 – Countdown', () {
    testWidgets('zeigt Workout-Titel + große Countdown-Zahl (T3-T4)',
        (tester) async {
      await pumpT3(tester, secondsRemaining: 3);

      expect(find.text('GANZKÖRPER-BLITZ'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Die Zahl ist die größte Textzeile des Screens (displayLarge).
      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.fontSize, greaterThan(40));
    });

    testWidgets('aktualisiert die Zahl bei jedem Tick (T3-T5)', (tester) async {
      await pumpT3(tester, secondsRemaining: 3);
      expect(find.text('3'), findsOneWidget);

      await pumpT3(tester, secondsRemaining: 2);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing);

      await pumpT3(tester, secondsRemaining: 1);
      expect(find.text('1'), findsOneWidget);

      // Nach dem Tick läuft die Puls-Animation aus (Scale → 1.0).
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });
  });
}
