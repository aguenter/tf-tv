import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/view/t5_exercise_view.dart';
import 'package:tv/session/view/t5b_rest_view.dart';
import 'package:tv/session/widget/progress_ring.dart';

import '../../helpers/test_fixtures.dart';

Future<void> pumpExercise(
  WidgetTester tester, {
  required int secondsRemaining,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: T5ExerciseView(
          exercise: pushupExercise,
          secondsRemaining: secondsRemaining,
        ),
      ),
    ),
  );
}

Future<void> pumpRest(
  WidgetTester tester, {
  required int secondsRemaining,
  Set<String> submitted = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: T5bRestView(
          exercise: pushupExercise,
          secondsRemaining: secondsRemaining,
          totalSeconds: pushupExercise.inputWindowSeconds,
          participants: allParticipants,
          submittedParticipantIds: submitted,
        ),
      ),
    ),
  );
}

void main() {
  group('T5 – Exercise View', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(1920, 1080);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('zeigt Übungs-Icon + Name + Anleitung (T5-T8)', (tester) async {
      await pumpExercise(tester, secondsRemaining: 40);

      final icon = tester.widget<Text>(find.text('💪'));
      expect(icon.style?.fontSize, greaterThan(80));

      expect(find.text('PUSH-UPS'), findsOneWidget);
      expect(
        find.text('So viele Liegestütze wie möglich in 40 Sekunden!'),
        findsOneWidget,
      );
    });

    testWidgets('ProgressRing zeigt Restzeit (T5-T9)', (tester) async {
      await pumpExercise(tester, secondsRemaining: 37);

      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('36'), findsOneWidget);
      expect(find.text('SEC'), findsOneWidget);
    });
  });

  group('T5b – Rest View', () {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(1920, 1080);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    testWidgets('zeigt Pause-Hinweis + alle Häkchen offen (T5b-T1)', (tester) async {
      await pumpRest(tester, secondsRemaining: 15);

      expect(find.text('REST'), findsOneWidget);
      expect(find.text('Enter your result on your phone'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsNWidgets(3));
    });

    testWidgets('eingetragene Person erhält grünes Häkchen (T5b-T2)', (tester) async {
      await pumpRest(tester, secondsRemaining: 10, submitted: {'p-lena'});

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsNWidgets(2));
      expect(find.text('LL'), findsOneWidget);

      await pumpRest(tester, secondsRemaining: 8, submitted: {'p-lena', 'p-jon'});
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('ProgressRing zeigt Restzeit (T5b-T3)', (tester) async {
      await pumpRest(tester, secondsRemaining: 15);

      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('SEC'), findsOneWidget);
    });
  });
}
