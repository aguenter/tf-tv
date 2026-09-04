import 'package:flutter_test/flutter_test.dart';

import '../../helpers/stub_workout_service.dart';
import '../../helpers/test_fixtures.dart';

/// Unit-Tests für den Workout-Katalog und die Übungs-Pools.
/// Tests run against the StubWorkoutService (same data contract as the
/// Supabase-backed WorkoutService, no network required).

void main() {
  late StubWorkoutService service;

  setUp(() => service = StubWorkoutService());

  group('Katalog (fetchCatalog)', () {
    test('liefert alle 9 Workouts aus dem UX-Konzept', () async {
      final catalog = await service.fetchCatalog();
      expect(catalog, hasLength(9));
    });

    test('Workout-IDs sind eindeutig', () async {
      final catalog = await service.fetchCatalog();
      expect(catalog.map((w) => w.id).toSet().length, catalog.length);
    });

    test('drei Workouts sind freigeschaltet (Katalog-Icons auf T2)', () async {
      final catalog = await service.fetchCatalog();
      expect(
        catalog.where((w) => w.isUnlocked).map((w) => w.id),
        ['ganzkoerper-blitz', 'kraft-fokus', 'rumpf-power'],
      );
    });

    test('workoutById findet bekannte Workouts, sonst null', () async {
      final catalog = await service.fetchCatalog();
      expect(service.workoutById(catalog, 'team-battle')?.name, 'Team-Battle');
      expect(service.workoutById(catalog, 'unbekannt'), isNull);
    });
  });

  group('Übungs-Pool (fetchExercises)', () {
    test('Ganzkörper-Blitz: Warm-up zuerst, dann Liegestütze → Kniebeugen → Sit-ups',
        () async {
      expect(await service.fetchExercises('ganzkoerper-blitz'), ganzkoerperPool);
    });

    test('Kraft-Fokus: Warm-up, dann Kniebeugen → Sit-ups → Liegestütze',
        () async {
      final pool = await service.fetchExercises('kraft-fokus');
      expect(pool, [warmupExercise, squatExercise, situpExercise, pushupExercise]);
    });

    test('Rumpf-Power: Warm-up, dann Sit-ups → Liegestütze → Kniebeugen',
        () async {
      final pool = await service.fetchExercises('rumpf-power');
      expect(pool, [warmupExercise, situpExercise, pushupExercise, squatExercise]);
    });

    test('unbekanntes Workout → Fallback auf den Ganzkörper-Pool', () async {
      expect(await service.fetchExercises('unbekannt'), ganzkoerperPool);
    });

    test('jeder Pool besteht aus 4 Übungen (1 Warm-up + 3 Challenges)',
        () async {
      for (final workoutId in ['ganzkoerper-blitz', 'kraft-fokus', 'rumpf-power']) {
        expect(await service.fetchExercises(workoutId), hasLength(4));
      }
    });
  });
}
