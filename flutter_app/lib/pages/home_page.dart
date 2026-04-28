import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../models/device_connection.dart';
import '../models/water_test_report.dart';
import '../services/pebble_bluetooth_connection_service.dart';
import '../services/water_quality_reports_api.dart';
import '../theme/app_spacing.dart';
import '../theme/responsive_layout.dart';
import '../widgets/metric_cards.dart';
import '../widgets/pebble_top_bar.dart';
import 'water_quality_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<WaterTestReport>> _reportsFuture;
  final PebbleBluetoothConnectionService _deviceConnectionService =
      PebbleBluetoothConnectionService.shared;
  late final StreamSubscription<DeviceConnection> _deviceConnectionSubscription;
  late final StreamSubscription<List<WaterTestReport>> _reportsSubscription;
  DeviceConnection _deviceConnection = const DeviceConnection.unconnected();
  bool _isConnectingDevice = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = WaterQualityReportsApi.shared.fetchReports();
    _reportsSubscription =
        WaterQualityReportsApi.shared.reportsChanged.listen((reports) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reportsFuture = Future<List<WaterTestReport>>.value(reports);
      });
    });
    _deviceConnectionSubscription =
        _deviceConnectionService.watchConnection().listen((connection) {
      if (!mounted) {
        return;
      }

      setState(() {
        _deviceConnection = connection;
        if (connection.isConnected) {
          _isConnectingDevice = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _reportsSubscription.cancel();
    _deviceConnectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<WaterTestReport>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          );
        }

        final reports = snapshot.data!;
        final latestReport = _latestReport(reports);
        final averageTestsData = AverageTestsCardData.fromReports(
          reports: reports,
          monthlyGoal: widget.snapshot.monthlyGoal,
        );
        final waterQualityData = WaterQualityCardData.fromReports(
          reports,
        );

        final deviceStatusData = DeviceStatusCardData.fromConnection(
          _deviceConnection,
          isConnecting: _isConnectingDevice,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                ResponsiveLayout.horizontalPadding(constraints.maxWidth);
            final cardContainerWidth =
                ResponsiveLayout.contentWidth(constraints.maxWidth);
            const cardGap = 9.0;
            final columnCount = _cardColumnCount(cardContainerWidth);
            final cardWidth = math.max(
              0.0,
              (cardContainerWidth - cardGap * (columnCount - 1)) / columnCount,
            );
            final compactHeightExtra = math.max(0.0, 180 - cardWidth) * 0.7;

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
                  PebbleTopBar(
                    showDate: true,
                    dateLabel: latestReport.testedAtLabel,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Text('My Health Test', style: textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.section),
                  Align(
                    child: SizedBox(
                      width: cardContainerWidth,
                      child: _MasonryCardGrid(
                        columnCount: columnCount,
                        cardWidth: cardWidth,
                        spacing: cardGap,
                        items: [
                          _MasonryCardItem(
                            height: 260,
                            child: AverageTestsCard(
                              data: averageTestsData,
                            ),
                          ),
                          _MasonryCardItem(
                            height: 218,
                            child: DeviceStatusCard(
                              data: deviceStatusData,
                              onConnect: _connectPebbleDevice,
                            ),
                          ),
                          _MasonryCardItem(
                            height: 196 + compactHeightExtra,
                            child: TestLifeCard(snapshot: widget.snapshot),
                          ),
                          _MasonryCardItem(
                            height: 196 + compactHeightExtra,
                            child: WaterQualityCard(
                              data: waterQualityData,
                              onOpen: (selection) {
                                _openWaterQualityPage(context, selection);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int _cardColumnCount(double width) {
    const minCardWidth = 170.0;
    const cardGap = 9.0;
    final count = ((width + cardGap) / (minCardWidth + cardGap)).floor();

    return count.clamp(2, 4).toInt();
  }

  WaterTestReport _latestReport(List<WaterTestReport> reports) {
    return reports.reduce(
      (latest, report) =>
          report.testedAt.isAfter(latest.testedAt) ? report : latest,
    );
  }

  Future<void> _connectPebbleDevice() async {
    if (_isConnectingDevice || _deviceConnection.isConnected) {
      return;
    }

    setState(() {
      _isConnectingDevice = true;
    });

    final connection = await _deviceConnectionService.connectToPebble();
    if (!mounted) {
      return;
    }

    setState(() {
      _deviceConnection = connection;
      _isConnectingDevice = false;
    });
  }

  void _openWaterQualityPage(
    BuildContext context,
    WaterQualityCardSelection selection,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: WaterQualityPage.routeName),
        builder: (context) {
          return WaterQualityPage(
            initialLocationId: selection.location.id,
            initialRegionCode: selection.regionCode,
          );
        },
      ),
    );
  }
}

class _MasonryCardGrid extends StatelessWidget {
  const _MasonryCardGrid({
    required this.items,
    required this.columnCount,
    required this.cardWidth,
    required this.spacing,
  });

  final List<_MasonryCardItem> items;
  final int columnCount;
  final double cardWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = List.generate(
      columnCount,
      (_) => <_MasonryCardItem>[],
      growable: false,
    );
    for (var index = 0; index < items.length; index++) {
      columns[index % columnCount].add(items[index]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var columnIndex = 0;
            columnIndex < columns.length;
            columnIndex++) ...[
          if (columnIndex > 0) SizedBox(width: spacing),
          SizedBox(
            width: cardWidth,
            child: Column(
              children: [
                for (var itemIndex = 0;
                    itemIndex < columns[columnIndex].length;
                    itemIndex++) ...[
                  if (itemIndex > 0) SizedBox(height: spacing),
                  SizedBox(
                    width: cardWidth,
                    height: columns[columnIndex][itemIndex].height,
                    child: columns[columnIndex][itemIndex].child,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MasonryCardItem {
  const _MasonryCardItem({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;
}
