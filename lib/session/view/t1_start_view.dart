import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/shared/constants.dart';
import '../../app/shared/theme.dart';
import '../model/participant.dart';
import '../widget/qr_code_widget.dart';

class T1StartView extends StatelessWidget {
  const T1StartView({
    super.key,
    required this.sessionId,
    required this.participants,
  });

  final String sessionId;
  final List<Participant> participants;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        const Positioned.fill(child: _RingWash()),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/logo_lockup.svg',
                height: 72,
              ),
              const SizedBox(height: TeamfitSpacing.s8),

              QrCodeWidget(data: AppConstants.deepLinkFor(sessionId)),
              const SizedBox(height: TeamfitSpacing.s8),

              Text(
                'SCAN THE CODE',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: TeamfitSpacing.s2),
              Text(
                'and join in!',
                style: textTheme.bodyLarge?.copyWith(
                  color: TeamfitColors.textOnInverseMuted,
                ),
              ),
              const SizedBox(height: TeamfitSpacing.s6),

              _ParticipantRow(participants: participants),
              const SizedBox(height: TeamfitSpacing.s4),

              // Session ID for debugging — copy this to run integration tests.
              SelectableText(
                sessionId,
                style: textTheme.bodySmall?.copyWith(
                  color: TeamfitColors.ink500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participants});

  final List<Participant> participants;

  static const _badgeSize = 40.0;
  static const _spacedGap = 6.0;
  static const _stackedOffset = 8.0;
  static const _stackThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final count = participants.length;

    if (count == 0) {
      return const _CounterBadge(count: 0);
    }

    final visible = participants.take(8).toList();
    final stacked = count >= _stackThreshold;

    // Sort so trainer is last (painted on top in Stack).
    final ordered = stacked
        ? [
            ...visible.where((p) => p.role != ParticipantRole.trainer),
            ...visible.where((p) => p.role == ParticipantRole.trainer),
          ]
        : visible;

    final badgeSpan = stacked
        ? _badgeSize + (ordered.length - 1) * _stackedOffset
        : ordered.length * (_badgeSize + _spacedGap) - _spacedGap;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: badgeSpan,
          height: _badgeSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < ordered.length; i++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  left: stacked
                      ? i * _stackedOffset
                      : i * (_badgeSize + _spacedGap),
                  top: 0,
                  child: _AvatarBadge(
                    initials: ordered[i].initials,
                    isTrainer: ordered[i].role == ParticipantRole.trainer,
                  ),
                ),
            ],
          ),
        ),
        if (count > 8)
          Padding(
            padding: const EdgeInsets.only(left: _spacedGap),
            child: _AvatarBadge(
              initials: '+${count - 8}',
              isTrainer: false,
            ),
          ),
        const SizedBox(width: TeamfitSpacing.s3),
        _CounterBadge(count: count),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.initials,
    required this.isTrainer,
  });

  final String initials;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTrainer
            ? TeamfitColors.streak500
            : TeamfitColors.ink600,
        border: Border.all(
          color: isTrainer ? TeamfitColors.streak300 : TeamfitColors.ink900,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.barlowCondensed(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isTrainer ? TeamfitColors.ink900 : TeamfitColors.cyan400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 person joined' : '$count people joined';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeamfitSpacing.s4,
        vertical: TeamfitSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: count > 0
            ? TeamfitColors.statusGo.withValues(alpha: 0.15)
            : TeamfitColors.ink700,
        borderRadius: BorderRadius.circular(TeamfitSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 18,
            color: count > 0
                ? TeamfitColors.statusGo
                : TeamfitColors.textOnInverseMuted,
          ),
          const SizedBox(width: TeamfitSpacing.s2),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: count > 0
                      ? TeamfitColors.statusGo
                      : TeamfitColors.textOnInverseMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _RingWash extends StatelessWidget {
  const _RingWash();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _RingWashPainter());
  }
}

class _RingWashPainter extends CustomPainter {
  const _RingWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final maxRadius = size.height * 0.8;
    const ringCount = 5;

    for (var i = 0; i < ringCount; i++) {
      final fraction = (i + 1) / ringCount;
      final radius = maxRadius * fraction;
      final opacity = 0.04 + (0.03 * (1 - fraction));
      final paint = Paint()
        ..color = TeamfitColors.brand.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
