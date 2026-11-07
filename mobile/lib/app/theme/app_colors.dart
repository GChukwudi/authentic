import 'package:flutter/material.dart';

/// Paper and ink. Flat colour, hairline borders, no blur or gradients.
abstract final class AppColors {
  static const paper = Color(0xFFF6F1E7);
  static const paperDeep = Color(0xFFEBE3D1);
  static const card = Color(0xFFFFFCF6);
  static const line = Color(0xFFDDD4C0);

  static const ink = Color(0xFF10241D);
  static const inkSoft = Color(0xFF3F5149);
  static const inkMuted = Color(0xFF7D8A83);

  static const forest = Color(0xFF0F3D2E);
  static const ochre = Color(0xFFE0A33A);

  static const genuine = Color(0xFF1F8A5F);
  static const genuineTint = Color(0xFFDCEFE3);
  static const caution = Color(0xFFD9891A);
  static const cautionTint = Color(0xFFF9E8C8);
  static const danger = Color(0xFFC1432E);
  static const dangerTint = Color(0xFFF7DDD5);
  static const neutral = Color(0xFF6F7C75);
  static const neutralTint = Color(0xFFE4E6DF);
}

extension ColorFade on Color {
  /// Same colour at [opacity] from 0 to 1. Named `faded` because newer
  /// Flutter versions give Color its own `a` getter, which would shadow it.
  Color faded(double opacity) => withAlpha((opacity * 255).round());
}
