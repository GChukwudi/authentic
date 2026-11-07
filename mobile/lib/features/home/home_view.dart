import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/core/format.dart';
import 'package:mobile/domain/models/verdict.dart';
import 'package:mobile/shared/routes.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/common.dart';
import 'package:mobile/shared/widgets/seal.dart';
import 'package:mobile/shared/widgets/verdict_style.dart';
import 'package:mobile/features/result/result_page.dart';
import 'package:mobile/features/home/home_view_model.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key, required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(homeViewModelProvider).recent;

    return SafeArea(
      bottom: false,
      child: PageColumn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          children: [
            const _Masthead(),
            const SizedBox(height: 26),
            _Hero(onScan: onScan),
            const SizedBox(height: 30),
            const _Steps(),
            const SizedBox(height: 34),
            SectionLabel('Recent checks', trailing: '${recent.length}'),
            const SizedBox(height: 14),
            if (recent.isEmpty)
              const _EmptyHistory()
            else
              for (final outcome in recent) ...[
                _HistoryTile(
                  outcome: outcome,
                  onTap: () => Navigator.of(context)
                      .push(slideUp(ResultPage(outcome: outcome))),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SealMark(size: 34),
        const SizedBox(width: 10),
        Text('Authentic', style: AppText.display(30)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.genuine,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Works offline', style: AppText.small.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        color: AppColors.forest,
        child: Stack(
          children: [
            Positioned(
              right: -70,
              top: -60,
              child: CustomPaint(
                size: const Size.square(260),
                painter: SealPainter(
                  color: AppColors.paper.faded(0.07),
                  glyph: SealGlyph.check,
                  showGlyph: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 32, 26, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHECK A PRODUCT', style: AppText.label.copyWith(color: AppColors.ochre)),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      style: AppText.display(52, color: AppColors.paper),
                      children: [
                        const TextSpan(text: 'Is it the\n'),
                        TextSpan(
                          text: 'real',
                          style: AppText.display(52, color: AppColors.ochre, italic: true),
                        ),
                        const TextSpan(text: ' thing?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Scan the tag on a product. We check the producer\'s signature, even without signal.',
                    style: AppText.body.copyWith(
                      color: AppColors.paper.faded(0.78),
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    label: 'Scan a tag',
                    icon: Icons.qr_code_scanner_rounded,
                    tone: ButtonTone.paper,
                    onPressed: onScan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    Widget cell(String n, String title, String body) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n, style: AppText.mono(13, color: AppColors.ochre)),
              const SizedBox(height: 8),
              Text(title, style: AppText.heading.copyWith(fontSize: 17)),
              const SizedBox(height: 4),
              Text(body, style: AppText.small.copyWith(fontSize: 13.5)),
            ],
          ),
        );

    Widget divider() => Container(
          width: 1,
          height: 84,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: AppColors.line,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cell('01', 'Signature', 'Signed by the producer'),
        divider(),
        cell('02', 'Registry', 'Recorded on Solana'),
        divider(),
        cell('03', 'History', 'Copies show up'),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: const Column(
        children: [
          SealMark(size: 54, color: AppColors.line),
          SizedBox(height: 14),
          Text('Nothing scanned yet', style: AppText.heading),
          SizedBox(height: 4),
          Text(
            'Your checks will appear here.',
            style: AppText.small,
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.outcome, required this.onTap});

  final ScanOutcome outcome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final verdict = outcome.verdict;
    final style = styleOf(verdict.kind);
    final title = verdict.batch?.productName ?? style.title;
    final subtitle = verdict.producerName ?? 'Unverified tag';

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 14, 0),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.heading,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$subtitle  ·  ${timeAgo(outcome.at)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Center(child: VerdictChip(kind: verdict.kind)),
            ],
          ),
        ),
      ),
    );
  }
}
