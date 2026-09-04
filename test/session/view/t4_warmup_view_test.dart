import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/session/view/t4_warmup_view.dart';
import 'package:tv/session/widget/progress_ring.dart';

import '../../helpers/test_fixtures.dart';

Future<void> pumpT4(WidgetTester tester, {required int secondsRemaining}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: T4WarmupView(
          exercise: warmupExercise,
          secondsRemaining: secondsRemaining,
        ),
      ),
    ),
  );
}

void main() {
  group('T4 – Warm-up', () {
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

    testWidgets('zeigt Übungsname + Anleitung (T4-T5)', (tester) async {
      await pumpT4(tester, secondsRemaining: 20);

      expect(find.text('JUMPING JACKS'), findsOneWidget);
      expect(find.text('Locker aufwärmen – alle machen mit!'), findsOneWidget);

      final name = tester.widget<Text>(find.text('JUMPING JACKS'));
      expect(name.style?.fontSize, greaterThan(40));
    });

    testWidgets('zeigt das Übungs-Icon groß (T4-T6)', (tester) async {
      await pumpT4(tester, secondsRemaining: 20);

      final icon = tester.widget<Text>(find.text('🤸'));
      expect(icon.style?.fontSize, greaterThan(80));
    });

    testWidgets('ProgressRing zeigt Restzeit (T4-T7)', (tester) async {
      await pumpT4(tester, secondsRemaining: 12);

      expect(find.byType(ProgressRing), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('SEC'), findsOneWidget);
    });
  });
}
