import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/app_spacing.dart';
import '../widgets/metric_cards.dart';
import '../widgets/pebble_top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardContainerWidth = math.min(367.0, constraints.maxWidth);
        final cardWidth = (cardContainerWidth - 9) / 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.pageTop,
            AppSpacing.pageHorizontal,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PebbleTopBar(showDate: true),
              const SizedBox(height: AppSpacing.section),
              Text('My Health Test', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.section),
              Align(
                child: SizedBox(
                  width: cardContainerWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: 204,
                        child: AverageTestsCard(snapshot: snapshot),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: cardWidth,
                        height: 233,
                        child: DeviceStatusCard(snapshot: snapshot),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: SizedBox(
                  width: cardContainerWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: 189,
                        child: TestLifeCard(snapshot: snapshot),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: cardWidth,
                        height: 193,
                        child: WaterQualityCard(snapshot: snapshot),
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
  }
}
