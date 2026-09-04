import 'package:flutter/material.dart';

import '../model/participant.dart';
import '../model/vote.dart';
import '../model/workout.dart';
import '../widget/name_bar.dart';
import '../widget/workout_card.dart';

/// T2 – Workout-Auswahl (Live-Spiegel & Voting): gespiegelter
/// 9-Kacheln-Katalog mit Initialen-Badges + Stimmenzahl pro Karte,
/// hervorgehobener Trainer-Karte und Namens-Leiste.
class T2SelectionView extends StatelessWidget {
  const T2SelectionView({
    super.key,
    required this.workouts,
    required this.votes,
    required this.participants,
    this.trainerWorkoutId,
  });

  final List<Workout> workouts;
  final List<Vote> votes;
  final List<Participant> participants;
  final String? trainerWorkoutId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          NameBar(participants: participants),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 3×3-Raster, das die verfügbare Fläche ausfüllt – auf dem
                // TV (16:9) muss der komplette Katalog ohne Scrollen sichtbar
                // sein, daher wird das Seitenverhältnis dynamisch berechnet.
                const crossAxisCount = 3;
                const spacing = 16.0;
                final cellWidth =
                    (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                final cellHeight =
                    (constraints.maxHeight - spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: cellWidth / cellHeight,
                  ),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];
                    return WorkoutCard(
                      workout: workout,
                      voters: _votersFor(workout.id),
                      highlighted: workout.id == trainerWorkoutId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Participant> _votersFor(String workoutId) {
    final voterIds = votes
        .where((vote) => vote.workoutId == workoutId)
        .expand((vote) => vote.participantIds)
        .toSet();
    return [
      for (final participant in participants)
        if (voterIds.contains(participant.id)) participant,
    ];
  }
}
