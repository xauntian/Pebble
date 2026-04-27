import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/sf_water_test_reports.dart';
import '../models/app_snapshot.dart';
import '../models/water_test_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/responsive_layout.dart';
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
  static const _detailFadeDuration = Duration(milliseconds: 500);

  final MapController _mapController = MapController();
  WaterPoint? _selectedPoint;
  WaterPoint? _detailPoint;
  bool _isDetailVisible = false;

  static final List<WaterPoint> _waterPoints =
      SfWaterTestReports.latestByLocation()
          .map(
            (report) => WaterPoint.fromReport(
              report,
              reports: SfWaterTestReports.forLocation(report.locationId),
            ),
          )
          .toList(growable: false);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            ResponsiveLayout.horizontalPadding(constraints.maxWidth);

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
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
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
                          height: 220,
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
            const Positioned(
              left: -1,
              right: -1,
              bottom: 0,
              height: 139,
              child: _BottomNavGradient(),
            ),
            Positioned(
              left: horizontalPadding,
              right: horizontalPadding,
              top: 60,
              child: const MapSearchBar(),
            ),
          ],
        );
      },
    );
  }
}

class _BottomNavGradient extends StatelessWidget {
  const _BottomNavGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00DAEECB),
            AppColors.limeSoft,
          ],
          stops: [0.08633, 0.91396],
        ),
      ),
    );
  }
}

class WaterPoint {
  const WaterPoint({
    required this.id,
    required this.name,
    required this.regionCode,
    required this.specificLocation,
    required this.point,
    required this.score,
    required this.tds,
    required this.ph,
    required this.temperatureCelsius,
    required this.cr6MgPerL,
    required this.status,
    required this.drinkingAdvice,
    required this.lastTested,
    required this.reports,
  });

  factory WaterPoint.fromReport(
    WaterTestReport report, {
    required List<WaterTestReport> reports,
  }) {
    final status = WaterStatus.fromScore(report.score);

    return WaterPoint(
      id: report.locationId,
      name: report.locationName,
      regionCode: report.regionCode,
      specificLocation: report.specificLocation,
      point: LatLng(report.latitude, report.longitude),
      score: report.score,
      tds: report.tds,
      ph: report.ph,
      temperatureCelsius: report.temperatureCelsius,
      cr6MgPerL: report.cr6MgPerL,
      status: status,
      drinkingAdvice: status.drinkingAdvice,
      lastTested: report.testedAtLabel,
      reports: reports,
    );
  }

  final String id;
  final String name;
  final String regionCode;
  final String specificLocation;
  final LatLng point;
  final int score;
  final int tds;
  final double ph;
  final double temperatureCelsius;
  final double cr6MgPerL;
  final WaterStatus status;
  final String drinkingAdvice;
  final String lastTested;
  final List<WaterTestReport> reports;

  int get reportCount => reports.length;
}

enum WaterStatus {
  safe('Safe', AppColors.waterQualitySafe),
  uncertain('Uncertain', AppColors.waterQualityCaution),
  unsafe('Unsafe', AppColors.waterQualityUnsafe);

  const WaterStatus(this.label, this.color);

  final String label;
  final Color color;

  static WaterStatus fromScore(int score) {
    if (score >= 80) {
      return WaterStatus.safe;
    }
    if (score >= 55) {
      return WaterStatus.uncertain;
    }
    return WaterStatus.unsafe;
  }

  String get drinkingAdvice => switch (this) {
        WaterStatus.safe => 'Good for drinking after a quick flush',
        WaterStatus.uncertain => 'Filter before drinking from this source',
        WaterStatus.unsafe => 'Avoid drinking until the next test clears',
      };
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
          duration: _MapPageState._detailFadeDuration,
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
        duration: _MapPageState._detailFadeDuration,
        opacity: waterPoint == null ? 0 : 1,
        child: PebbleGlassCard(
          blurSigma: 46.25,
          boxShadow: AppShadows.mapCard,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
          padding: EdgeInsets.zero,
          child: waterPoint == null
              ? const SizedBox(width: 262, height: 187)
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
            const SizedBox(width: 42),
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
      height: 123,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            point.specificLocation,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          'Last: ${point.lastTested} - ${point.reportCount} tests',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            height: 1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _RatingContainer(score: point.score),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ReportMetric(
                    label: 'TDS',
                    value: '${point.tds}',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ReportMetric(
                    label: 'pH',
                    value: point.ph.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ReportMetric(
                    label: 'Temp C',
                    value: point.temperatureCelsius.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ReportMetric(
                    label: 'Cr6+ mg/L',
                    value: point.cr6MgPerL.toStringAsFixed(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.limeSoft.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w700,
                height: 1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingContainer extends StatefulWidget {
  const _RatingContainer({
    required this.score,
  });

  final int score;

  @override
  State<_RatingContainer> createState() => _RatingContainerState();
}

class _RatingContainerState extends State<_RatingContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _targetProgress = 0;

  @override
  void initState() {
    super.initState();
    _targetProgress = _normalizedScore(widget.score);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = _buildAnimation();
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _RatingContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextProgress = _normalizedScore(widget.score);
    if (nextProgress != _targetProgress) {
      _targetProgress = nextProgress;
      _progressAnimation = _buildAnimation();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _normalizedScore(int score) => score.clamp(0, 100).toDouble() / 100;

  Animation<double> _buildAnimation() {
    return CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ).drive(Tween<double>(begin: 0, end: _targetProgress));
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = AppColors.waterQualityScoreColor(widget.score);

    return SizedBox(
      width: 70,
      height: 70,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(70),
                painter: _RatingEllipsePainter(
                  progress: _progressAnimation.value,
                  color: progressColor,
                ),
              ),
              child!,
            ],
          );
        },
        child: Text(
          '${widget.score}',
          maxLines: 1,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
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
      ..color = color.withValues(alpha: 0.18)
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
