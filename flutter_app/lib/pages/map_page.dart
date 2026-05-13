import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../data/sf_water_test_reports.dart';
import '../models/app_snapshot.dart';
import '../models/water_test_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _detailHideTimer;
  WaterPoint? _selectedPoint;
  WaterPoint? _detailPoint;
  bool _isDetailVisible = false;
  bool _isSearchExpanded = false;
  String _searchQuery = '';

  static final List<WaterPoint> _testedWaterPoints =
      SfWaterTestReports.latestByLocation()
          .map(
            (report) => WaterPoint.fromReport(
              report,
              reports: SfWaterTestReports.forLocation(report.locationId),
            ),
          )
          .toList(growable: false);

  static final List<WaterPoint> _waterPoints = [
    ..._testedWaterPoints,
    ..._possiblePublicDrinkPoints.where(
      (candidate) =>
          !_testedWaterPoints.any((point) => point.id == candidate.id),
    ),
  ];

  static const List<WaterPoint> _possiblePublicDrinkPoints = [
    WaterPoint.possiblePublicDrink(
      id: 'civic-center-plaza-fountain',
      name: 'Civic Center Plaza',
      regionCode: 'SF, CA',
      specificLocation:
          'Possible public drinking fountain near Civic Center Plaza',
      point: LatLng(37.7793, -122.4175),
    ),
    WaterPoint.possiblePublicDrink(
      id: 'dolores-park-fountain',
      name: 'Dolores Park',
      regionCode: 'SF, CA',
      specificLocation: 'Possible public drinking fountain inside Dolores Park',
      point: LatLng(37.7596, -122.4269),
    ),
    WaterPoint.possiblePublicDrink(
      id: 'golden-gate-park-conservatory',
      name: 'Golden Gate Park',
      regionCode: 'SF, CA',
      specificLocation:
          'Possible public drinking fountain near Conservatory of Flowers',
      point: LatLng(37.7726, -122.4602),
    ),
    WaterPoint.possiblePublicDrink(
      id: 'crissy-field-east-beach',
      name: 'Crissy Field East Beach',
      regionCode: 'SF, CA',
      specificLocation:
          'Possible public drinking fountain near the East Beach promenade',
      point: LatLng(37.8044, -122.4514),
    ),
    WaterPoint.possiblePublicDrink(
      id: 'union-square-plaza',
      name: 'Union Square Plaza',
      regionCode: 'SF, CA',
      specificLocation: 'Possible public drinking fountain near Union Square',
      point: LatLng(37.788, -122.4074),
    ),
    WaterPoint.possiblePublicDrink(
      id: 'pier-7-promenade',
      name: 'Pier 7 Promenade',
      regionCode: 'SF, CA',
      specificLocation: 'Possible public drinking fountain near Pier 7',
      point: LatLng(37.7982, -122.3959),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  @override
  void dispose() {
    _detailHideTimer?.cancel();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChanged)
      ..dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    if (mounted) {
      setState(() {
        if (!_searchFocusNode.hasFocus && _searchQuery.trim().isEmpty) {
          _isSearchExpanded = false;
        }
      });
    }
  }

  bool get _isSearchActive =>
      _isSearchExpanded ||
      _searchFocusNode.hasFocus ||
      _searchQuery.trim().isNotEmpty;

  List<WaterPoint> get _visibleWaterPoints {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      return _waterPoints;
    }

    return _waterPoints
        .where((point) => _matchesWaterPoint(point, query))
        .toList(growable: false);
  }

  List<WaterPoint> get _searchResults {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      return const [];
    }

    return _visibleWaterPoints.take(6).toList(growable: false);
  }

  void _activateSearch() {
    setState(() => _isSearchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _updateSearchQuery(String value) {
    final shouldHideDetails = _selectedPoint != null && value.trim().isNotEmpty;
    setState(() {
      _isSearchExpanded = true;
      _searchQuery = value;
    });
    if (shouldHideDetails) {
      _hidePointDetails();
    }
  }

  void _submitSearch() {
    if (_searchQuery.trim().isEmpty) {
      _activateSearch();
      return;
    }

    final results = _searchResults;
    if (results.isNotEmpty) {
      _selectSearchResult(results.first);
    }
  }

  void _selectSearchResult(WaterPoint point) {
    _searchController.text = point.name;
    _searchQuery = point.name;
    _isSearchExpanded = true;
    _searchFocusNode.unfocus();
    _showPointDetails(point);
  }

  void _showPointDetails(WaterPoint point) {
    _detailHideTimer?.cancel();
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

    _detailHideTimer?.cancel();
    _detailHideTimer = Timer(_detailFadeDuration, () {
      _detailHideTimer = null;
      if (!mounted || _isDetailVisible) {
        return;
      }

      setState(() => _detailPoint = null);
    });
  }

  bool _matchesWaterPoint(WaterPoint point, String rawQuery) {
    final tokens = rawQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().isNotEmpty)
        .map(_normalizeSearchText)
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return true;
    }

    final searchableFields = [
      point.name,
      point.regionCode,
      point.specificLocation,
      point.status.label,
      if (!point.hasTestData) 'public drink drinking fountain no data',
    ].map(_normalizeSearchText).toList(growable: false);

    return tokens.every(
      (token) => searchableFields.any(
        (field) => field.contains(token) || _isSubsequence(token, field),
      ),
    );
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  bool _isSubsequence(String needle, String haystack) {
    if (needle.isEmpty) {
      return true;
    }

    var needleIndex = 0;
    for (final codeUnit in haystack.codeUnits) {
      if (codeUnit == needle.codeUnitAt(needleIndex)) {
        needleIndex++;
        if (needleIndex == needle.length) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            ResponsiveLayout.horizontalPadding(constraints.maxWidth);
        final visibleWaterPoints = _visibleWaterPoints;
        final searchResults = _searchResults;

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
                      for (final point in visibleWaterPoints)
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
              child: MapSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                active: _isSearchActive,
                onActivate: _activateSearch,
                onChanged: _updateSearchQuery,
                onSearch: _submitSearch,
              ),
            ),
            if (_isSearchActive && _searchQuery.trim().isNotEmpty)
              Positioned(
                left: horizontalPadding,
                right: horizontalPadding,
                top: 112,
                child: _MapSearchResultsPanel(
                  results: searchResults,
                  onSelected: _selectSearchResult,
                ),
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

class _MapSearchResultsPanel extends StatelessWidget {
  const _MapSearchResultsPanel({
    required this.results,
    required this.onSelected,
  });

  final List<WaterPoint> results;
  final ValueChanged<WaterPoint> onSelected;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      blurSigma: 12,
      color: AppColors.controlFill,
      boxShadow: AppShadows.dropdownMenu,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'No drinking points found',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final point in results)
                  _MapSearchResultTile(
                    point: point,
                    onTap: () => onSelected(point),
                  ),
              ],
            ),
    );
  }
}

class _MapSearchResultTile extends StatelessWidget {
  const _MapSearchResultTile({
    required this.point,
    required this.onTap,
  });

  final WaterPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Select ${point.name}',
      child: GestureDetector(
        key: ValueKey('map-search-result-${point.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              _WaterPointGlyph(
                size: 22,
                color: point.markerColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyBold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      point.specificLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                point.hasTestData ? '${point.score}' : 'No data',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: point.markerColor,
                ),
              ),
            ],
          ),
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
    required this.hasTestData,
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

  const WaterPoint.possiblePublicDrink({
    required this.id,
    required this.name,
    required this.regionCode,
    required this.specificLocation,
    required this.point,
  })  : hasTestData = false,
        score = 0,
        tds = 0,
        ph = 0,
        temperatureCelsius = 0,
        cr6MgPerL = 0,
        status = WaterStatus.untested,
        drinkingAdvice =
            'Possible public drinking point. Test before drinking.',
        lastTested = 'No test data',
        reports = const [];

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
      hasTestData: true,
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
  final bool hasTestData;
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

  Color get markerColor => status.markerColor;
}

enum WaterStatus {
  safe('Safe', AppColors.waterQualitySafe),
  uncertain('Uncertain', AppColors.waterQualityCaution),
  unsafe('Unsafe', AppColors.waterQualityUnsafe),
  untested('No data', AppColors.textMuted);

  const WaterStatus(this.label, this.color);

  final String label;
  final Color color;

  Color get markerColor => switch (this) {
        WaterStatus.safe => const Color(0xFF6EDB1A),
        WaterStatus.uncertain => AppColors.waterQualityCaution,
        WaterStatus.unsafe => AppColors.waterQualityUnsafe,
        WaterStatus.untested => AppColors.textMuted,
      };

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
        WaterStatus.untested =>
          'Possible public drinking point. Test before drinking.',
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        selected: selected,
        child: Center(
          child: AnimatedContainer(
            duration: _MapPageState._detailFadeDuration,
            width: 44,
            height: 44,
            child: _WaterPointGlyph(
              size: 44,
              color: point.markerColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterPointGlyph extends StatelessWidget {
  const _WaterPointGlyph({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconWidth = size * 18 / 44;
    final iconHeight = size * 24 / 44;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: SvgPicture.asset(
            'assets/figma/water_point.svg',
            width: iconWidth,
            height: iconHeight,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
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
    final gradientColors = point.hasTestData
        ? const [
            Color(0xFF6DA66A),
            Color(0xFF244D3F),
          ]
        : const [
            Color(0xFFB8BDB6),
            Color(0xFF59615C),
          ];

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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
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
            Positioned(
              left: 12,
              top: 8,
              child: _WaterPointGlyph(
                size: 22,
                color: AppColors.white.withValues(alpha: 0.5),
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
    if (!point.hasTestData) {
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
              _NoDataBadge(label: point.status.label),
              const SizedBox(height: 8),
              Text(
                point.drinkingAdvice,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

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

class _NoDataBadge extends StatelessWidget {
  const _NoDataBadge({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
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
