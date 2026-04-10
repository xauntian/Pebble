import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pebble_glass_card.dart';

class QuestionRowCard extends StatelessWidget {
  const QuestionRowCard({
    super.key,
    required this.question,
  });

  final String question;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
