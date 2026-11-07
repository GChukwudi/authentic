import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/core/encoding.dart';
import 'package:mobile/core/format.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/shared/routes.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/common.dart';
import 'package:mobile/features/producer/create_batch_page.dart';
import 'package:mobile/features/producer/producer_view_model.dart';
import 'package:mobile/features/producer/tag_sheet_page.dart';

class ProducerView extends ConsumerWidget {
  const ProducerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(producerViewModelProvider);

    return SafeArea(
      bottom: false,
      child: PageColumn(
        child: switch (state) {
          ProducerLoading() => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.forest,
              ),
            ),
          ProducerNeedsSetup(:final busy, :final error) =>
            _SetupView(busy: busy, error: error),
          final ProducerReady ready => _BatchesView(state: ready),
        },
      ),
    );
  }
}

class _SetupView extends ConsumerStatefulWidget {
  const _SetupView({required this.busy, required this.error});

  final bool busy;
  final String? error;

  @override
  ConsumerState<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<_SetupView> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text('PRODUCER MODE', style: AppText.label.copyWith(color: AppColors.ochre)),
        const SizedBox(height: 14),
        Text('Issue tags\nbuyers can trust.', style: AppText.display(52)),
        const SizedBox(height: 14),
        Text(
          'Register once. Every unit you make gets its own signed QR tag that anyone can check.',
          style: AppText.body.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.paperDeep,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.key_rounded, size: 24, color: AppColors.forest),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'A signing key is created on this phone. It never leaves it, and nobody can sign tags in your name.',
                  style: AppText.body.copyWith(fontSize: 15, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LabeledField(
          label: 'Organisation name',
          hint: 'Gakenke Highlands Co-op',
          controller: _name,
          error: widget.error,
          onChanged: (_) {},
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Create key and register',
          busy: widget.busy,
          onPressed: () =>
              ref.read(producerViewModelProvider.notifier).register(_name.text),
        ),
      ],
    );
  }
}

class _BatchesView extends ConsumerWidget {
  const _BatchesView({required this.state});

  final ProducerReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Text('PRODUCER', style: AppText.label.copyWith(color: AppColors.ochre)),
        const SizedBox(height: 10),
        Text(state.profile.name, style: AppText.display(40)),
        const SizedBox(height: 12),
        _KeyChip(publicKey: state.profile.publicKey),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Stat(value: '${state.batches.length}', label: 'Batches'),
            const _StatDivider(),
            _Stat(value: '${state.unitsIssued}', label: 'Tags issued'),
            const _StatDivider(),
            _Stat(value: '${state.unitsScanned}', label: 'Scanned'),
          ],
        ),
        const SizedBox(height: 26),
        PrimaryButton(
          label: 'New batch',
          icon: Icons.add_rounded,
          onPressed: () =>
              Navigator.of(context).push(slideUp(const CreateBatchPage())),
        ),
        const SizedBox(height: 32),
        SectionLabel('Your batches', trailing: '${state.batches.length}'),
        const SizedBox(height: 14),
        if (state.batches.isEmpty)
          const _EmptyBatches()
        else
          for (final batch in state.batches) ...[
            _BatchCard(batch: batch),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.display(44)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppText.label),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: AppColors.line,
      );
}

class _KeyChip extends StatefulWidget {
  const _KeyChip({required this.publicKey});

  final String publicKey;

  @override
  State<_KeyChip> createState() => _KeyChipState();
}

class _KeyChipState extends State<_KeyChip> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.publicKey));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: _copy,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check_rounded : Icons.key_rounded,
                size: 16,
                color: _copied ? AppColors.genuine : AppColors.inkSoft,
              ),
              const SizedBox(width: 8),
              Text(
                _copied ? 'Copied' : shortKey(widget.publicKey),
                style: AppText.mono(13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBatches extends StatelessWidget {
  const _EmptyBatches();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.line),
          const SizedBox(height: 12),
          Text('No batches yet', style: AppText.heading),
          const SizedBox(height: 4),
          Text(
            'Create one to get a sheet of signed tags.',
            style: AppText.small,
          ),
        ],
      ),
    );
  }
}

class _BatchCard extends ConsumerWidget {
  const _BatchCard({required this.batch});

  final BatchSummary batch;

  Future<void> _recall(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      barrierColor: const Color(0x99081410),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _RecallSheet(),
    );
    if (reason == null) return;
    await ref.read(producerViewModelProvider.notifier).recall(batch.id, reason);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recalled = batch.isRecalled;
    final fraction =
        batch.quantity == 0 ? 0.0 : batch.unitsScanned / batch.quantity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.productName, style: AppText.heading.copyWith(fontSize: 20)),
                    const SizedBox(height: 3),
                    Text(
                      '${batch.origin}  ·  ${batch.label}  ·  ${formatDate(batch.createdAt)}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(recalled: recalled),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 8,
              color: AppColors.paperDeep,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  color: recalled ? AppColors.danger : AppColors.forest,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${batch.unitsScanned} of ${batch.quantity} scanned',
            style: AppText.mono(13, color: AppColors.inkSoft),
          ),
          if (recalled && batch.recallReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Recalled: ${batch.recallReason}',
              style: AppText.small.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: 'Tag sheet',
                  icon: Icons.qr_code_2_rounded,
                  onPressed: () => Navigator.of(context)
                      .push(slideUp(TagSheetPage(batch: batch))),
                ),
              ),
              if (!recalled) ...[
                const SizedBox(width: 10),
                GhostButton(
                  label: 'Recall',
                  color: AppColors.danger,
                  onPressed: () => _recall(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.recalled});

  final bool recalled;

  @override
  Widget build(BuildContext context) {
    final color = recalled ? AppColors.danger : AppColors.genuine;
    final tint = recalled ? AppColors.dangerTint : AppColors.genuineTint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        recalled ? 'Recalled' : 'Active',
        style: AppText.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RecallSheet extends StatefulWidget {
  const _RecallSheet();

  @override
  State<_RecallSheet> createState() => _RecallSheetState();
}

class _RecallSheetState extends State<_RecallSheet> {
  static const _reasons = [
    'Quality issue',
    'Safety concern',
    'Counterfeits found',
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('Recall this batch?', style: AppText.display(36)),
            const SizedBox(height: 8),
            Text(
              'Anyone who scans a unit from it will see a red "Recalled" verdict. This is recorded on-chain and cannot be undone.',
              style: AppText.body,
            ),
            const SizedBox(height: 20),
            Text('REASON', style: AppText.label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _reasons.length; i++)
                  Pressable(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _selected == i ? AppColors.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: _selected == i ? AppColors.ink : AppColors.line,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        _reasons[i],
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 15,
                          color: _selected == i ? AppColors.paper : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'Recall batch',
              tone: ButtonTone.danger,
              onPressed: () => Navigator.of(context).pop(_reasons[_selected]),
            ),
            const SizedBox(height: 10),
            GhostButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
