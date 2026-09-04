import 'package:flutter/material.dart';

import '../../app/shared/theme.dart';

class T3CountdownView extends StatelessWidget {
  const T3CountdownView({
    super.key,
    required this.workoutName,
    required this.secondsRemaining,
  });

  final String workoutName;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            workoutName.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(secondsRemaining),
            tween: Tween<double>(begin: 1.3, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              '$secondsRemaining',
              style: TeamfitTypo.mono(
                fontSize: 88,
                color: TeamfitColors.streak500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
