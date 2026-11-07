import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';

/// One typeface throughout: Inter.
abstract final class AppText {
  static const family = 'Inter';

  /// Inter reads larger than the serif these sizes were picked for,
  /// so display text is scaled down to keep the same visual weight.
  static const _displayScale = 0.7;

  static TextStyle display(double size, {Color color = AppColors.ink}) {
    final scaled = size * _displayScale;
    return TextStyle(
      fontFamily: family,
      fontSize: scaled,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -scaled * 0.025,
      color: color,
    );
  }

  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.inkSoft,
  );

  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.ink,
  );

  static const small = TextStyle(
    fontFamily: family,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkMuted,
  );

  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.2,
    color: AppColors.inkMuted,
  );

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );

  /// Codes and keys: same typeface, tabular figures so digits line up.
  static TextStyle mono(double size, {Color color = AppColors.ink}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
