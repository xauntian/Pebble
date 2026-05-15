import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'pill_chip.dart';

class PebbleTopBar extends StatelessWidget {
  const PebbleTopBar({
    super.key,
    this.showDate = false,
    this.dateLabel = 'Jun 10, 2024',
    this.onMenuPressed,
  });

  final bool showDate;
  final String dateLabel;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _MenuButton(onPressed: onMenuPressed),
            if (showDate) ...[
              const Spacer(),
              PillChip(
                label: dateLabel,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                boxShadow: const [],
                borderRadius: AppRadius.pill,
                textStyle: AppTextStyles.date,
              ),
              const Spacer(),
            ] else
              const Spacer(),
            const _UserIcon(),
          ],
        );
      },
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
          width: 39,
          height: 39,
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

class _UserIcon extends StatelessWidget {
  const _UserIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/figma/menu-user.svg',
      width: 39,
      height: 39,
    );
  }
}
