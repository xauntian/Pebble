import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
            Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(
                  text: 'in 1 month ',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: '${snapshot.averageTestScore}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '/ ${snapshot.monthlyGoal}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(child: _MiniBarChart(values: snapshot.chartValues)),
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
                const Icon(
                  Icons.battery_6_bar_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  batteryLabel,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
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
                  alignment: const Alignment(0.25, 0),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ConnectionDot(),
                SizedBox(width: AppSpacing.lg),
                Text(
                  'Test Kit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Connected',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
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
    return _MetricCardFrame(
      child: SizedBox(
        height: 159,
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressRing(
                    value: snapshot.testLife / 100,
                    size: 80,
                    child: Text.rich(
                      TextSpan(
                        text: '${snapshot.testLife}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        children: const [
                          TextSpan(
                            text: '%',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Utilization',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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

class WaterQualityCard extends StatelessWidget {
  const WaterQualityCard({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return _MetricCardFrame(
      child: SizedBox(
        height: 163,
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
            Row(
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
            const SizedBox(height: 12),
            Center(
              child: ProgressRing(
                value: snapshot.waterQualityScore / 100,
                size: 80,
                child: Text.rich(
                  TextSpan(
                    text: '${snapshot.waterQualityScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    children: const [
                      TextSpan(
                        text: '/ 100',
                        style: TextStyle(fontSize: 10),
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
                      Text('100', style: TextStyle(fontSize: 8)),
                      SizedBox(height: 11),
                      Text('50', style: TextStyle(fontSize: 8)),
                      SizedBox(height: 11),
                      Text('0', style: TextStyle(fontSize: 8)),
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
                                        style: TextStyle(
                                          fontSize: 5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
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
                              Text('Mar', style: TextStyle(fontSize: 8)),
                              Text('Jun', style: TextStyle(fontSize: 8)),
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
