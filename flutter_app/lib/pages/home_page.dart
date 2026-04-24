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
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - AppSpacing.pageHorizontal * 2,
        );
        final cardContainerWidth = availableWidth;
        const cardGap = 9.0;
        final cardWidth = math.max(0.0, (cardContainerWidth - cardGap) / 2);
        final compactHeightExtra = math.max(0.0, 180 - cardWidth) * 0.7;

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
                        child: Column(
                          children: [
                            SizedBox(
                              height: 204,
                              child: AverageTestsCard(snapshot: snapshot),
                            ),
                            const SizedBox(height: cardGap),
                            SizedBox(
                              height: 196 + compactHeightExtra,
                              child: TestLifeCard(snapshot: snapshot),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: cardGap),
                      SizedBox(
                        width: cardWidth,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 233,
                              child: DeviceStatusCard(snapshot: snapshot),
                            ),
                            const SizedBox(height: cardGap),
                            SizedBox(
                              height: 196 + compactHeightExtra,
                              child: WaterQualityCard(snapshot: snapshot),
                            ),
                          ],
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
  }
}
