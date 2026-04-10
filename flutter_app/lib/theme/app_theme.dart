import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.olive,
      onPrimary: AppColors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.copyWith(
      headlineLarge: AppTextStyles.pageTitle,
      headlineSmall: AppTextStyles.pageTitle,
      titleLarge: AppTextStyles.cardTitle,
      titleMedium: AppTextStyles.bodyBold,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.bodySmall,
      bodySmall: AppTextStyles.label,
      labelLarge: AppTextStyles.bodyBold,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.label,
    ),
  );
}
