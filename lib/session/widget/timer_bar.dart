import 'package:flutter/material.dart';

/// Timer-Balken mit Sekunden-Anzeige (T3/T4/T5).
class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final int secondsRemaining;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$secondsRemaining s',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: totalSeconds > 0 ? secondsRemaining / totalSeconds : 0,
          minHeight: 12,
        ),
      ],
    );
  }
}
