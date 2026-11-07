import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/features/result/verdict_detail.dart';

/// Opens a past check from the history list.
class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          children: [
            VerdictDetail(
              outcome: outcome,
              topPadding: 66,
              primaryLabel: 'Done',
              onPrimary: () => Navigator.of(context).maybePop(),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
