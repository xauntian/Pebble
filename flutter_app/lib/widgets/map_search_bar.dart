import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';
import 'pebble_glass_card.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onActivate,
    required this.onChanged,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onActivate;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return Row(
        children: [
          Expanded(
            child: _SearchFieldContainer(
              child: TextField(
                key: const ValueKey('map-search-input'),
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (_) => onSearch(),
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.textPrimary,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search place',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHint,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          _MapSearchButton(onTap: onSearch),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onActivate,
      child: _SearchFieldContainer(
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
    );
  }
}

class _SearchFieldContainer extends StatelessWidget {
  const _SearchFieldContainer({
    required this.child,
  });

  final Widget child;

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
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 20),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MapSearchButton extends StatelessWidget {
  const _MapSearchButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search map',
      child: GestureDetector(
        key: const ValueKey('map-search-submit'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.olive,
            borderRadius: BorderRadius.circular(AppRadius.search),
            boxShadow: AppShadows.card,
          ),
          child: const SizedBox(
            width: 68,
            height: 44,
            child: Icon(
              Icons.search_rounded,
              size: 24,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
