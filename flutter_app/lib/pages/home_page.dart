import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/demo_device_connection.dart';
import '../models/app_snapshot.dart';
import '../models/water_test_report.dart';
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
  late final Future<List<WaterTestReport>> _reportsFuture =
      WaterQualityReportsApi.shared.fetchReports();

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
        final deviceStatusData = DeviceStatusCardData.fromConnection(
          DemoDeviceConnection.current,
        );
        final waterQualityData = WaterQualityCardData.fromReports(
          reports,
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
                      child: Wrap(
                        spacing: cardGap,
                        runSpacing: cardGap,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            height: 260,
                            child: AverageTestsCard(data: averageTestsData),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: 233,
                            child: DeviceStatusCard(data: deviceStatusData),
                          ),
                          SizedBox(
                            width: cardWidth,
                            height: 196 + compactHeightExtra,
                            child: TestLifeCard(snapshot: widget.snapshot),
                          ),
                          SizedBox(
                            width: cardWidth,
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
