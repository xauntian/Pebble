import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/pebble_glass_card.dart';
import 'app_destination.dart';
import 'app_nav_button.dart';

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

        return PebbleGlassCard(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.nav)),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.navVerticalPadding,
          ),
          child: Row(
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
        );
      },
    );
  }
}
