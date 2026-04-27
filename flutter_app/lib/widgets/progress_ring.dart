import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 92,
    this.strokeWidth = 9.2,
    this.progressColor,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutCubic,
  });

  final double value;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Duration animationDuration;
  final Curve animationCurve;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _targetValue = _normalizedValue(widget.value);
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _progressAnimation = _buildAnimation();
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = _normalizedValue(widget.value);
    final animationChanged =
        oldWidget.animationCurve != widget.animationCurve ||
            oldWidget.animationDuration != widget.animationDuration;

    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }

    if (nextValue != _targetValue || animationChanged) {
      _targetValue = nextValue;
      _progressAnimation = _buildAnimation();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _normalizedValue(double value) => value.clamp(0.0, 1.0).toDouble();

  Animation<double> _buildAnimation() {
    return CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    ).drive(Tween<double>(begin: 0, end: _targetValue));
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = widget.progressColor ??
        AppColors.waterQualityScoreColor(_targetValue * 100);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _ProgressRingPainter(
                  value: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  progressColor: progressColor,
                ),
              ),
              child!,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.value,
    required this.strokeWidth,
    required this.progressColor,
  });

  final double value;
  final double strokeWidth;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor;
  }
}
