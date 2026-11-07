import 'package:flutter/material.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_text.dart';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppText.family,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      surface: AppColors.paper,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.forest,
      selectionColor: Color(0x330F3D2E),
    ),
  );
}
