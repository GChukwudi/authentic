import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';

enum SealGlyph { check, alert, cross, dash }

/// A scalloped stamp with a hand-drawn glyph. [t] runs 0 to 1: the stamp
/// scales and turns in, then the glyph draws itself.
class SealPainter extends CustomPainter {
  const SealPainter({
    required this.color,
    required this.glyph,
    this.t = 1,
    this.showGlyph = true,
  });

  final Color color;
  final SealGlyph glyph;
  final double t;
  final bool showGlyph;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 * 0.9;

    final bodyT = (t * 1.7).clamp(0.0, 1.0);
    final scale = Curves.easeOutBack.transform(bodyT);
    final turn = (1 - Curves.easeOut.transform(bodyT)) * -0.7;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.rotate(turn);

    const scallops = 18;
    final body = Path();
    for (var i = 0; i <= 360; i++) {
      final angle = i * math.pi / 180;
      final radius = r * (1 + 0.035 * math.cos(scallops * angle));
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      if (i == 0) {
        body.moveTo(x, y);
      } else {
        body.lineTo(x, y);
      }
    }
    body.close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawCircle(
      Offset.zero,
      r * 0.79,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..color = AppColors.paper.faded(0.5),
    );
    canvas.restore();
    if (!showGlyph) return;

    final progress =
        Curves.easeOut.transform(((t - 0.3) / 0.7).clamp(0.0, 1.0));
    if (progress <= 0) return;

    final u = r * 0.36;
    final path = Path();
    switch (glyph) {
      case SealGlyph.check:
        path
          ..moveTo(center.dx - u, center.dy + u * 0.05)
          ..lineTo(center.dx - u * 0.3, center.dy + u * 0.75)
          ..lineTo(center.dx + u * 1.1, center.dy - u * 0.75);
      case SealGlyph.alert:
        path
          ..moveTo(center.dx, center.dy - u * 0.95)
          ..lineTo(center.dx, center.dy + u * 0.2);
      case SealGlyph.cross:
        path
          ..moveTo(center.dx - u * 0.8, center.dy - u * 0.8)
          ..lineTo(center.dx + u * 0.8, center.dy + u * 0.8)
          ..moveTo(center.dx + u * 0.8, center.dy - u * 0.8)
          ..lineTo(center.dx - u * 0.8, center.dy + u * 0.8);
      case SealGlyph.dash:
        path
          ..moveTo(center.dx - u * 0.9, center.dy)
          ..lineTo(center.dx + u * 0.9, center.dy);
    }

    final stroke = Paint()
      ..color = AppColors.paper
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final trimmed = Path();
    for (final metric in path.computeMetrics()) {
      trimmed.addPath(
          metric.extractPath(0, metric.length * progress), Offset.zero);
    }
    canvas.drawPath(trimmed, stroke);

    if (glyph == SealGlyph.alert && progress > 0.85) {
      canvas.drawCircle(
        Offset(center.dx, center.dy + u * 0.85),
        r * 0.075,
        Paint()..color = AppColors.paper,
      );
    }
  }

  @override
  bool shouldRepaint(SealPainter old) =>
      old.t != t ||
      old.color != color ||
      old.glyph != glyph ||
      old.showGlyph != showGlyph;
}

class VerdictSeal extends StatefulWidget {
  const VerdictSeal({
    super.key,
    required this.color,
    required this.glyph,
    this.size = 150,
  });

  final Color color;
  final SealGlyph glyph;
  final double size;

  @override
  State<VerdictSeal> createState() => _VerdictSealState();
}

class _VerdictSealState extends State<VerdictSeal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: SealPainter(
          color: widget.color,
          glyph: widget.glyph,
          t: _controller.value,
        ),
      ),
    );
  }
}

/// Static logo mark.
class SealMark extends StatelessWidget {
  const SealMark({super.key, this.size = 30, this.color = AppColors.forest});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: SealPainter(color: color, glyph: SealGlyph.check),
    );
  }
}
