import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';
import 'package:mobile/core/format.dart';
import 'package:mobile/domain/models/batch.dart';
import 'package:mobile/shared/widgets/common.dart';
import 'package:mobile/features/timeline/timeline_view_model.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key, required this.batch});

  final BatchSummary batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(timelineViewModelProvider(batch.id));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: PageColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopBar(title: 'Custody trail'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: [
                    Text(batch.productName, style: AppText.display(38)),
                    const SizedBox(height: 6),
                    Text(
                      '${batch.origin}  ·  ${batch.label}',
                      style: AppText.small.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    events.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Could not load the trail.',
                        style: AppText.body,
                      ),
                      data: (list) => Column(
                        children: [
                          for (var i = 0; i < list.length; i++)
                            _TimelineRow(
                              event: list[i],
                              isFirst: i == 0,
                              isLast: i == list.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _kindColor(CustodyKind kind) => switch (kind) {
      CustodyKind.created => AppColors.forest,
      CustodyKind.handoff => AppColors.ink,
      CustodyKind.flagged => AppColors.danger,
    };

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final CustodyEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(event.kind);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: CustomPaint(
              painter: _RailPainter(
                color: color,
                isFirst: isFirst,
                isLast: isLast,
                filled: event.kind != CustodyKind.handoff,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(event.at).toUpperCase(),
                    style: AppText.mono(12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(event.title, style: AppText.heading),
                  const SizedBox(height: 4),
                  Text(
                    '${event.actor}  ·  ${event.place}',
                    style: AppText.body.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.filled,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    const nodeY = 10.0;
    const x = 12.0;
    final line = Paint()
      ..color = AppColors.line
      ..strokeWidth = 2;
    if (!isLast) {
      canvas.drawLine(const Offset(x, nodeY + 12), Offset(x, size.height), line);
    }
    if (!isFirst) {
      canvas.drawLine(const Offset(x, 0), const Offset(x, nodeY - 12), line);
    }
    canvas.drawCircle(
      const Offset(x, nodeY),
      9,
      Paint()..color = filled ? color : AppColors.paper,
    );
    if (!filled) {
      canvas.drawCircle(
        const Offset(x, nodeY),
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.filled != filled;
}
