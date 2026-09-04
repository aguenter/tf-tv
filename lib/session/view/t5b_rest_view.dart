import 'package:flutter/material.dart';

import '../model/exercise.dart';
import '../model/participant.dart';
import '../widget/progress_ring.dart';

class T5bRestView extends StatelessWidget {
  const T5bRestView({
    super.key,
    required this.exercise,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.participants,
    required this.submittedParticipantIds,
  });

  final Exercise exercise;
  final int secondsRemaining;
  final int totalSeconds;
  final List<Participant> participants;
  final Set<String> submittedParticipantIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySeconds = secondsRemaining - 1;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'REST',
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              exercise.name.toUpperCase(),
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'Enter your result on your phone',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final participant in participants)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        submittedParticipantIds.contains(participant.id)
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: submittedParticipantIds.contains(participant.id)
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(participant.initials),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ProgressRing(
              value: totalSeconds > 0 ? secondsRemaining / totalSeconds : 0,
              totalSeconds: totalSeconds,
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
