import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/core/encoding.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/shared/routes.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/risk_gauge.dart';
import 'package:mobile/shared/widgets/seal.dart';
import 'package:mobile/shared/widgets/ticket_card.dart';
import 'package:mobile/shared/widgets/verdict_style.dart';
import 'package:mobile/features/timeline/timeline_page.dart';

/// The verdict screen body, used inside the scanner and on the history detail
/// page. [primaryLabel] and [onPrimary] drive the bottom action.
class VerdictDetail extends StatelessWidget {
  const VerdictDetail({
    super.key,
    required this.outcome,
    required this.primaryLabel,
    required this.onPrimary,
    this.topPadding = 20,
  });

  final ScanOutcome outcome;
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// Extra room at the top when a floating back button sits over the page.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final verdict = outcome.verdict;
    final style = styleOf(verdict.kind);
    final batch = verdict.batch;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, topPadding, 24, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                  decoration: BoxDecoration(
                    color: style.tint,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      VerdictSeal(
                        color: style.color,
                        glyph: style.glyph,
                        size: 148,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'VERDICT',
                        style: AppText.label.copyWith(color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        style.title,
                        textAlign: TextAlign.center,
                        style: AppText.display(48),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        verdictMessage(verdict),
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TicketCard(
                  top: _Facts(outcome: outcome),
                  bottom: _KeyLine(outcome: outcome),
                ),
                if (verdict.riskScore != null) ...[
                  const SizedBox(height: 18),
                  _RiskCard(
                    score: verdict.riskScore!,
                    explanation: verdict.riskExplanation ?? '',
                  ),
                ],
                const SizedBox(height: 24),
                if (batch != null) ...[
                  GhostButton(
                    label: 'View custody trail',
                    icon: Icons.timeline_rounded,
                    onPressed: () => Navigator.of(context)
                        .push(slideUp(TimelinePage(batch: batch))),
                  ),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(label: primaryLabel, onPressed: onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final verdict = outcome.verdict;
    final batch = verdict.batch;
    final rows = <(String, String)>[
      if (batch != null) ('Product', batch.productName),
      ('Producer', verdict.producerName ?? 'Not in the registry'),
      if (batch != null) ('Origin', batch.origin),
      if (batch != null)
        ('Unit', '${outcome.tag.serialLabel} of ${batch.quantity}'),
      if (batch != null) ('Batch', batch.label),
      if (verdict.scanCount != null)
        (
          'Scans',
          verdict.scanCount == 1 ? 'This one' : '${verdict.scanCount} so far'
        ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(rows[i].$1.toUpperCase(), style: AppText.label),
              ),
              Expanded(
                child: Text(
                  rows[i].$2,
                  style: AppText.bodyStrong,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _KeyLine extends StatelessWidget {
  const _KeyLine({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final key = base58Encode(outcome.tag.producerKey);
    return Row(
      children: [
        const Icon(Icons.key_rounded, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        const Text('SIGNED BY', style: AppText.label),
        const Spacer(),
        Text(shortKey(key), style: AppText.mono(12.5)),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.score, required this.explanation});

  final int score;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Text('SCAN RISK', style: AppText.label),
              Spacer(),
              Text('AI summary', style: AppText.small),
            ],
          ),
          const SizedBox(height: 16),
          RiskGauge(score: score),
          const SizedBox(height: 14),
          Text(
            explanation,
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}
