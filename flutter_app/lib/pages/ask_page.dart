import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/design_tokens.dart';
import '../widgets/glass_card.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 60, 30, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _MenuButton(),
              Spacer(),
              _UserBadge(),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'Knowledge of Water',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 25),
          for (final question in _questions) ...[
            _QuestionCard(question: question),
            const SizedBox(height: 15),
          ],
          const _AiSearchCard(suggestions: _suggestions),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.blackText,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: AppColors.blackText,
          ),
        ],
      ),
    );
  }
}

class _AiSearchCard extends StatelessWidget {
  const _AiSearchCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Search',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions
                  .map((suggestion) => _SuggestionChip(text: suggestion))
                  .toList(),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(15.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.keyboard_outlined,
                    size: 18,
                    color: AppColors.olive,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Click or Press to ask',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFAECA69), AppColors.olive],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 31, height: 31),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(50),
        boxShadow: AppShadows.dropdown,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0x80000000),
          ),
        ),
      ),
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
      color: AppColors.blackText,
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'YT',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.blackText,
        ),
      ),
    );
  }
}
