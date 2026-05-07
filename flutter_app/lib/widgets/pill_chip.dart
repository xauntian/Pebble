import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

const double _dropdownMenuInset = 3;
const double _dropdownShadowOutset = 20;
const double _dropdownPillIconSize = 10;
const double _dropdownPillIconGap = 5;
const EdgeInsets _dropdownPillPadding = EdgeInsets.fromLTRB(8, 0, 10, 0);
const _dropdownTransitionDuration = Duration(milliseconds: 500);
const _dropdownTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);
const _dropdownPillStrutStyle = StrutStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 10,
  height: 1,
  forceStrutHeight: true,
);
const _dropdownPillTextStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 10,
  fontWeight: FontWeight.w500,
  height: 1,
  decoration: TextDecoration.none,
  color: AppColors.textPrimary,
);

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
    this.labelWidth,
    this.shrinkLabel = false,
    this.labelAlignment = Alignment.centerLeft,
    this.textAlign = TextAlign.start,
    this.textHeightBehavior,
    this.strutStyle,
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
  final double? labelWidth;
  final bool shrinkLabel;
  final AlignmentGeometry labelAlignment;
  final TextAlign textAlign;
  final TextHeightBehavior? textHeightBehavior;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ?? AppTextStyles.chip;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = labelWidth ?? constraints.maxWidth;
                final labelText = Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: shrinkLabel
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: textAlign,
                  textHeightBehavior: textHeightBehavior,
                  strutStyle: strutStyle,
                  style: effectiveTextStyle,
                );

                return SizedBox(
                  width: width.isFinite ? width : null,
                  child: shrinkLabel
                      ? FittedBox(
                          alignment: labelAlignment,
                          fit: BoxFit.scaleDown,
                          child: labelText,
                        )
                      : labelText,
                );
              },
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
    this.labelWidth,
    this.showIcon = true,
  });

  final String label;
  final double? width;
  final double? labelWidth;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final chip = PillChip(
      label: label,
      height: 20,
      padding: _dropdownPillPadding,
      borderRadius: AppRadius.pill,
      labelWidth: labelWidth,
      textStyle: _dropdownPillTextStyle,
      labelAlignment: Alignment.center,
      textAlign: TextAlign.center,
      textHeightBehavior: _dropdownTextHeightBehavior,
      strutStyle: _dropdownPillStrutStyle,
      leading: showIcon
          ? const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: _dropdownPillIconSize,
              color: AppColors.textPrimary,
            )
          : null,
    );

    return width == null ? chip : SizedBox(width: width, child: chip);
  }
}

class FigmaPillDropdown<T> extends StatefulWidget {
  const FigmaPillDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    this.width,
    this.enabled = true,
  });

  final T value;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T> onSelected;
  final double? width;
  final bool enabled;

  @override
  State<FigmaPillDropdown<T>> createState() => _FigmaPillDropdownState<T>();
}

class _FigmaPillDropdownState<T> extends State<FigmaPillDropdown<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: _dropdownTransitionDuration,
      reverseDuration: _dropdownTransitionDuration,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_canOpen) {
      return;
    }

    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_overlayEntry != null || !_canOpen) {
      return;
    }

    final targetRect = _targetRectInOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _FigmaDropdownOverlay<T>(
          layerLink: _layerLink,
          offset: const Offset(
            -_dropdownShadowOutset - _dropdownMenuInset,
            -_dropdownShadowOutset - _dropdownMenuInset,
          ),
          targetRect: targetRect,
          animation: _menuAnimation,
          value: widget.value,
          items: widget.items,
          labelFor: widget.labelFor,
          onDismiss: _closeMenu,
          onSelected: (item) {
            _closeMenu();
            widget.onSelected(item);
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _menuController.forward(from: 0);
  }

  Rect? _targetRectInOverlay() {
    final targetBox = context.findRenderObject();
    final overlayBox = Overlay.of(context).context.findRenderObject();
    if (targetBox is! RenderBox ||
        overlayBox is! RenderBox ||
        !targetBox.hasSize) {
      return null;
    }

    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & targetBox.size;
  }

  void _closeMenu({bool updateState = true}) {
    if (_overlayEntry == null) {
      if (updateState && mounted && _isOpen) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
      return;
    }

    if (!updateState) {
      _removeOverlay();
      _isOpen = false;
      return;
    }

    _menuController.reverse().whenComplete(() {
      if (_overlayEntry == null) {
        return;
      }

      _removeOverlay();
      if (mounted) {
        setState(() => _isOpen = false);
      } else {
        _isOpen = false;
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool get _canOpen {
    if (!widget.enabled) {
      return false;
    }

    return widget.items.any((item) => item != widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = _canOpen;

    return Align(
      alignment: Alignment.centerLeft,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canOpen ? _toggleMenu : null,
          child: Semantics(
            button: canOpen,
            enabled: canOpen,
            expanded: _isOpen,
            child: AnimatedOpacity(
              opacity: _isOpen ? 0 : 1,
              duration: _dropdownTransitionDuration,
              curve: Curves.easeOutCubic,
              child: DropdownPillChip(
                label: widget.labelFor(widget.value),
                width: widget.width,
                showIcon: canOpen,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaDropdownOverlay<T> extends StatelessWidget {
  const _FigmaDropdownOverlay({
    required this.layerLink,
    required this.offset,
    required this.targetRect,
    required this.animation,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    required this.onDismiss,
  });

  static const double _minimumMenuWidth = 96;

  final LayerLink layerLink;
  final Offset offset;
  final Rect? targetRect;
  final Animation<double> animation;
  final T value;
  final List<T> items;
  final String Function(T item) labelFor;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final availableItems =
        items.where((item) => item != value).toList(growable: false);
    final menuWidth = _menuWidthFor(context, [
      value,
      ...availableItems,
    ]);
    final effectiveOffset = _effectiveOffset(context, menuWidth);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: effectiveOffset,
          child: FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.all(_dropdownShadowOutset),
                child: SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(
                      begin: const Offset(0, -0.04),
                      end: Offset.zero,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: menuWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A073433),
                              blurRadius: 20,
                              offset: Offset.zero,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(_dropdownMenuInset),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _FigmaSelectedDropdownItem<T>(
                                value: value,
                                label: labelFor(value),
                                onSelected: onSelected,
                              ),
                              for (final item in availableItems)
                                _FigmaDropdownMenuItem<T>(
                                  value: item,
                                  label: labelFor(item),
                                  onSelected: onSelected,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Offset _effectiveOffset(BuildContext context, double menuWidth) {
    final target = targetRect;
    if (target == null) {
      return offset;
    }

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final menuLeft = target.left + offset.dx + _dropdownShadowOutset;
    var shift = 0.0;
    final overflowRight = menuLeft + menuWidth - viewportWidth;
    if (overflowRight > 0) {
      shift -= overflowRight;
    }
    final shiftedLeft = menuLeft + shift;
    if (shiftedLeft < 0) {
      shift -= shiftedLeft;
    }

    return offset.translate(shift, 0);
  }

  double _menuWidthFor(BuildContext context, List<T> menuItems) {
    final widestPill = menuItems.fold<double>(_minimumMenuWidth, (
      maxWidth,
      item,
    ) {
      return math.max(
        maxWidth,
        _dropdownPillWidthFor(
          context,
          labelFor(item),
          showIcon: true,
        ),
      );
    });
    final maxScreenWidth = math.max(
      _minimumMenuWidth,
      MediaQuery.sizeOf(context).width - _dropdownShadowOutset * 2,
    );

    return (widestPill + _dropdownMenuInset * 2)
        .clamp(_minimumMenuWidth, maxScreenWidth)
        .toDouble();
  }

  double _dropdownPillWidthFor(
    BuildContext context,
    String label, {
    required bool showIcon,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _dropdownPillTextStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return painter.width +
        _dropdownPillPadding.horizontal +
        (showIcon ? _dropdownPillIconSize + _dropdownPillIconGap : 0);
  }
}

class _FigmaSelectedDropdownItem<T> extends StatelessWidget {
  const _FigmaSelectedDropdownItem({
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final String label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: SizedBox(
        width: double.infinity,
        child: DropdownPillChip(
          label: label,
          labelWidth: null,
        ),
      ),
    );
  }
}

class _FigmaDropdownMenuItem<T> extends StatelessWidget {
  const _FigmaDropdownMenuItem({
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final String label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: SizedBox(
        width: double.infinity,
        height: 20,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textHeightBehavior: _dropdownTextHeightBehavior,
              strutStyle: _dropdownPillStrutStyle,
              style: _dropdownPillTextStyle,
            ),
          ),
        ),
      ),
    );
  }
}
