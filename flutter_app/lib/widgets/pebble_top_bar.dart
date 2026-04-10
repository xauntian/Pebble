import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'pill_chip.dart';

class PebbleTopBar extends StatelessWidget {
  const PebbleTopBar({
    super.key,
    this.showDate = false,
    this.dateLabel = 'Jun 10, 2024',
    this.avatarLabel = 'YT',
  });

  final bool showDate;
  final String dateLabel;
  final String avatarLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _MenuButton(),
        if (showDate) ...[
          const Spacer(),
          PillChip(
            label: dateLabel,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            backgroundColor: AppColors.glassTint,
            boxShadow: AppShadows.card,
            borderRadius: AppRadius.pill,
            leading: const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textPrimary,
            ),
            textStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
        ] else
          const Spacer(),
        _UserAvatar(label: avatarLabel),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.menu_rounded,
      size: 29,
      color: AppColors.textPrimary,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.avatar),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
