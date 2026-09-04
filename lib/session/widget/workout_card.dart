import 'package:flutter/material.dart';

import '../model/participant.dart';
import '../model/workout.dart';
import 'initials_badge.dart';

/// Kachel des Workout-Katalogs auf T2: mit Live-Vote-Badges
/// (Initialen + Stimmenzahl) und Hervorhebung der Trainer-Auswahl.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    required this.voters,
    this.highlighted = false,
  });

  final Workout workout;
  final List<Participant> voters;
  final bool highlighted;

  /// Maximal sichtbare Initialen-Badges je Karte (Rest als „+N“,
  /// ux.md §2.1 T2: „max. 4–5, Rest als +2“).
  static const int maxVisibleBadges = 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Hervorhebung der Trainer-Auswahl: Rahmen + dezenter Glow (ux.md §2.1).
        color: highlighted
            ? Colors.amber.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? Colors.amber : Colors.transparent,
          width: 3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                workout.isUnlocked ? Icons.lock_open : Icons.lock,
                size: 18,
              ),
            ),
            const Spacer(),
            Text(
              workout.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              workout.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (voters.isEmpty)
              Text(
                'Noch keine Stimmen',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white54),
              )
            else
              Row(
                children: [
                  // Initialen-Badges der Stimmenden (max. 5, Rest als „+N“).
                  for (final voter in voters.take(maxVisibleBadges)) ...[
                    InitialsBadge(
                      initials: voter.initials,
                      isTrainer: voter.role == ParticipantRole.trainer,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (voters.length > maxVisibleBadges) ...[
                    Text(
                      '+${voters.length - maxVisibleBadges}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Spacer(),
                  // Kleine Stimmenzahl (z. B. „● 3“, ux.md §2.1 T2).
                  Text(
                    '● ${voters.length}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
