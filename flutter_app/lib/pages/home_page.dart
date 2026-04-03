import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/design_tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(30, 60, 30, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _MenuButton(),
              Spacer(),
              _DateChip(),
              Spacer(),
              _UserBadge(),
            ],
          ),
          const SizedBox(height: 25),
          Text('My Health Test', style: textTheme.headlineSmall),
          const SizedBox(height: 25),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = (constraints.maxWidth - 10) / 2;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: Column(
                      children: [
                        _AverageTestCard(snapshot: snapshot),
                        const SizedBox(height: 11),
                        _TestLifeCard(snapshot: snapshot),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: columnWidth,
                    child: Column(
                      children: [
                        _DeviceCard(snapshot: snapshot),
                        const SizedBox(height: 11),
                        _WaterQualityCard(snapshot: snapshot),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AverageTestCard extends StatelessWidget {
  const _AverageTestCard({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 178,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avg test Number',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'in 1 month',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 10, color: AppColors.blackText),
                    ),
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          text: '${snapshot.averageTestScore}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blackText,
                          ),
                          children: [
                            TextSpan(
                              text: '/${snapshot.monthlyGoal}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _MiniBarChart(values: snapshot.chartValues),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 201,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  'Your’s',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const Icon(
                  Icons.battery_6_bar_outlined,
                  size: 20,
                  color: AppColors.blackText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${snapshot.batteryLevel}%',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: Image.asset(
                'assets/home-device.png',
                height: 110,
                width: 134,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _ConnectionDot(),
                SizedBox(width: 15),
                Text(
                  'Test Kit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Connected',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestLifeCard extends StatelessWidget {
  const _TestLifeCard({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  size: 18,
                  color: AppColors.blackText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Test Life',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressRing(
                    value: snapshot.testLife / 100,
                    size: 84,
                    child: Text.rich(
                      TextSpan(
                        text: '${snapshot.testLife}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackText,
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
                  const SizedBox(height: 12),
                  const Text(
                    'Utilization',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackText,
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

class _WaterQualityCard extends StatelessWidget {
  const _WaterQualityCard({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 172,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: AppColors.blackText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Water Quality',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 6,
              children: [
                _DropdownPill(label: snapshot.locationName),
                _DropdownPill(label: snapshot.locationShort),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ProgressRing(
                value: snapshot.waterQualityScore / 100,
                size: 78,
                child: Text.rich(
                  TextSpan(
                    text: '${snapshot.waterQualityScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackText,
                    ),
                    children: const [
                      TextSpan(
                        text: '/100',
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

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              SizedBox(
                height: 72,
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
                              color: AppColors.secondaryText,
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 6,
                          height: height * 0.78,
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? AppColors.secondaryText
                                : AppColors.blackText,
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
    );
  }
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.dropdown,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.expand_more_rounded,
              size: 10,
              color: AppColors.blackText,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: AppColors.blackText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.menu_rounded,
      size: 29,
      color: AppColors.blackText,
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.card,
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.blackText,
            ),
            SizedBox(width: 5),
            Text(
              'Jun 10, 2024',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.blackText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'YT',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.blackText,
        ),
      ),
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
        color: Color(0xFF27E48B),
        shape: BoxShape.circle,
      ),
    );
  }
}
