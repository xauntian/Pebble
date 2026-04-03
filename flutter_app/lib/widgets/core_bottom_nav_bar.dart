import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'glass_card.dart';

class CoreBottomNavBar extends StatelessWidget {
  const CoreBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.navBar)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            key: const ValueKey('nav-home'),
            icon: Icons.insert_chart_outlined_rounded,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            key: const ValueKey('nav-map'),
            icon: Icons.map_outlined,
            label: 'Map',
            isActive: currentIndex == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            key: const ValueKey('nav-ask'),
            icon: Icons.chrome_reader_mode_outlined,
            label: 'Ask',
            isActive: currentIndex == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.navButton),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 73,
              height: 52,
              decoration: BoxDecoration(
                color: isActive ? AppColors.olive : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.navButton),
                boxShadow: AppShadows.navButton,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 28,
                color: isActive ? Colors.white : AppColors.blackText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
