import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tv/app/shared/constants.dart';
import 'package:tv/session/model/exercise.dart';
import 'package:tv/session/view/t5_exercise_view.dart';
import 'package:tv/session/widget/exercise_icon.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    assert(
      AppConstants.supabaseUrl.isNotEmpty,
      'SUPABASE_URL must be set in .env',
    );
  });

  group('Exercise image from Supabase Storage', () {
    testWidgets('ExerciseIcon loads WebP from storage', (tester) async {
      const exercise = Exercise(
        id: 'test-pushup',
        name: 'Push-ups',
        instruction: 'Test',
        executionSeconds: 30,
        inputWindowSeconds: 10,
        imagePath: 'app_assets/pushup_anim.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      // Wait for network image to load.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Image.network should be present (not the emoji fallback text).
      expect(find.byType(Image), findsOneWidget,
          reason: 'Image widget should render (not emoji fallback)');

      // The emoji fallback should NOT be visible.
      expect(find.text('🏋️'), findsNothing,
          reason: 'Emoji fallback should not appear when image loads');
    });

    testWidgets('T5ExerciseView renders with real image', (tester) async {
      const exercise = Exercise(
        id: 'test-pushup',
        name: 'Push-ups',
        instruction: 'So viele Liegestütze wie möglich!',
        executionSeconds: 30,
        inputWindowSeconds: 10,
        imagePath: 'app_assets/pushup_anim.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const T5ExerciseView(
            exercise: exercise,
            secondsRemaining: 25,
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget,
          reason: 'Exercise view should show the Supabase image');
    });

    testWidgets('emoji fallback when imagePath is null', (tester) async {
      const exercise = Exercise(
        id: 'test-no-image',
        name: 'No Image',
        instruction: 'Test',
        executionSeconds: 30,
        inputWindowSeconds: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('🏋️'), findsOneWidget,
          reason: 'Emoji fallback should show when no imagePath');
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('emoji fallback on invalid imagePath', (tester) async {
      const exercise = Exercise(
        id: 'test-bad-path',
        name: 'Bad Path',
        instruction: 'Test',
        executionSeconds: 30,
        inputWindowSeconds: 10,
        imagePath: 'app_assets/does_not_exist.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('🏋️'), findsOneWidget,
          reason: 'Emoji fallback should show on load error');
    });
  });
}
