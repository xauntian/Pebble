import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../services/ask_ai_responder.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';
import '../widgets/pebble_glass_card.dart';
import '../widgets/pebble_top_bar.dart';
import '../widgets/pill_chip.dart';
import '../widgets/question_row_card.dart';

class AskPage extends StatefulWidget {
  const AskPage({
    super.key,
    required this.snapshot,
    this.aiResponder = const LocalAskAiResponder(),
  });

  final AppSnapshot snapshot;
  final AskAiResponder aiResponder;

  static const List<_QuestionAnswer> _questionAnswers = [
    _QuestionAnswer(
      question: 'What is TDS?',
      answer:
          'TDS means total dissolved solids. It refers to tiny substances dissolved in water, such as minerals, salts, and some metals. A TDS reading helps show how "heavy" or mineral-rich the water is.',
    ),
    _QuestionAnswer(
      question: 'What are TDS Levels?',
      answer:
          'TDS levels tell you how much dissolved material is in the water. A low number usually means fewer dissolved solids, while a high number means more minerals, salts, or other particles. However, TDS alone cannot prove water is completely safe.',
    ),
    _QuestionAnswer(
      question: 'Is clear water safe?',
      answer:
          'Clear water is not always safe. Some harmful substances, like bacteria, chemicals, or heavy metals, may not change the color, smell, or taste of water. Testing gives a more reliable answer than appearance.',
    ),
    _QuestionAnswer(
      question: 'How to improve water quality',
      answer:
          'You can improve water quality by using a suitable filter, keeping bottles and containers clean, and avoiding unknown water sources. When the water looks, smells, or tastes unusual, it is better to test it before drinking.',
    ),
  ];

  static const List<String> _suggestions = [
    'How to update water quality ?',
    'What is PH?',
  ];

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  int? _expandedQuestionIndex;

  void _toggleQuestion(int index) {
    setState(() {
      _expandedQuestionIndex = _expandedQuestionIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            ResponsiveLayout.horizontalPadding(constraints.maxWidth);
        final contentWidth =
            ResponsiveLayout.contentWidth(constraints.maxWidth);
        final scale = math.min(1.0, contentWidth / 370.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.pageTop,
            horizontalPadding,
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
              for (final entry in AskPage._questionAnswers.indexed) ...[
                SizedBox(
                  width: contentWidth,
                  child: QuestionRowCard(
                    question: entry.$2.question,
                    answer: entry.$2.answer,
                    expanded: _expandedQuestionIndex == entry.$1,
                    onTap: () => _toggleQuestion(entry.$1),
                  ),
                ),
                SizedBox(height: 15 * scale),
              ],
              SizedBox(
                width: contentWidth,
                child: _AiSearchCard(
                  suggestions: AskPage._suggestions,
                  scale: scale,
                  responder: widget.aiResponder,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestionAnswer {
  const _QuestionAnswer({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

enum _AiSearchMode { normal, typing, ready, recording, answer }

const _aiSearchTransitionDuration = Duration(milliseconds: 500);
const _aiSearchTransitionCurve = Curves.easeOutCubic;

Widget _aiSearchControlTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: _aiSearchTransitionCurve,
    reverseCurve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: curvedAnimation,
    child: child,
  );
}

Widget _aiSearchBottomLayoutBuilder(
  Widget? currentChild,
  List<Widget> previousChildren,
) {
  return Stack(
    alignment: Alignment.bottomCenter,
    clipBehavior: Clip.none,
    children: [
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}

BoxDecoration _aiSearchContainerDecoration({
  required double radius,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    color: AppColors.chipGlass,
    shape: shape,
    borderRadius:
        shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
    border: Border.all(color: AppColors.white.withValues(alpha: 0.36)),
    boxShadow: AppShadows.field,
  );
}

BoxDecoration _aiSearchActionButtonDecoration({
  required double radius,
  BoxShape shape = BoxShape.rectangle,
}) {
  return BoxDecoration(
    shape: shape,
    borderRadius:
        shape == BoxShape.rectangle ? BorderRadius.circular(radius) : null,
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.oliveLight, AppColors.olive],
    ),
    boxShadow: AppShadows.field,
  );
}

class _AiSearchCard extends StatefulWidget {
  const _AiSearchCard({
    required this.suggestions,
    required this.scale,
    required this.responder,
  });

  final List<String> suggestions;
  final double scale;
  final AskAiResponder responder;

  @override
  State<_AiSearchCard> createState() => _AiSearchCardState();
}

class _AiSearchCardState extends State<_AiSearchCard> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _AiSearchMode _mode = _AiSearchMode.normal;
  AiSearchResponse? _response;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _enterTyping() {
    setState(() {
      _mode = _textController.text.trim().isEmpty
          ? _AiSearchMode.typing
          : _AiSearchMode.ready;
      _response = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _selectSuggestion(String suggestion) {
    _textController.text = suggestion;
    setState(() {
      _mode = _AiSearchMode.ready;
      _response = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleTextChanged(String value) {
    final nextMode =
        value.trim().isEmpty ? _AiSearchMode.typing : _AiSearchMode.ready;
    if (_mode != nextMode || _response != null) {
      setState(() {
        _mode = nextMode;
        _response = null;
      });
    }
  }

  void _toggleRecording() {
    if (_mode == _AiSearchMode.recording) {
      _finishVoiceSearch();
      return;
    }

    _focusNode.unfocus();
    setState(() {
      _mode = _AiSearchMode.recording;
      _response = null;
    });
  }

  void _returnToNormal() {
    _focusNode.unfocus();
    setState(() {
      _mode = _AiSearchMode.normal;
      _response = null;
    });
  }

  Future<void> _finishVoiceSearch() async {
    if (_isLoading) {
      return;
    }

    _textController.text = 'Voice search';
    await _submit(AiSearchSource.voice);
  }

  Future<void> _submit(AiSearchSource source) async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty) {
      _enterTyping();
      return;
    }

    _focusNode.unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await widget.responder.ask(
        AiSearchRequest(prompt: prompt, source: source),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
        _mode = _AiSearchMode.answer;
        _isLoading = false;
      });
    } on Exception {
      if (!mounted) {
        return;
      }

      setState(() {
        _response = AiSearchResponse(
          prompt: prompt,
          answer: 'AI Search is not available right now.',
        );
        _mode = _AiSearchMode.answer;
        _isLoading = false;
      });
    }
  }

  void _resetSearch() {
    _textController.clear();
    _focusNode.unfocus();
    setState(() {
      _mode = _AiSearchMode.normal;
      _response = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final isAnswer = _mode == _AiSearchMode.answer;
    final innerHeight = (isAnswer ? 204.0 : 179.0) * scale;

    return AnimatedSize(
      duration: _aiSearchTransitionDuration,
      curve: _aiSearchTransitionCurve,
      alignment: Alignment.topCenter,
      child: PebbleGlassCard(
        padding: EdgeInsets.all(15 * scale),
        child: SizedBox(
          height: innerHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: isAnswer,
                  child: AnimatedOpacity(
                    duration: _aiSearchTransitionDuration,
                    curve: _aiSearchTransitionCurve,
                    opacity: isAnswer ? 0 : 1,
                    child: ExcludeSemantics(
                      excluding: isAnswer,
                      child: _buildNormalContent(context, scale),
                    ),
                  ),
                ),
              ),
              if (isAnswer)
                Positioned.fill(
                  child: _buildAnswerContent(context, scale),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'AI Search',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildNormalContent(BuildContext context, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        SizedBox(height: 12 * scale),
        _buildSuggestionRow(scale),
        const Spacer(),
        AnimatedSwitcher(
          duration: _aiSearchTransitionDuration,
          switchInCurve: _aiSearchTransitionCurve,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _aiSearchControlTransitionBuilder,
          layoutBuilder: _aiSearchBottomLayoutBuilder,
          child: KeyedSubtree(
            key: ValueKey(_mode),
            child: _buildSearchControl(scale),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerContent(BuildContext context, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        SizedBox(height: 10 * scale),
        Expanded(child: _buildAnswerPanel(scale)),
        SizedBox(height: 10 * scale),
        Align(
          alignment: Alignment.centerRight,
          child: _DoneButton(
            scale: scale,
            onTap: _resetSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionRow(double scale) {
    return Row(
      children: [
        _SuggestionChip(
          key: const ValueKey('ai-search-suggestion-0'),
          text: widget.suggestions[0],
          width: 208 * scale,
          scale: scale,
          onTap: () => _selectSuggestion(widget.suggestions[0]),
        ),
        SizedBox(width: 6 * scale),
        _SuggestionChip(
          key: const ValueKey('ai-search-suggestion-1'),
          text: widget.suggestions[1],
          width: 100 * scale,
          scale: scale,
          onTap: () => _selectSuggestion(widget.suggestions[1]),
        ),
      ],
    );
  }

  Widget _buildSearchControl(double scale) {
    if (_mode == _AiSearchMode.recording) {
      return Center(
        child: _VoicePrompt(
          scale: scale,
          label: 'Recording...',
          onTap: _toggleRecording,
        ),
      );
    }

    if (_mode == _AiSearchMode.typing || _mode == _AiSearchMode.ready) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CircleIconButton(
            key: const ValueKey('ai-search-voice-small'),
            scale: scale,
            icon: Icons.graphic_eq_rounded,
            onTap: _returnToNormal,
          ),
          SizedBox(width: 20 * scale),
          Expanded(
            child: SizedBox(
              height: 31 * scale,
              child: Row(
                children: [
                  Expanded(child: _buildPromptField(scale)),
                  SizedBox(width: 10 * scale),
                  _SearchSubmitButton(
                    key: const ValueKey('ai-search-submit'),
                    scale: scale,
                    isLoading: _isLoading,
                    onTap:
                        _isLoading ? null : () => _submit(AiSearchSource.typed),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _CircleIconButton(
          key: const ValueKey('ai-search-keyboard'),
          scale: scale,
          icon: Icons.keyboard_outlined,
          onTap: _enterTyping,
        ),
        Expanded(
          child: _VoicePrompt(
            scale: scale,
            label: 'Click or Press to ask',
            onTap: _toggleRecording,
          ),
        ),
        SizedBox(width: 31 * scale, height: 31 * scale),
      ],
    );
  }

  Widget _buildPromptField(double scale) {
    return DecoratedBox(
      decoration: _aiSearchContainerDecoration(radius: 8 * scale),
      child: TextField(
        key: const ValueKey('ai-search-input'),
        controller: _textController,
        focusNode: _focusNode,
        onChanged: _handleTextChanged,
        onSubmitted: (_) => _submit(AiSearchSource.typed),
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.textPrimary,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0x80000000),
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildAnswerPanel(double scale) {
    final response = _response;

    return SizedBox(
      key: const ValueKey('ai-search-answer-panel'),
      width: double.infinity,
      child: DecoratedBox(
        decoration: _aiSearchContainerDecoration(radius: 15 * scale),
        child: Padding(
          padding: EdgeInsets.all(15 * scale),
          child: response == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.prompt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0x80000000),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          response.answer,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0x80000000),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    super.key,
    required this.scale,
    required this.icon,
    required this.onTap,
  });

  final double scale;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 31 * scale,
          height: 31 * scale,
          decoration: BoxDecoration(
            color: AppColors.limeSoft,
            borderRadius: BorderRadius.circular(15.5 * scale),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18 * scale,
            color: AppColors.olive,
          ),
        ),
      ),
    );
  }
}

class _VoicePrompt extends StatelessWidget {
  const _VoicePrompt({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: 8 * scale),
        GestureDetector(
          key: const ValueKey('ai-search-voice'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 48.33 * scale,
            height: 48.33 * scale,
            decoration: _aiSearchActionButtonDecoration(
              radius: 24.165 * scale,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 26 * scale,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSubmitButton extends StatelessWidget {
  const _SearchSubmitButton({
    super.key,
    required this.scale,
    required this.isLoading,
    required this.onTap,
  });

  final double scale;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 46 * scale,
        height: 31 * scale,
        decoration: _aiSearchActionButtonDecoration(radius: 8 * scale),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.white,
              ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({
    required this.scale,
    required this.onTap,
  });

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 37 * scale,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        decoration: _aiSearchActionButtonDecoration(radius: 8 * scale),
        alignment: Alignment.center,
        child: Text(
          'Done',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    super.key,
    required this.text,
    required this.width,
    required this.scale,
    this.onTap,
  });

  final String text;
  final double width;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = SizedBox(
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

    if (onTap == null) {
      return chip;
    }

    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}
