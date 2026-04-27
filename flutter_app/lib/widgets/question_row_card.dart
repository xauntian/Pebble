import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pebble_glass_card.dart';

class QuestionRowCard extends StatelessWidget {
  const QuestionRowCard({
    super.key,
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  static const _animationDuration = Duration(milliseconds: 500);
  static const _animationCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: question,
      hint: expanded ? 'Collapse answer' : 'Expand answer',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: PebbleGlassCard(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: AnimatedSize(
              duration: _animationDuration,
              curve: _animationCurve,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: _animationDuration,
                        curve: _animationCurve,
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: _animationDuration,
                    switchInCurve: _animationCurve,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: expanded
                        ? Padding(
                            key: const ValueKey('answer'),
                            padding: const EdgeInsets.only(
                              top: AppSpacing.md,
                            ),
                            child: Text(
                              answer,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('collapsed')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
