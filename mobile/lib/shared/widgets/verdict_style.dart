import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/shared/widgets/seal.dart';

class VerdictStyle {
  const VerdictStyle({
    required this.color,
    required this.tint,
    required this.glyph,
    required this.title,
    required this.chip,
  });

  final Color color;
  final Color tint;
  final SealGlyph glyph;
  final String title;
  final String chip;
}

VerdictStyle styleOf(VerdictKind kind) => switch (kind) {
      VerdictKind.genuineFirstScan => const VerdictStyle(
          color: AppColors.genuine,
          tint: AppColors.genuineTint,
          glyph: SealGlyph.check,
          title: 'Genuine',
          chip: 'Genuine',
        ),
      VerdictKind.genuineScannedBefore => const VerdictStyle(
          color: AppColors.caution,
          tint: AppColors.cautionTint,
          glyph: SealGlyph.alert,
          title: 'Scanned before',
          chip: 'Scanned before',
        ),
      VerdictKind.invalidTag => const VerdictStyle(
          color: AppColors.danger,
          tint: AppColors.dangerTint,
          glyph: SealGlyph.cross,
          title: 'Not authentic',
          chip: 'Invalid',
        ),
      VerdictKind.unknownProducer => const VerdictStyle(
          color: AppColors.danger,
          tint: AppColors.dangerTint,
          glyph: SealGlyph.cross,
          title: 'Unknown producer',
          chip: 'Unregistered',
        ),
      VerdictKind.recalled => const VerdictStyle(
          color: AppColors.danger,
          tint: AppColors.dangerTint,
          glyph: SealGlyph.cross,
          title: 'Recalled',
          chip: 'Recalled',
        ),
      VerdictKind.unchecked => const VerdictStyle(
          color: AppColors.neutral,
          tint: AppColors.neutralTint,
          glyph: SealGlyph.dash,
          title: 'Signature valid',
          chip: 'Unchecked',
        ),
    };

String verdictMessage(Verdict v) => switch (v.kind) {
      VerdictKind.genuineFirstScan =>
        'Signed by the producer and recorded on Solana. This is the first time this unit has been scanned.',
      VerdictKind.genuineScannedBefore =>
        'The signature is real, but this unit has been scanned ${v.scanCount ?? 2} times. It may be a copy.',
      VerdictKind.invalidTag =>
        'This tag\'s signature does not match. It was not issued by the producer it claims.',
      VerdictKind.unknownProducer =>
        'The signature is valid, but this producer is not in the registry. Treat the product with suspicion.',
      VerdictKind.recalled =>
        'The producer has pulled this batch. Do not use it, and return it to the seller.',
      VerdictKind.unchecked =>
        'You are offline. We confirmed the signature on this phone, but not the registry or scan history. Check again when you have signal.',
    };

class VerdictChip extends StatelessWidget {
  const VerdictChip({super.key, required this.kind});

  final VerdictKind kind;

  @override
  Widget build(BuildContext context) {
    final style = styleOf(kind);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            style.chip,
            style: AppText.small.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
