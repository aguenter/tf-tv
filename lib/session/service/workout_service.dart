import 'package:supabase/supabase.dart' hide Session;

import '../model/exercise.dart';
import '../model/workout.dart';

/// Liefert den Workout-Katalog und den Übungs-Pool für die TV-Anzeige.
class WorkoutService {
  WorkoutService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  Future<List<Workout>> fetchCatalog() async {
    final rows = await _client
        .from('workouts')
        .select()
        .order('sort_order', ascending: true);

    return rows.map<Workout>((row) => Workout.fromRow(row)).toList();
  }

  Future<List<Exercise>> fetchExercises(String workoutId) async {
    final rows = await _client
        .from('exercises')
        .select()
        .eq('workout_id', workoutId)
        .order('sort_order', ascending: true);

    return rows.map<Exercise>((row) => Exercise.fromRow(row)).toList();
  }

  Workout? workoutById(List<Workout> workouts, String id) {
    for (final workout in workouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }
}
