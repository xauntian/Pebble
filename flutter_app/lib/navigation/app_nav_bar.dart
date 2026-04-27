import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/pebble_glass_card.dart';
import 'app_destination.dart';
import 'app_nav_button.dart';

const _navIndicatorDuration = Duration(milliseconds: 500);
const _navItemHeight = 52.0;

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentDestination,
    required this.onChanged,
  });

  final AppDestination currentDestination;
  final ValueChanged<AppDestination> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const buttonCount = 3;
        const preferredButtonWidth = 73.0;
        const minButtonWidth = 56.0;
        const minGap = 4.0;
        final horizontalPadding =
            (constraints.maxWidth * 0.14).clamp(AppSpacing.sm, AppSpacing.xxl);
        final contentWidth = constraints.maxWidth - horizontalPadding * 2;
        final buttonWidth =
            ((contentWidth - minGap * (buttonCount - 1)) / buttonCount)
                .clamp(minButtonWidth, preferredButtonWidth);
        final gap =
            ((contentWidth - buttonWidth * buttonCount) / (buttonCount - 1))
                .clamp(0.0, double.infinity);
        final selectedIndex = currentDestination.index;
        final indicatorLeft = selectedIndex * (buttonWidth + gap);

        return PebbleGlassCard(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.nav)),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.navVerticalPadding,
          ),
          child: SizedBox(
            width: contentWidth,
            height: _navItemHeight,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: _navIndicatorDuration,
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: 0,
                  width: buttonWidth,
                  height: _navItemHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.olive,
                      borderRadius: BorderRadius.circular(AppRadius.navItem),
                      boxShadow: AppShadows.navItem,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppNavButton(
                      destination: AppDestination.home,
                      currentDestination: currentDestination,
                      onTap: () => onChanged(AppDestination.home),
                      width: buttonWidth,
                    ),
                    SizedBox(width: gap),
                    AppNavButton(
                      destination: AppDestination.map,
                      currentDestination: currentDestination,
                      onTap: () => onChanged(AppDestination.map),
                      width: buttonWidth,
                    ),
                    SizedBox(width: gap),
                    AppNavButton(
                      destination: AppDestination.ask,
                      currentDestination: currentDestination,
                      onTap: () => onChanged(AppDestination.ask),
                      width: buttonWidth,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
