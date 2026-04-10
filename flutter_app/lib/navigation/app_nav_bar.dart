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
    return PebbleGlassCard(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.nav)),
      padding: const EdgeInsets.symmetric(
        horizontal: 55,
        vertical: AppSpacing.navVerticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppNavButton(
            destination: AppDestination.home,
            currentDestination: currentDestination,
            onTap: () => onChanged(AppDestination.home),
          ),
          AppNavButton(
            destination: AppDestination.map,
            currentDestination: currentDestination,
            onTap: () => onChanged(AppDestination.map),
          ),
          AppNavButton(
            destination: AppDestination.ask,
            currentDestination: currentDestination,
            onTap: () => onChanged(AppDestination.ask),
          ),
        ],
      ),
    );
  }
}
