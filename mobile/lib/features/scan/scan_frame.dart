import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';

/// Dimmed camera with a square cut-out, corner brackets and a sweeping line.
class ScanFrame extends StatefulWidget {
  const ScanFrame({super.key});

  /// Where the cut-out sits inside a box of [size].
  static Rect frameFor(Size size) {
    final side = (size.width * 0.72).clamp(220.0, 320.0);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.4),
      width: side,
      height: side,
    );
  }

  @override
  State<ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: size,
              painter: _FramePainter(
                t: _controller.value,
                frame: ScanFrame.frameFor(size),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.t, required this.frame});

  final double t;
  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 30.0;
    const arm = 38.0;

    final cutout =
        RRect.fromRectAndRadius(frame, const Radius.circular(radius));
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(cutout),
    );
    canvas.drawPath(dim, Paint()..color = const Color(0xAA081410));

    final bracket = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final l = frame.left;
    final r = frame.right;
    final tp = frame.top;
    final b = frame.bottom;
    const rad = Radius.circular(radius);

    final path = Path()
      ..moveTo(l, tp + arm)
      ..lineTo(l, tp + radius)
      ..arcToPoint(Offset(l + radius, tp), radius: rad)
      ..lineTo(l + arm, tp)
      ..moveTo(r - arm, tp)
      ..lineTo(r - radius, tp)
      ..arcToPoint(Offset(r, tp + radius), radius: rad)
      ..lineTo(r, tp + arm)
      ..moveTo(r, b - arm)
      ..lineTo(r, b - radius)
      ..arcToPoint(Offset(r - radius, b), radius: rad)
      ..lineTo(r - arm, b)
      ..moveTo(l + arm, b)
      ..lineTo(l + radius, b)
      ..arcToPoint(Offset(l, b - radius), radius: rad)
      ..lineTo(l, b - arm);
    canvas.drawPath(path, bracket);

    final y =
        frame.top + 28 + (frame.height - 56) * Curves.easeInOut.transform(t);
    final sweep = Paint()
      ..color = AppColors.ochre
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(l + 22, y), Offset(r - 22, y), sweep);
    canvas.drawCircle(Offset(l + 22, y), 4, Paint()..color = AppColors.ochre);
    canvas.drawCircle(Offset(r - 22, y), 4, Paint()..color = AppColors.ochre);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.t != t || old.frame != frame;
}
