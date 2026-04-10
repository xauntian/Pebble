import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../widgets/map_place_card.dart';
import '../widgets/map_search_bar.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(constraints.maxWidth / 430.0, 1.0);
        final horizontalInset = (constraints.maxWidth - 430 * scale) / 2;

        return ColoredBox(
          color: AppColors.mapBase,
          child: Stack(
            children: [
              Positioned.fill(
                child: _MapBackdrop(
                  scale: scale,
                  horizontalInset: horizontalInset,
                ),
              ),
              Positioned(
                left: horizontalInset + 47 * scale,
                top: 60 * scale,
                child: SizedBox(
                  width: 336 * scale,
                  height: 44 * scale,
                  child: const MapSearchBar(),
                ),
              ),
              Positioned(
                left: horizontalInset + 86 * scale,
                top: 389 * scale,
                child: _MapPin(size: 71.5 * scale, selected: true),
              ),
              Positioned(
                left: horizontalInset + 127 * scale,
                top: 583 * scale,
                child: _MapPin(size: 25.5 * scale),
              ),
              Positioned(
                left: horizontalInset + 322 * scale,
                top: 258 * scale,
                child: _MapPin(size: 25.5 * scale),
              ),
              Positioned(
                left: horizontalInset + 262 * scale,
                top: 159 * scale,
                child: _MapPin(size: 25.5 * scale),
              ),
              Positioned(
                left: horizontalInset + 43 * scale,
                top: 330 * scale,
                child: _MapPin(size: 25.5 * scale),
              ),
              Positioned(
                left: horizontalInset + 198 * scale,
                top: 250 * scale,
                child: _MapPin(size: 25.5 * scale),
              ),
              Positioned(
                left: horizontalInset + 153 * scale,
                top: 284 * scale,
                child: SizedBox(
                  width: 262 * scale,
                  height: 158 * scale,
                  child: MapPlaceCard(snapshot: snapshot, scale: scale),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop({
    required this.scale,
    required this.horizontalInset,
  });

  final double scale;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _MapBackdropPainter(
              scale: scale,
              horizontalInset: horizontalInset,
            ),
          ),
        ),
        _StreetLabel(
          text: 'Civic Center',
          left: horizontalInset - 10 * scale,
          top: 84 * scale,
          fontSize: 22 * scale,
          weight: FontWeight.w800,
          color: AppColors.mapStreetLabel,
        ),
        _StreetLabel(
          text: 'Van Ness',
          left: horizontalInset + 68 * scale,
          top: 128 * scale,
          fontSize: 18 * scale,
          weight: FontWeight.w700,
          color: AppColors.mapStreetLabel,
        ),
        _StreetLabel(
          text: 'San Francisco\nCaltrain',
          left: horizontalInset + 220 * scale,
          top: 112 * scale,
          fontSize: 20 * scale,
          weight: FontWeight.w700,
          color: AppColors.mapStreetLabel,
          align: TextAlign.center,
        ),
        _StreetLabel(
          text: '16th St',
          left: horizontalInset + 42 * scale,
          top: 308 * scale,
          fontSize: 14 * scale,
          weight: FontWeight.w600,
          color: AppColors.mapStreetLabelSecondary,
        ),
        _StreetLabel(
          text: '24th St',
          left: horizontalInset + 48 * scale,
          top: 575 * scale,
          fontSize: 14 * scale,
          weight: FontWeight.w600,
          color: AppColors.mapStreetLabelSecondary,
        ),
        _StreetLabel(
          text: 'BART',
          left: horizontalInset + 18 * scale,
          top: 318 * scale,
          fontSize: 16 * scale,
          weight: FontWeight.w800,
          color: AppColors.mapStreetLabel,
          rotation: 1.56,
        ),
        _StreetLabel(
          text: '101',
          left: horizontalInset + 254 * scale,
          top: 707 * scale,
          fontSize: 11 * scale,
          weight: FontWeight.w700,
          color: const Color(0xFFB0A99E),
        ),
        _StreetLabel(
          text: '280',
          left: horizontalInset + 381 * scale,
          top: 748 * scale,
          fontSize: 11 * scale,
          weight: FontWeight.w700,
          color: const Color(0xFF5C7CC4),
        ),
      ],
    );
  }
}

class _StreetLabel extends StatelessWidget {
  const _StreetLabel({
    required this.text,
    required this.left,
    required this.top,
    required this.fontSize,
    required this.weight,
    required this.color,
    this.rotation = 0,
    this.align = TextAlign.left,
  });

  final String text;
  final double left;
  final double top;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final double rotation;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    Widget label = Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        height: 1,
        color: color.withValues(alpha: 0.92),
      ),
    );

    if (rotation != 0) {
      label = Transform.rotate(angle: rotation, child: label);
    }

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(child: label),
    );
  }
}

class _MapBackdropPainter extends CustomPainter {
  const _MapBackdropPainter({
    required this.scale,
    required this.horizontalInset,
  });

  final double scale;
  final double horizontalInset;

  Offset _point(double x, double y) => Offset(horizontalInset + x * scale, y * scale);

  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = AppColors.mapStreet
      ..strokeWidth = 1.15 * scale;

    for (double x = -10; x <= 440; x += 26) {
      canvas.drawLine(_point(x, 0), _point(x + 18, 932), streetPaint);
    }

    for (double y = 26; y <= 930; y += 34) {
      canvas.drawLine(_point(-20, y), _point(450, y - 18), streetPaint);
    }

    final blockPaint = Paint()..color = const Color(0x1ADAEECB);
    canvas.drawOval(
      Rect.fromCenter(
        center: _point(31, 859),
        width: 78 * scale,
        height: 60 * scale,
      ),
      blockPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: _point(178, 815),
        width: 124 * scale,
        height: 80 * scale,
      ),
      blockPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: _point(370, 872),
        width: 94 * scale,
        height: 64 * scale,
      ),
      blockPaint,
    );

    final transitColors = <Color>[
      AppColors.mapTransitRed,
      AppColors.mapTransitOrange,
      AppColors.mapTransitGreen,
      AppColors.mapTransitBlue,
    ];
    final transitPath = Path()
      ..moveTo(_point(243, -8).dx, _point(243, -8).dy)
      ..lineTo(_point(54, 180).dx, _point(54, 180).dy)
      ..lineTo(_point(56, 433).dx, _point(56, 433).dy)
      ..lineTo(_point(60, 656).dx, _point(60, 656).dy)
      ..lineTo(_point(18, 767).dx, _point(18, 767).dy)
      ..lineTo(_point(-4, 932).dx, _point(-4, 932).dy);
    for (int i = 0; i < transitColors.length; i++) {
      final transitPaint = Paint()
        ..color = transitColors[i]
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.3 * scale;
      canvas.drawPath(
        transitPath.shift(Offset(i * 4.4 * scale, 0)),
        transitPaint,
      );
    }

    final routePaint = Paint()
      ..color = AppColors.mapRouteRed
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final routePath = Path()
      ..moveTo(_point(214, 0).dx, _point(214, 0).dy)
      ..lineTo(_point(401, 148).dx, _point(401, 148).dy)
      ..lineTo(_point(430, 932).dx, _point(430, 932).dy);
    canvas.drawPath(routePath, routePaint);

    final waterPaint = Paint()
      ..color = AppColors.mapWater
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _point(396, 84).dx,
          _point(396, 84).dy,
          32 * scale,
          130 * scale,
        ),
        Radius.circular(18 * scale),
      ),
      waterPaint,
    );

    final markerPaint = Paint()..color = const Color(0xFFF95E6B);
    for (final dot in [
      _point(225, 14),
      _point(295, 56),
      _point(384, 124),
      _point(376, 827),
    ]) {
      canvas.drawCircle(dot, 3.4 * scale, markerPaint);
    }

    final stationPaint = Paint()..color = Colors.white.withValues(alpha: 0.86);
    for (final dot in [_point(51, 250), _point(60, 575)]) {
      canvas.drawCircle(dot, 6.2 * scale, stationPaint);
    }

    final highwayFill = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _point(265, 710),
          width: 24 * scale,
          height: 16 * scale,
        ),
        Radius.circular(6 * scale),
      ),
      highwayFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: _point(390, 752),
          width: 24 * scale,
          height: 16 * scale,
        ),
        Radius.circular(6 * scale),
      ),
      highwayFill,
    );
  }

  @override
  bool shouldRepaint(covariant _MapBackdropPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.horizontalInset != horizontalInset;
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.size,
    this.selected = false,
  });

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.66,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: size,
            color: AppColors.lime,
          ),
          if (selected)
            Positioned(
              top: size * 0.18,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
