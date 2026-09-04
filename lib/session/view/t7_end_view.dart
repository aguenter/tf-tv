import 'package:flutter/material.dart';

import '../../app/shared/constants.dart';
import '../../app/shared/theme.dart';

class T7EndView extends StatelessWidget {
  const T7EndView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'THANKS!',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'See you next time – the screen will be ready for the next group shortly.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TeamfitColors.textOnInverseMuted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            AppConstants.appName.toUpperCase(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: TeamfitColors.streak500,
                ),
          ),
        ],
      ),
    );
  }
}
