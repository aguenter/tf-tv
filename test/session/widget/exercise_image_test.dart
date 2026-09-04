@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tv/app/shared/constants.dart';
import 'package:tv/session/model/exercise.dart';
import 'package:tv/session/widget/exercise_icon.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    assert(
      AppConstants.supabaseUrl.isNotEmpty,
      'SUPABASE_URL must be set in .env to run this test',
    );
  });

  group('ExerciseIcon widget rendering', () {
    testWidgets('renders Image.network when imagePath is set', (tester) async {
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
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget,
          reason: 'Should render Image.network, not emoji fallback');
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.text('🏋️'), findsNothing);
      expect(find.text('💪'), findsNothing);
    });

    testWidgets('falls back to emoji when imagePath is null', (tester) async {
      const exercise = Exercise(
        id: 'test-no-image',
        name: 'No Image',
        instruction: 'Test',
        executionSeconds: 30,
        inputWindowSeconds: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('🏋️'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('constructed URL matches expected pattern', (tester) async {
      const exercise = Exercise(
        id: 'test-url',
        name: 'URL Test',
        instruction: 'Test',
        executionSeconds: 30,
        inputWindowSeconds: 10,
        imagePath: 'app_assets/pushup_anim.webp',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExerciseIcon(exercise: exercise, size: 400),
            ),
          ),
        ),
      );

      final imageWidget = tester.widget<Image>(find.byType(Image));
      final provider = imageWidget.image as NetworkImage;
      final expectedUrl =
          '${AppConstants.supabaseUrl}/storage/v1/object/public/app_assets/pushup_anim.webp';
      expect(provider.url, expectedUrl);
    });
  });
}
