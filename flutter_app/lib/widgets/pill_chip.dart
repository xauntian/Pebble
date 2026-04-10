import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.backgroundColor = AppColors.white,
    this.boxShadow = AppShadows.field,
    this.textStyle,
    this.borderRadius = AppRadius.round,
    this.height,
  });

  final String label;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final List<BoxShadow> boxShadow;
  final TextStyle? textStyle;
  final double borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle ?? AppTextStyles.chip,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 5),
            trailing!,
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: height == null
          ? content
          : SizedBox(
              height: height,
              child: Center(child: content),
            ),
    );
  }
}

class DropdownPillChip extends StatelessWidget {
  const DropdownPillChip({
    super.key,
    required this.label,
    this.width,
  });

  final String label;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final chip = PillChip(
      label: label,
      height: 18,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      borderRadius: AppRadius.pill,
      textStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 8,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      leading: const Icon(
        Icons.expand_more_rounded,
        size: 10,
        color: AppColors.textPrimary,
      ),
    );

    return width == null ? chip : SizedBox(width: width, child: chip);
  }
}
