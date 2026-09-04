import 'package:equatable/equatable.dart';

/// Eine Stimme für ein Workout (votes-Tabelle): welche Teilnehmer:innen
/// haben für welches Workout mitgevotet.
class Vote extends Equatable {
  const Vote({required this.workoutId, required this.participantIds});

  final String workoutId;

  /// IDs der Teilnehmer:innen, die für dieses Workout gestimmt haben.
  final List<String> participantIds;

  @override
  List<Object?> get props => [workoutId, participantIds];
}
