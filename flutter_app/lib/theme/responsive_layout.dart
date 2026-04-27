import 'dart:math' as math;

import 'app_spacing.dart';

class ResponsiveLayout {
  const ResponsiveLayout._();

  static double horizontalPadding(double width) {
    if (width <= 430) {
      return AppSpacing.pageHorizontal;
    }

    return (width * 0.08).clamp(AppSpacing.pageHorizontal, 120).toDouble();
  }

  static double contentWidth(double width) {
    return math.max(0.0, width - horizontalPadding(width) * 2);
  }
}
