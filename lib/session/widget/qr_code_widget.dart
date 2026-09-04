import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/shared/theme.dart';

class QrCodeWidget extends StatelessWidget {
  const QrCodeWidget({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TeamfitSpacing.s5),
      decoration: BoxDecoration(
        color: TeamfitColors.sand50,
        borderRadius: BorderRadius.circular(TeamfitSpacing.radiusLg),
      ),
      child: QrImageView(
        data: data,
        size: 320,
        backgroundColor: TeamfitColors.sand50,
        dataModuleStyle: const QrDataModuleStyle(
          color: TeamfitColors.ink900,
        ),
        eyeStyle: const QrEyeStyle(
          color: TeamfitColors.ink900,
        ),
      ),
    );
  }
}
