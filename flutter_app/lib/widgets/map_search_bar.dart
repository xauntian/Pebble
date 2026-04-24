import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'pebble_glass_card.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      blurSigma: 4,
      color: AppColors.glass,
      boxShadow: AppShadows.card,
      borderRadius: const BorderRadius.all(
        Radius.circular(AppRadius.search),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.search_rounded,
            size: 24,
            color: AppColors.textPrimary,
          ),
          Expanded(
            child: Text(
              'Search place',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
