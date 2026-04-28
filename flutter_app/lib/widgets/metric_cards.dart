import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_snapshot.dart';
import '../models/device_connection.dart';
import '../models/water_test_report.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pill_chip.dart';
import 'pebble_glass_card.dart';
import 'progress_ring.dart';

class AverageTestsCard extends StatelessWidget {
  const AverageTestsCard({
    super.key,
    required this.data,
  });

  final AverageTestsCardData data;

  @override
  Widget build(BuildContext context) {
    return _MetricCardFrame(
      child: SizedBox(
        height: 230,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avg test Number',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            text: 'in 1 month ',
                            style: AppTextStyles.metricPrefix,
                            children: [
                              TextSpan(
                                text: '${data.averageTestScore}',
                                style: AppTextStyles.metricValue,
                              ),
                              TextSpan(
                                text: '/ ${data.monthlyGoal}',
                                style: AppTextStyles.metricSuffix,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _MiniBarChart(
                          values: data.chartValues,
                          labels: data.chartLabels,
                          highlightIndex: data.highlightIndex,
                          highlightLabel: data.highlightLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AverageTestsCardData {
  const AverageTestsCardData({
    required this.averageTestScore,
    required this.monthlyGoal,
    required this.chartValues,
    required this.chartLabels,
    this.highlightIndex,
    this.highlightLabel,
  });

  factory AverageTestsCardData.fromSnapshot(AppSnapshot snapshot) {
    final chartValues = List<double>.unmodifiable(snapshot.chartValues);
    final chartLabels =
        List<String>.unmodifiable(List.filled(chartValues.length, ''));
    final highlightIndex = chartValues.isEmpty ? null : chartValues.length - 1;

    return AverageTestsCardData(
      averageTestScore: snapshot.averageTestScore,
      monthlyGoal: snapshot.monthlyGoal,
      chartValues: chartValues,
      chartLabels: chartLabels,
      highlightIndex: highlightIndex,
      highlightLabel: highlightIndex == null
          ? null
          : chartValues[highlightIndex].round().toString(),
    );
  }

  factory AverageTestsCardData.fromScores({
    required List<num> recentScores,
    required int monthlyGoal,
    List<String> labels = const [],
  }) {
    final scores = List<double>.unmodifiable(
      recentScores.map((score) => score.toDouble()),
    );
    final chartLabels = List<String>.unmodifiable(
      List.generate(
        scores.length,
        (index) => index < labels.length ? labels[index] : '',
      ),
    );
    final average = scores.isEmpty
        ? 0
        : (scores.reduce((total, score) => total + score) / scores.length)
            .round();
    final highlightIndex = scores.isEmpty ? null : scores.length - 1;

    return AverageTestsCardData(
      averageTestScore: average,
      monthlyGoal: monthlyGoal,
      chartValues: scores,
      chartLabels: chartLabels,
      highlightIndex: highlightIndex,
      highlightLabel: highlightIndex == null
          ? null
          : scores[highlightIndex].round().toString(),
    );
  }

  factory AverageTestsCardData.fromReports({
    required List<WaterTestReport> reports,
    required int monthlyGoal,
  }) {
    final sortedReports = [...reports]
      ..sort((a, b) => a.testedAt.compareTo(b.testedAt));

    return AverageTestsCardData.fromScores(
      recentScores: sortedReports.map((report) => report.score).toList(),
      monthlyGoal: monthlyGoal,
      labels: sortedReports.map(_shortReportDateLabel).toList(),
    );
  }

  static String _shortReportDateLabel(WaterTestReport report) {
    return report.testedAtLabel.split(',').first;
  }

  final int averageTestScore;
  final int monthlyGoal;
  final List<double> chartValues;
  final List<String> chartLabels;
  final int? highlightIndex;
  final String? highlightLabel;
}

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({
    super.key,
    required this.data,
    this.onConnect,
  });

  final DeviceStatusCardData data;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final card = _DeviceCardFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.min(
            149.0,
            constraints.maxWidth.isFinite ? constraints.maxWidth : 149.0,
          );

          return Center(
            child: SizedBox(
              width: contentWidth,
              height: 188,
              child: Column(
                children: [
                  SizedBox(
                    height: 21,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            "Your’s",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/figma/device-card-battery.svg',
                              width: 21,
                              height: 21,
                            ),
                            const SizedBox(width: 5),
                            SizedBox(
                              width: 26,
                              height: 10,
                              child: Text(
                                data.batteryLabel,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.batteryLabel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: contentWidth,
                    height: 167,
                    child: Column(
                      children: [
                        _DeviceConnectionVisual(
                          isConnected: data.isConnected,
                          width: contentWidth,
                        ),
                        Expanded(
                          child: data.isConnected
                              ? _ConnectedDeviceInfo(data: data)
                              : _UnconnectedDeviceInfo(data: data),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (onConnect == null || data.isConnected) {
      return card;
    }

    return Semantics(
      button: true,
      enabled: !data.isConnecting,
      label: data.isConnecting
          ? 'Connecting Pebble device'
          : 'Connect Pebble device',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: data.isConnecting ? null : onConnect,
        child: card,
      ),
    );
  }
}

class _DeviceCardFrame extends StatelessWidget {
  const _DeviceCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      padding: const EdgeInsets.all(15),
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A4C7C09),
          blurRadius: 10,
          offset: Offset.zero,
        ),
      ],
      border: Border.all(color: Colors.transparent, width: 0),
      child: child,
    );
  }
}

class _ConnectedDeviceInfo extends StatelessWidget {
  const _ConnectedDeviceInfo({required this.data});

  final DeviceStatusCardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ConnectionDot(color: data.connectionDotColor),
            const SizedBox(width: 15),
            Flexible(
              child: Text(
                data.deviceName,
                style: AppTextStyles.deviceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          data.statusLabel,
          style: AppTextStyles.statusLabel,
        ),
      ],
    );
  }
}

class _UnconnectedDeviceInfo extends StatelessWidget {
  const _UnconnectedDeviceInfo({required this.data});

  final DeviceStatusCardData data;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Text(
        data.statusLabel,
        style: AppTextStyles.deviceLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class DeviceStatusCardData {
  const DeviceStatusCardData({
    required this.isConnected,
    this.isConnecting = false,
    this.batteryPercent,
    this.deviceName = 'Test Kit',
    this.productAssetPath,
  });

  factory DeviceStatusCardData.fromConnection(
    DeviceConnection connection, {
    bool isConnecting = false,
  }) {
    return DeviceStatusCardData(
      isConnected: connection.isConnected,
      isConnecting: !connection.isConnected && isConnecting,
      batteryPercent: connection.isConnected ? connection.batteryPercent : null,
      deviceName: connection.deviceName,
      productAssetPath:
          connection.isConnected ? connection.productAssetPath : null,
    );
  }

  factory DeviceStatusCardData.fromSnapshot(AppSnapshot snapshot) {
    final batteryPercent = int.tryParse(
      snapshot.battery_number.replaceAll('%', '').trim(),
    );

    return DeviceStatusCardData(
      isConnected: snapshot.deviceConnected,
      batteryPercent: snapshot.deviceConnected ? batteryPercent : null,
    );
  }

  final bool isConnected;
  final bool isConnecting;
  final int? batteryPercent;
  final String deviceName;
  final String? productAssetPath;

  String get statusLabel {
    if (isConnecting) {
      return 'Connecting';
    }

    return isConnected ? 'Connected' : 'Unconnected';
  }

  String get batteryLabel {
    if (!isConnected || batteryPercent == null) {
      return '-';
    }

    return '$batteryPercent%';
  }

  Color get connectionDotColor =>
      isConnected ? AppColors.success : AppColors.textMuted;
}

class _DeviceConnectionVisual extends StatelessWidget {
  const _DeviceConnectionVisual({
    required this.isConnected,
    required this.width,
  });

  final bool isConnected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final assetPath = isConnected
        ? 'assets/figma/device-card-connected.png'
        : 'assets/figma/device-card-unconnected.png';
    const height = 118.0;

    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        assetPath,
        key: ValueKey(
          isConnected ? 'device-connected-image' : 'device-unconnected-image',
        ),
        fit: BoxFit.contain,
      ),
    );
  }
}

class TestLifeCard extends StatelessWidget {
  const TestLifeCard({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    const testLifePercent = 89;
    final testLifeProgress = testLifePercent / 100.0;

    return _MetricCardFrame(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 159),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Test Life',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 149,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProgressRing(
                        value: testLifeProgress,
                        size: 92,
                        child: Text.rich(
                          TextSpan(
                            text: '$testLifePercent',
                            style: AppTextStyles.metricValue,
                            children: const [
                              TextSpan(
                                text: '%',
                                style: AppTextStyles.metricPercentSuffix,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Utilization',
                        style: AppTextStyles.sectionLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef WaterQualityCardOpenCallback = void Function(
  WaterQualityCardSelection selection,
);

class WaterQualityCardSelection {
  const WaterQualityCardSelection({
    required this.location,
    required this.regionCode,
  });

  final WaterQualityLocationOption location;
  final String regionCode;
}

class WaterQualityCard extends StatefulWidget {
  const WaterQualityCard({
    super.key,
    required this.data,
    this.onOpen,
  });

  final WaterQualityCardData data;
  final WaterQualityCardOpenCallback? onOpen;

  @override
  State<WaterQualityCard> createState() => _WaterQualityCardState();
}

class _WaterQualityCardState extends State<WaterQualityCard> {
  late WaterQualityLocationOption _selectedLocation;
  late String _selectedRegion;

  @override
  void initState() {
    super.initState();
    _setInitialSelection();
  }

  @override
  void didUpdateWidget(covariant WaterQualityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.locations != widget.data.locations) {
      _setInitialSelection();
    }
  }

  void _setInitialSelection() {
    _selectedLocation = widget.data.latestLocation;
    _selectedRegion = _selectedLocation.regionCode;
  }

  @override
  Widget build(BuildContext context) {
    final regionLocations = widget.data.locations
        .where((location) => location.regionCode == _selectedRegion)
        .toList(growable: false);
    final locationItems =
        regionLocations.isEmpty ? widget.data.locations : regionLocations;
    if (!locationItems.contains(_selectedLocation)) {
      _selectedLocation = locationItems.first;
    }

    final waterQualityPercent = _selectedLocation.score.clamp(0, 100).toInt();
    final waterQualityProgress = waterQualityPercent / 100.0;

    final card = _MetricCardFrame(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 163),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Water Quality',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const _HeaderChevron(),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 149,
                child: Row(
                  children: [
                    Expanded(
                      child: FigmaPillDropdown<WaterQualityLocationOption>(
                        value: _selectedLocation,
                        items: locationItems,
                        labelFor: (location) => location.name,
                        onSelected: (location) {
                          setState(() {
                            _selectedLocation = location;
                            _selectedRegion = location.regionCode;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: FigmaPillDropdown<String>(
                        value: _selectedRegion,
                        items: widget.data.regionCodes,
                        labelFor: (region) => region,
                        onSelected: (region) {
                          setState(() {
                            _selectedRegion = region;
                            _selectedLocation =
                                widget.data.locations.firstWhere(
                              (location) => location.regionCode == region,
                              orElse: () => _selectedLocation,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ProgressRing(
                value: waterQualityProgress,
                size: 92,
                child: Text.rich(
                  TextSpan(
                    text: '$waterQualityPercent',
                    style: AppTextStyles.metricValue,
                    children: const [
                      TextSpan(
                        text: '/ 100',
                        style: AppTextStyles.metricSuffix,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onOpen == null) {
      return card;
    }

    return Semantics(
      button: true,
      label: 'Open water quality',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onOpen!(
            WaterQualityCardSelection(
              location: _selectedLocation,
              regionCode: _selectedRegion,
            ),
          );
        },
        child: card,
      ),
    );
  }
}

class WaterQualityCardData {
  const WaterQualityCardData({
    required this.locations,
    required this.latestLocationId,
  });

  factory WaterQualityCardData.fromReports(List<WaterTestReport> reports) {
    final latestReports = <String, WaterTestReport>{};
    WaterTestReport? latestReport;

    for (final report in reports) {
      final current = latestReports[report.locationId];
      if (current == null || report.testedAt.isAfter(current.testedAt)) {
        latestReports[report.locationId] = report;
      }
      if (latestReport == null ||
          report.testedAt.isAfter(latestReport.testedAt)) {
        latestReport = report;
      }
    }

    final locations = latestReports.values.map((report) {
      return WaterQualityLocationOption(
        id: report.locationId,
        name: report.locationName,
        regionCode: report.regionCode,
        score: report.score,
      );
    }).toList(growable: false)
      ..sort((a, b) {
        final regionCompare = _regionSortOrder(a.regionCode)
            .compareTo(_regionSortOrder(b.regionCode));
        if (regionCompare != 0) {
          return regionCompare;
        }

        final regionNameCompare = a.regionCode.compareTo(b.regionCode);
        if (regionNameCompare != 0) {
          return regionNameCompare;
        }

        return a.name.compareTo(b.name);
      });

    return WaterQualityCardData(
      locations: List.unmodifiable(locations),
      latestLocationId: latestReport?.locationId ?? locations.first.id,
    );
  }

  static int _regionSortOrder(String regionCode) =>
      regionCode == 'SF, CA' ? 0 : 1;

  final List<WaterQualityLocationOption> locations;
  final String latestLocationId;

  WaterQualityLocationOption get latestLocation {
    return locations.firstWhere(
      (location) => location.id == latestLocationId,
      orElse: () => locations.first,
    );
  }

  List<String> get regionCodes {
    return List.unmodifiable(
      locations.map((location) => location.regionCode).toSet(),
    );
  }
}

class WaterQualityLocationOption {
  const WaterQualityLocationOption({
    required this.id,
    required this.name,
    required this.regionCode,
    required this.score,
  });

  final String id;
  final String name;
  final String regionCode;
  final int score;
}

class _HeaderChevron extends StatelessWidget {
  const _HeaderChevron();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 5,
      height: 9,
      child: CustomPaint(
        painter: _HeaderChevronPainter(),
      ),
    );
  }
}

class _HeaderChevronPainter extends CustomPainter {
  const _HeaderChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.12)
      ..lineTo(size.width * 0.78, size.height * 0.5)
      ..lineTo(size.width * 0.22, size.height * 0.88);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeaderChevronPainter oldDelegate) => false;
}

class _MetricCardFrame extends StatelessWidget {
  const _MetricCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.values,
    required this.labels,
    this.highlightIndex,
    this.highlightLabel,
  });

  final List<double> values;
  final List<String> labels;
  final int? highlightIndex;
  final String? highlightLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const axisWidth = 22.0;
        const maxChartHeight = 126.0;
        const maxPlotHeight = 102.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : maxChartHeight;
        final chartHeight = math.min(maxChartHeight, availableHeight);
        final chartPlotHeight = math.min(
          maxPlotHeight,
          math.max(48.0, chartHeight - 24),
        );
        final chartWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 149.0;

        return Align(
          alignment: Alignment.bottomLeft,
          child: SizedBox(
            width: chartWidth,
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: SizedBox(
                    width: axisWidth,
                    height: chartPlotHeight,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('100', style: AppTextStyles.chartLabel),
                        Text('50', style: AppTextStyles.chartLabel),
                        Text('0', style: AppTextStyles.chartLabel),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ResponsiveBarPlot(
                    values: values,
                    labels: labels,
                    highlightIndex: highlightIndex,
                    highlightLabel: highlightLabel,
                    plotHeight: chartPlotHeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResponsiveBarPlot extends StatelessWidget {
  const _ResponsiveBarPlot({
    required this.values,
    required this.labels,
    required this.plotHeight,
    this.highlightIndex,
    this.highlightLabel,
  });

  final List<double> values;
  final List<String> labels;
  final double plotHeight;
  final int? highlightIndex;
  final String? highlightLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const barWidth = 6.0;
        const minBarGap = 7.0;

        final visibleCount = _visibleBarCount(
          availableWidth: constraints.maxWidth,
          barWidth: barWidth,
          minBarGap: minBarGap,
          valueCount: values.length,
        );
        final startIndex = values.length - visibleCount;
        final visibleValues = values.skip(startIndex).toList(growable: false);
        final visibleLabels = labels.skip(startIndex).toList(growable: false);
        final visibleHighlightIndex =
            highlightIndex == null ? null : highlightIndex! - startIndex;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: plotHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(visibleValues.length, (index) {
                  final isHighlighted = visibleHighlightIndex == index;
                  final chartValue =
                      visibleValues[index].clamp(0, 100).toDouble();
                  final label =
                      highlightLabel ?? visibleValues[index].round().toString();

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isHighlighted)
                        Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.dataPoint,
                          ),
                        ),
                      Container(
                        width: barWidth,
                        height: chartValue / 100 * plotHeight,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      visibleLabels.isEmpty ? '' : visibleLabels.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.chartLabel,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visibleLabels.isEmpty ? '' : visibleLabels.last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.chartLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  int _visibleBarCount({
    required double availableWidth,
    required double barWidth,
    required double minBarGap,
    required int valueCount,
  }) {
    if (valueCount == 0) {
      return 0;
    }

    final width = availableWidth.isFinite ? availableWidth : 149.0;
    final fitCount = ((width + minBarGap) / (barWidth + minBarGap)).floor();

    return math.min(valueCount, math.max(1, fitCount));
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
