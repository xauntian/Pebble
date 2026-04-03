import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.color = AppColors.whiteGlass,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppRadii.card),
    ),
    this.blurSigma = 4,
    this.boxShadow = AppShadows.card,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final BorderRadius borderRadius;
  final double blurSigma;
  final List<BoxShadow> boxShadow;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: boxShadow,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              border: border ?? Border.all(color: AppColors.whiteTint),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
