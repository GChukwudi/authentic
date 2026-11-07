import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/shared/widgets/common.dart';
import 'package:mobile/shared/widgets/tag_qr.dart';
import 'package:mobile/features/producer/tag_sheet_view_model.dart';

class TagSheetPage extends ConsumerWidget {
  const TagSheetPage({super.key, required this.batch});

  final BatchSummary batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagSheetViewModelProvider(batch.id));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: PageColumn(
          child: Column(
            children: [
              const TopBar(title: 'Tag sheet'),
              Expanded(
                child: tags.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.forest,
                    ),
                  ),
                  error: (_, __) => const Center(
                    child:
                        Text('Could not sign the tags.', style: AppText.body),
                  ),
                  data: (list) => CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(batch.productName,
                                  style: AppText.display(38)),
                              const SizedBox(height: 6),
                              Text(
                                '${list.length} signed tags  ·  ${batch.label}',
                                style: AppText.small.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Print one per unit. Tap a tag to show it large, then scan it from another phone.',
                                style: AppText.body,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.84,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _TagCell(serial: i, data: list[i]),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagCell extends StatelessWidget {
  const _TagCell({required this.serial, required this.data});

  final int serial;
  final String data;

  String get _label => '#${serial.toString().padLeft(4, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.paper,
        barrierColor: const Color(0x99081410),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => _BigTag(label: _label, data: data),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Column(
          children: [
            Expanded(child: TagQr(data: data)),
            const SizedBox(height: 8),
            Text(_label, style: AppText.mono(11, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _BigTag extends StatelessWidget {
  const _BigTag({required this.label, required this.data});

  final String label;
  final String data;

  @override
  Widget build(BuildContext context) {
    final side = (MediaQuery.of(context).size.width - 96).clamp(200.0, 320.0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: TagQr(data: data, size: side),
            ),
            const SizedBox(height: 18),
            Text(label, style: AppText.mono(17.5)),
            const SizedBox(height: 6),
            const Text('Scan this from another phone.', style: AppText.small),
          ],
        ),
      ),
    );
  }
}
