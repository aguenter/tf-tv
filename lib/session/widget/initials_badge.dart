import 'package:flutter/material.dart';

/// Initialen-Badge: kleines rundes Chip mit den Initialen einer Person.
///
/// Wird in der Namens-Leiste (T2) und auf den Workout-Karten (Voting-Badges,
/// T2) verwendet. Der Trainer wird farblich hervorgehoben (ux.md §1, §2.1).
class InitialsBadge extends StatelessWidget {
  const InitialsBadge({
    super.key,
    required this.initials,
    this.isTrainer = false,
    this.size = 28,
  });

  final String initials;
  final bool isTrainer;

  /// Durchmesser des Badges in logischen Pixeln.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isTrainer
            ? Colors.amber.shade700
            : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: isTrainer ? Colors.black87 : null,
        ),
      ),
    );
  }
}
