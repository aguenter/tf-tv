import 'package:tv/session/model/exercise.dart';
import 'package:tv/session/model/workout.dart';
import 'package:tv/session/service/workout_service.dart';

/// Test double for [WorkoutService] that returns hardcoded catalog data
/// without requiring a Supabase connection.
class StubWorkoutService implements WorkoutService {
  @override
  Future<List<Workout>> fetchCatalog() async {
    return const [
      Workout(
        id: 'ganzkoerper-blitz',
        name: 'Ganzkörper-Blitz',
        description:
            'Klassiker-Mix für den ganzen Körper – perfekt zum Reinschnuppern.',
        isUnlocked: true,
      ),
      Workout(
        id: 'kraft-fokus',
        name: 'Kraft-Fokus',
        description:
            'Startet mit den Beinen – für alle, die es unten herum wissen wollen.',
        isUnlocked: true,
      ),
      Workout(
        id: 'rumpf-power',
        name: 'Rumpf-Power',
        description: 'Bauch zuerst – bringt die Körpermitte in Schwung.',
        isUnlocked: true,
      ),
      Workout(
        id: 'cardio-sprint',
        name: 'Cardio-Sprint',
        description:
            'Kurz, knackig, außer Atem – reine Ausdauer-Challenge fürs Team.',
        isUnlocked: false,
      ),
      Workout(
        id: 'bauch-beine-po',
        name: 'Bauch-Beine-Po',
        description:
            'Der Klassiker aus dem Kursraum, jetzt als Gruppen-Challenge.',
        isUnlocked: false,
      ),
      Workout(
        id: 'oberkoerper-fokus',
        name: 'Oberkörper-Fokus',
        description: 'Arme, Brust, Schultern – wer hält am längsten durch?',
        isUnlocked: false,
      ),
      Workout(
        id: 'team-battle',
        name: 'Team-Battle',
        description:
            'Zwei Gruppen, ein Screen – wer sammelt mehr Wiederholungen?',
        isUnlocked: false,
      ),
      Workout(
        id: 'mobility-stretch',
        name: 'Mobility & Stretch',
        description: 'Ruhiger Ausklang zum Runterkommen nach dem Kurs.',
        isUnlocked: false,
      ),
      Workout(
        id: 'eigene-workouts',
        name: 'Eigene Workouts erstellen',
        description:
            'Stelle dein eigenes Workout aus beliebigen Übungen zusammen.',
        isUnlocked: false,
      ),
    ];
  }

  @override
  Future<List<Exercise>> fetchExercises(String workoutId) async {
    const hampelmann = Exercise(
      id: 'hampelmann',
      name: 'Jumping Jacks',
      instruction: 'Locker aufwärmen – alle machen mit!',
      executionSeconds: 20,
      inputWindowSeconds: 0,
    );
    const liegestuetze = Exercise(
      id: 'liegestuetze',
      name: 'Push-ups',
      instruction: 'So viele Liegestütze wie möglich in 40 Sekunden!',
      executionSeconds: 40,
      inputWindowSeconds: 15,
    );
    const kniebeugen = Exercise(
      id: 'kniebeugen',
      name: 'Squats',
      instruction: 'So viele Kniebeugen wie möglich in 40 Sekunden!',
      executionSeconds: 40,
      inputWindowSeconds: 15,
    );
    const situps = Exercise(
      id: 'situps',
      name: 'Sit-ups',
      instruction: 'So viele Sit-ups wie möglich in 40 Sekunden!',
      executionSeconds: 40,
      inputWindowSeconds: 15,
    );

    switch (workoutId) {
      case 'kraft-fokus':
        return [hampelmann, kniebeugen, situps, liegestuetze];
      case 'rumpf-power':
        return [hampelmann, situps, liegestuetze, kniebeugen];
      default:
        return [hampelmann, liegestuetze, kniebeugen, situps];
    }
  }

  @override
  Workout? workoutById(List<Workout> workouts, String id) {
    for (final workout in workouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }
}
