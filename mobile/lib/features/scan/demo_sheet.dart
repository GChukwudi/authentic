import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/providers.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/data/mock/mock_world.dart';
import 'package:mobile/shared/widgets/app_buttons.dart';
import 'package:mobile/shared/widgets/verdict_style.dart';

/// Bottom sheet of sample tags, for emulators and for demos without prints.
Future<DemoTag?> showDemoSheet(BuildContext context) {
  return showModalBottomSheet<DemoTag>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x99081410),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _DemoSheet(),
  );
}

class _DemoSheet extends ConsumerWidget {
  const _DemoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(mockWorldProvider).demoTags;
    final online = ref.watch(onlineProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
            const SizedBox(height: 20),
            Text('Try a demo tag', style: AppText.display(34)),
            const SizedBox(height: 6),
            Text(
              'Sample tags signed by the seeded producers. Each one ends differently.',
              style: AppText.body,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.inkSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Simulate no signal', style: AppText.bodyStrong),
                  ),
                  Switch(
                    value: !online,
                    activeTrackColor: AppColors.forest,
                    onChanged: (v) =>
                        ref.read(onlineProvider.notifier).state = !v,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final tag = tags[i];
                  final style = styleOf(tag.expected);
                  return Pressable(
                    onTap: () => Navigator.of(context).pop(tag),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tag.title, style: AppText.heading),
                                const SizedBox(height: 2),
                                Text(tag.hint, style: AppText.small),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 20,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
