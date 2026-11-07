import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';

Color riskColor(int score) {
  if (score < 35) return AppColors.genuine;
  if (score < 70) return AppColors.caution;
  return AppColors.danger;
}

String riskWord(int score) {
  if (score < 35) return 'Low';
  if (score < 70) return 'Elevated';
  return 'High';
}

class RiskGauge extends StatelessWidget {
  const RiskGauge({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final shown = (value * 100).round();
        return SizedBox(
          width: 190,
          height: 112,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GaugePainter(value: value, color: riskColor(score)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$shown', style: AppText.display(44)),
                  Text(
                    riskWord(score).toUpperCase(),
                    style: AppText.label.copyWith(color: riskColor(score)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final center = Offset(size.width / 2, size.height - 6);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.paperDeep;
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (value > 0) {
      canvas.drawArc(rect, math.pi, math.pi * value, false, fill);
    }

    // Tick marks at 0, 25, 50, 75 and 100.
    final tick = Paint()
      ..strokeWidth = 1.4
      ..color = AppColors.inkMuted.faded(0.55);
    for (var i = 0; i <= 4; i++) {
      final angle = math.pi + math.pi * i / 4;
      final inner = radius - stroke - 5;
      final outer = radius - stroke - 11;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}
