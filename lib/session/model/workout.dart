import 'package:equatable/equatable.dart';

/// Eine Kachel des Workout-Katalogs (workouts-Tabelle).
class Workout extends Equatable {
  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.isUnlocked,
  });

  factory Workout.fromRow(Map<String, dynamic> row) {
    return Workout(
      id: row['id'] as String,
      name: row['name'] as String,
      description: (row['description'] as String?) ?? '',
      isUnlocked: row['is_unlocked'] as bool,
    );
  }

  final String id;
  final String name;
  final String description;
  final bool isUnlocked;

  @override
  List<Object?> get props => [id, name, description, isUnlocked];
}
