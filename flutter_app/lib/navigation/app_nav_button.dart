import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import 'app_destination.dart';

class AppNavButton extends StatelessWidget {
  const AppNavButton({
    super.key,
    required this.destination,
    required this.currentDestination,
    required this.onTap,
  });

  final AppDestination destination;
  final AppDestination currentDestination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = destination == currentDestination;
    final iconAsset = switch (destination) {
      AppDestination.home => isActive
          ? 'assets/nav/home_active.svg'
          : 'assets/nav/home_inactive.svg',
      AppDestination.map => isActive
          ? 'assets/nav/map_active.svg'
          : 'assets/nav/map_inactive.svg',
      AppDestination.ask => isActive
          ? 'assets/nav/ask_active.svg'
          : 'assets/nav/ask_inactive.svg',
    };
    final iconColor =
        isActive ? AppColors.navIconActive : AppColors.navIconInactive;
    final iconSize = destination == AppDestination.home ? 26.0 : 28.0;
    final keyValue = switch (destination) {
      AppDestination.home => 'nav-home',
      AppDestination.map => 'nav-map',
      AppDestination.ask => 'nav-ask',
    };
    final semanticLabel = switch (destination) {
      AppDestination.home => 'Home',
      AppDestination.map => 'Map',
      AppDestination.ask => 'Ask',
    };

    return Semantics(
      button: true,
      selected: isActive,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(keyValue),
          borderRadius: BorderRadius.circular(AppRadius.navItem),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 73,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? AppColors.olive : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.navItem),
              boxShadow: isActive ? AppShadows.navItem : null,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
