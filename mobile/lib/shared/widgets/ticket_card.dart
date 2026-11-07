import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';

/// A card in two halves with notches on the sides and a dashed tear line,
/// like a ticket stub. Drawn with paths, not clipped boxes.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.top, required this.bottom});

  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: const _HalfPainter(isTop: true),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: SizedBox(width: double.infinity, child: top),
          ),
        ),
        CustomPaint(
          painter: const _HalfPainter(isTop: false),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            child: SizedBox(width: double.infinity, child: bottom),
          ),
        ),
      ],
    );
  }
}

class _HalfPainter extends CustomPainter {
  const _HalfPainter({required this.isTop});

  final bool isTop;

  static const _r = 22.0; // outer corner radius
  static const _n = 12.0; // notch radius

  Path _path(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path();
    if (isTop) {
      p
        ..moveTo(0, _r)
        ..arcToPoint(const Offset(_r, 0), radius: const Radius.circular(_r))
        ..lineTo(w - _r, 0)
        ..arcToPoint(Offset(w, _r), radius: const Radius.circular(_r))
        ..lineTo(w, h - _n)
        ..arcToPoint(
          Offset(w - _n, h),
          radius: const Radius.circular(_n),
          clockwise: false,
        )
        ..lineTo(_n, h)
        ..arcToPoint(
          Offset(0, h - _n),
          radius: const Radius.circular(_n),
          clockwise: false,
        )
        ..close();
    } else {
      p
        ..moveTo(_n, 0)
        ..lineTo(w - _n, 0)
        ..arcToPoint(
          Offset(w, _n),
          radius: const Radius.circular(_n),
          clockwise: false,
        )
        ..lineTo(w, h - _r)
        ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
        ..lineTo(_r, h)
        ..arcToPoint(Offset(0, h - _r), radius: const Radius.circular(_r))
        ..lineTo(0, _n)
        ..arcToPoint(
          const Offset(_n, 0),
          radius: const Radius.circular(_n),
          clockwise: false,
        )
        ..close();
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawPath(path, Paint()..color = AppColors.card);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.line,
    );

    if (!isTop) {
      // Dashed tear line along the top edge of the lower half.
      final line = Path()
        ..moveTo(_n + 6, 0)
        ..lineTo(size.width - _n - 6, 0);
      final dashed = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.line;
      for (final metric in line.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          canvas.drawPath(metric.extractPath(distance, distance + 6), dashed);
          distance += 11;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HalfPainter old) => old.isTop != isTop;
}
