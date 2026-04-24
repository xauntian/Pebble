import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/pebble_glass_card.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _sanFrancisco = LatLng(37.7749, -122.4194);
  static const _defaultZoom = 13.4;
  static const _detailZoom = 15.2;
  static const _detailFadeDuration = Duration(milliseconds: 180);

  final MapController _mapController = MapController();
  WaterPoint? _selectedPoint;
  WaterPoint? _detailPoint;
  bool _isDetailVisible = false;

  static const List<WaterPoint> _waterPoints = [
    WaterPoint(
      id: 'animal-park',
      name: 'Animal Park',
      regionCode: 'SF,CA',
      point: LatLng(37.7694, -122.4862),
      score: 92,
      tds: 118,
      ph: 7.3,
      status: WaterStatus.safe,
      drinkingAdvice: 'This Place is better to drink after filter',
      lastTested: 'Jun 10, 2024',
    ),
    WaterPoint(
      id: 'mission-creek-tap',
      name: 'Mission Creek Tap',
      regionCode: 'SF,CA',
      point: LatLng(37.7727, -122.3910),
      score: 78,
      tds: 164,
      ph: 7.0,
      status: WaterStatus.uncertain,
      drinkingAdvice: 'Filter before drinking from this nearby source',
      lastTested: 'May 10, 2025',
    ),
    WaterPoint(
      id: 'embarcadero-fountain',
      name: 'Embarcadero Fountain',
      regionCode: 'SF,CA',
      point: LatLng(37.7955, -122.3937),
      score: 84,
      tds: 136,
      ph: 7.5,
      status: WaterStatus.safe,
      drinkingAdvice: 'Good for drinking after a quick flush',
      lastTested: 'Apr 18, 2025',
    ),
    WaterPoint(
      id: 'soma-station',
      name: 'SoMa Station',
      regionCode: 'SF,CA',
      point: LatLng(37.7812, -122.4080),
      score: 63,
      tds: 242,
      ph: 6.6,
      status: WaterStatus.uncertain,
      drinkingAdvice: 'Use a filter before drinking here',
      lastTested: 'Mar 22, 2025',
    ),
    WaterPoint(
      id: 'bayview-pier',
      name: 'Bayview Pier',
      regionCode: 'SF,CA',
      point: LatLng(37.7297, -122.3742),
      score: 41,
      tds: 389,
      ph: 6.1,
      status: WaterStatus.unsafe,
      drinkingAdvice: 'Avoid drinking until the next test clears',
      lastTested: 'Feb 08, 2025',
    ),
  ];

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _showPointDetails(WaterPoint point) {
    setState(() {
      _selectedPoint = point;
      _detailPoint = point;
      _isDetailVisible = true;
    });

    _mapController.move(_detailCameraCenter(point.point), _detailZoom);
  }

  LatLng _detailCameraCenter(LatLng point) {
    const longitudeOffset = 0.0048;

    return LatLng(point.latitude, point.longitude + longitudeOffset);
  }

  void _hidePointDetails() {
    if (_detailPoint == null && !_isDetailVisible && _selectedPoint == null) {
      return;
    }

    setState(() {
      _selectedPoint = null;
      _isDetailVisible = false;
    });

    Future<void>.delayed(_detailFadeDuration, () {
      if (!mounted || _isDetailVisible) {
        return;
      }

      setState(() => _detailPoint = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sanFrancisco,
              initialZoom: _defaultZoom,
              minZoom: 11,
              maxZoom: 18,
              backgroundColor: const Color(0xFFF5F6F2),
              onTap: (_, __) => _hidePointDetails(),
              onPositionChanged: (_, hasGesture) {
                if (hasGesture) {
                  _hidePointDetails();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.pebble.water_quality_companion',
              ),
              MarkerLayer(
                markers: [
                  for (final point in _waterPoints)
                    Marker(
                      point: point.point,
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      child: _WaterMarker(
                        point: point,
                        selected: point == _selectedPoint,
                        onTap: () => _showPointDetails(point),
                      ),
                    ),
                  if (_detailPoint case final detailPoint?)
                    Marker(
                      point: detailPoint.point,
                      width: 332,
                      height: 178,
                      alignment: Alignment.centerRight,
                      child: _WaterPointMarkerDetail(
                        point: detailPoint,
                        visible: _isDetailVisible,
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors, CARTO',
                    prependCopyright: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSpacing.pageHorizontal,
          right: AppSpacing.pageHorizontal,
          top: AppSpacing.xl,
          child: const MapSearchBar(),
        ),
      ],
    );
  }
}

class WaterPoint {
  const WaterPoint({
    required this.id,
    required this.name,
    required this.regionCode,
    required this.point,
    required this.score,
    required this.tds,
    required this.ph,
    required this.status,
    required this.drinkingAdvice,
    required this.lastTested,
  });

  final String id;
  final String name;
  final String regionCode;
  final LatLng point;
  final int score;
  final int tds;
  final double ph;
  final WaterStatus status;
  final String drinkingAdvice;
  final String lastTested;
}

enum WaterStatus {
  safe('Safe', Color(0xFF27B96D)),
  uncertain('Uncertain', Color(0xFFF0A323)),
  unsafe('Unsafe', Color(0xFFE84C4F));

  const WaterStatus(this.label, this.color);

  final String label;
  final Color color;
}

class _WaterMarker extends StatelessWidget {
  const _WaterMarker({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final WaterPoint point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerSize = selected ? 46.0 : 38.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            boxShadow: AppShadows.mapCard,
          ),
          child: Icon(
            Icons.water_drop_rounded,
            size: markerSize * 0.66,
            color: point.status.color,
          ),
        ),
      ),
    );
  }
}

class _WaterPointCard extends StatelessWidget {
  const _WaterPointCard({
    required this.point,
  });

  final WaterPoint? point;

  @override
  Widget build(BuildContext context) {
    final waterPoint = point;

    return IgnorePointer(
      ignoring: waterPoint == null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: waterPoint == null ? 0 : 1,
        child: PebbleGlassCard(
          blurSigma: 46.25,
          boxShadow: AppShadows.mapCard,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
          padding: EdgeInsets.zero,
          child: waterPoint == null
              ? const SizedBox(width: 262, height: 158)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlaceImageHeader(point: waterPoint),
                    _PlaceInfoBody(point: waterPoint),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WaterPointMarkerDetail extends StatelessWidget {
  const _WaterPointMarkerDetail({
    required this.point,
    required this.visible,
  });

  final WaterPoint point;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: _MapPageState._detailFadeDuration,
        curve: Curves.easeOutCubic,
        opacity: visible ? 1 : 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 50),
            _WaterPointCard(point: point),
          ],
        ),
      ),
    );
  }
}

class _PlaceImageHeader extends StatelessWidget {
  const _PlaceImageHeader({
    required this.point,
  });

  final WaterPoint point;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 262,
      height: 64,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.card),
          topRight: Radius.circular(AppRadius.card),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6DA66A),
                    Color(0xFF244D3F),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 36,
              top: -20,
              child: Icon(
                Icons.park_rounded,
                size: 96,
                color: Color(0x33FFFFFF),
              ),
            ),
            const Positioned(
              left: 12,
              top: 8,
              child: Icon(
                Icons.water_drop_rounded,
                size: 22,
                color: Color(0x80FFFFFF),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD9000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        point.name,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    point.regionCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceInfoBody extends StatelessWidget {
  const _PlaceInfoBody({
    required this.point,
  });

  final WaterPoint point;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 262,
      height: 94,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 147,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      point.drinkingAdvice,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Last time: ${point.lastTested}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _RatingContainer(score: point.score),
          ],
        ),
      ),
    );
  }
}

class _RatingContainer extends StatelessWidget {
  const _RatingContainer({
    required this.score,
  });

  final int score;

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.clamp(0, 100) / 100;

    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(70),
            painter: _RatingEllipsePainter(
              progress: normalizedScore,
              color: AppColors.lime,
            ),
          ),
          Text(
            '$score',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingEllipsePainter extends CustomPainter {
  const _RatingEllipsePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const double _startAngle = -80 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.14;
    final basePaint = Paint()
      ..color = AppColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
        rect.deflate(strokeWidth / 2), 0, math.pi * 2, false, basePaint);
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      _startAngle,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RatingEllipsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
