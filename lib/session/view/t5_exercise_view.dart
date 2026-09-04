import 'package:flutter/material.dart';

import '../model/exercise.dart';
import '../widget/exercise_icon.dart';
import '../widget/progress_ring.dart';

class T5ExerciseView extends StatelessWidget {
  const T5ExerciseView({
    super.key,
    required this.exercise,
    required this.secondsRemaining,
  });

  final Exercise exercise;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final displaySeconds = secondsRemaining - 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExerciseIcon(exercise: exercise, size: 400),
            const SizedBox(height: 32),
            Text(
              exercise.name.toUpperCase(),
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              exercise.instruction,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ProgressRing(
              value: exercise.executionSeconds > 0
                  ? secondsRemaining / exercise.executionSeconds
                  : 0,
              totalSeconds: exercise.executionSeconds,
              size: 200,
              thickness: 16,
              label: '$displaySeconds',
              sublabel: 'SEC',
              showTenths: true,
            ),
          ],
        ),
      ),
    );
  }
}
