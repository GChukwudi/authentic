import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';

abstract final class AppText {
  static const _serif = 'InstrumentSerif';
  static const _sans = 'Barlow';
  static const _mono = 'PlexMono';

  static TextStyle display(
    double size, {
    Color color = AppColors.ink,
    bool italic = false,
  }) =>
      TextStyle(
        fontFamily: _serif,
        fontSize: size,
        height: 1.02,
        letterSpacing: -size * 0.012,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static const heading = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkSoft,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.ink,
  );

  static const small = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.inkMuted,
  );

  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    height: 1.2,
    color: AppColors.inkMuted,
  );

  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.1,
  );

  static TextStyle mono(double size, {Color color = AppColors.ink}) =>
      TextStyle(
        fontFamily: _mono,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: color,
      );
}
