import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text_styles.dart';

const double _dropdownMenuInset = 3;
const double _dropdownShadowOutset = 20;
const _dropdownTransitionDuration = Duration(milliseconds: 500);

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
            child: SizedBox(
              width: labelWidth,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle ?? AppTextStyles.chip,
              ),
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
    this.labelWidth = 35,
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
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      borderRadius: AppRadius.pill,
      labelWidth: labelWidth,
      textStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
        color: AppColors.textPrimary,
      ),
      leading: showIcon
          ? const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 10,
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

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _FigmaDropdownOverlay<T>(
          layerLink: _layerLink,
          offset: const Offset(
            -_dropdownShadowOutset - _dropdownMenuInset,
            -_dropdownShadowOutset - _dropdownMenuInset,
          ),
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
    required this.animation,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.onSelected,
    required this.onDismiss,
  });

  static const double _menuWidth = 96;

  final LayerLink layerLink;
  final Offset offset;
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
          offset: offset,
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
                      width: _menuWidth,
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
      child: DropdownPillChip(
        label: label,
        labelWidth: null,
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
          padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
