import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'pill_chip.dart';

class PebbleTopBar extends StatelessWidget {
  const PebbleTopBar({
    super.key,
    this.showDate = false,
    this.dateLabel = 'Jun 10, 2024',
    this.avatarLabel = 'YT',
    this.onMenuPressed,
  });

  final bool showDate;
  final String dateLabel;
  final String avatarLabel;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MenuButton(onPressed: onMenuPressed),
        if (showDate) ...[
          const Spacer(),
          PillChip(
            label: dateLabel,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            backgroundColor: AppColors.white.withValues(alpha: 0.2),
            boxShadow: const [],
            borderRadius: AppRadius.pill,
            textStyle: AppTextStyles.date,
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
  const _MenuButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open menu',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: const SizedBox(
          width: 29,
          height: 29,
          child: Icon(
            Icons.menu_rounded,
            size: 29,
            color: AppColors.textPrimary,
          ),
        ),
      ),
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
