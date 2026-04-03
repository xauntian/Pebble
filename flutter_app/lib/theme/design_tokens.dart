import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF5FBEF);
  static const Color blackText = Color(0xFF132525);
  static const Color secondaryText = Color(0xFF355051);
  static const Color mutedText = Color(0xFF949494);
  static const Color olive = Color(0xFF4C7C09);
  static const Color lime = Color(0xFF68DA1F);
  static const Color softGreen = Color(0xFFDAEECB);
  static const Color whiteGlass = Color(0x80FFFFFF);
  static const Color whiteTint = Color(0x33FFFFFF);
  static const Color tealShadow = Color(0x1A094A49);
  static const Color greenShadow = Color(0x1A4C7C09);
  static const Color mapShadow = Color(0x33132525);
  static const Color ringTrack = Color(0xFFE2F0D8);
}

class AppRadii {
  static const double card = 20;
  static const double navBar = 28;
  static const double navButton = 15;
  static const double pill = 20;
  static const double search = 100;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.greenShadow,
      blurRadius: 10,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> dropdown = [
    BoxShadow(
      color: AppColors.tealShadow,
      blurRadius: 10,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> navButton = [
    BoxShadow(
      color: Color(0x26355051),
      blurRadius: 6.8,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> mapCard = [
    BoxShadow(
      color: AppColors.mapShadow,
      blurRadius: 30,
      offset: Offset(0, 0),
    ),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.olive,
      onPrimary: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.blackText,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.blackText,
        height: 1,
      ),
      titleLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.blackText,
        height: 1,
      ),
      titleMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.blackText,
        height: 1,
      ),
      bodyLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.blackText,
      ),
      bodyMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.blackText,
      ),
      bodySmall: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.mutedText,
      ),
    ),
  );
}
