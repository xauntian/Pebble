import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'pill_chip.dart';
import 'pebble_glass_card.dart';
import 'progress_ring.dart';

class AverageTestsCard extends StatelessWidget {
  const AverageTestsCard({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _MetricCardFrame(
      child: SizedBox(
        height: 174,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avg test Number',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 149,
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
                                text: '${snapshot.averageTestScore}',
                                style: AppTextStyles.metricValue,
                              ),
                              TextSpan(
                                text: '/ ${snapshot.monthlyGoal}',
                                style: AppTextStyles.metricSuffix,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: _MiniBarChart(values: snapshot.chartValues),
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

class DeviceStatusCard extends StatelessWidget {
  const DeviceStatusCard({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final batteryLabel = snapshot.battery_number.trim().endsWith('%')
        ? snapshot.battery_number.trim()
        : '${snapshot.battery_number.trim()}%';

    return _MetricCardFrame(
      child: SizedBox(
        height: 203,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Your's",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Spacer(),
                SvgPicture.asset(
                  'assets/figma/battery.svg',
                  width: 21,
                  height: 21,
                ),
                const SizedBox(width: 5),
                Text(
                  batteryLabel,
                  style: AppTextStyles.batteryLabel,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipOval(
              child: SizedBox(
                width: 134,
                height: 110,
                child: Image.asset(
                  'assets/figma/home-device.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _ConnectionDot(),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Test Kit',
                    style: AppTextStyles.deviceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Connected',
              style: AppTextStyles.statusLabel,
            ),
          ],
        ),
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

class WaterQualityCard extends StatelessWidget {
  const WaterQualityCard({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final waterQualityPercent =
        snapshot.waterQualityScore.clamp(0, 100).toInt();
    final waterQualityProgress = waterQualityPercent / 100.0;

    return _MetricCardFrame(
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 149,
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownPillChip(label: snapshot.locationName),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: DropdownPillChip(label: snapshot.locationShort),
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
  }
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
  const _MiniBarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.bottomLeft,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: 149,
              height: 86,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text('100', style: AppTextStyles.chartLabel),
                      SizedBox(height: 11),
                      Text('50', style: AppTextStyles.chartLabel),
                      SizedBox(height: 11),
                      Text('0', style: AppTextStyles.chartLabel),
                      SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(values.length, (index) {
                              final isHighlighted = index == 3;
                              final height = values[index];

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
                                      child: const Text(
                                        '99',
                                        style: AppTextStyles.dataPoint,
                                      ),
                                    ),
                                  Container(
                                    width: 6,
                                    height: math.min(height * 0.56, 38),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 12),
                              Text('Mar', style: AppTextStyles.chartLabel),
                              Text('Jun', style: AppTextStyles.chartLabel),
                              SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}
