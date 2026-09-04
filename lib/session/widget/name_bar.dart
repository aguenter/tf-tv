import 'package:flutter/material.dart';

import '../model/participant.dart';
import 'initials_badge.dart';

/// Namens-Leiste (T2): zeigt, wer gerade im Raum ist. Der Trainer wird
/// farblich hervorgehoben (ux.md §2.1 T2).
class NameBar extends StatelessWidget {
  const NameBar({super.key, required this.participants});

  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people_outline),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final participant in participants) ...[
                  InitialsBadge(
                    initials: participant.initials,
                    isTrainer: participant.role == ParticipantRole.trainer,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
