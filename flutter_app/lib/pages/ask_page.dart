import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/pebble_glass_card.dart';
import '../widgets/pebble_top_bar.dart';
import '../widgets/pill_chip.dart';
import '../widgets/question_row_card.dart';

class AskPage extends StatelessWidget {
  const AskPage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  static const List<String> _questions = [
    'What is TDS?',
    'What is TDS Levels?',
    'Is clear water safe?',
    'How to improve water quality',
  ];

  static const List<String> _suggestions = [
    'How to update water quality ?',
    'What is PH?',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(370.0, constraints.maxWidth);
        final scale = contentWidth / 370.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.pageTop,
            AppSpacing.pageHorizontal,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PebbleTopBar(),
              const SizedBox(height: AppSpacing.section),
              Text(
                'Knowledge of Water',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.section),
              for (final question in _questions) ...[
                SizedBox(
                  width: contentWidth,
                  height: 54 * scale,
                  child: QuestionRowCard(question: question),
                ),
                SizedBox(height: 15 * scale),
              ],
              SizedBox(
                width: contentWidth,
                height: 209 * scale,
                child: _AiSearchCard(
                  suggestions: _suggestions,
                  scale: scale,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AiSearchCard extends StatelessWidget {
  const _AiSearchCard({
    required this.suggestions,
    required this.scale,
  });

  final List<String> suggestions;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      padding: EdgeInsets.all(15 * scale),
      child: SizedBox(
        height: 179 * scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Search',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12 * scale),
            Row(
              children: [
                _SuggestionChip(
                  text: suggestions[0],
                  width: 208 * scale,
                  scale: scale,
                ),
                SizedBox(width: 6 * scale),
                _SuggestionChip(
                  text: suggestions[1],
                  width: 100 * scale,
                  scale: scale,
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 31 * scale,
                  height: 31 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.limeSoft,
                    borderRadius: BorderRadius.circular(15.5 * scale),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_outlined,
                    size: 18 * scale,
                    color: AppColors.olive,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Click or Press to ask',
                        style: TextStyle(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Container(
                        width: 48.33 * scale,
                        height: 48.33 * scale,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.oliveLight, AppColors.olive],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 26 * scale,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 31 * scale, height: 31 * scale),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.width,
    required this.scale,
  });

  final String text;
  final double width;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PillChip(
        label: text,
        height: 32 * scale,
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        borderRadius: AppRadius.round * scale,
        backgroundColor: AppColors.chipGlass,
        boxShadow: AppShadows.field,
        textStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12 * scale,
          color: const Color(0x80000000),
        ),
      ),
    );
  }
}
