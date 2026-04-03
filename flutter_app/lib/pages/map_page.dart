import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/design_tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';

class MapPage extends StatelessWidget {
  const MapPage({
    super.key,
    required this.snapshot,
  });

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = math.min(262.0, width * 0.62);

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/map-background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 60,
              left: 30,
              right: 30,
              child: Row(
                children: [
                  Expanded(child: const _SearchBar()),
                  const SizedBox(width: 10),
                  const _PreviewBubble(),
                ],
              ),
            ),
            Positioned(
              left: width * 0.10,
              top: height * 0.46,
              child: const _MapPin(size: 64, selected: true),
            ),
            Positioned(
              left: width * 0.62,
              top: height * 0.20,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.45,
              top: height * 0.28,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.72,
              top: height * 0.31,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.08,
              top: height * 0.37,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.21,
              top: height * 0.64,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.58,
              top: height * 0.58,
              child: const _MapPin(size: 24),
            ),
            Positioned(
              left: width * 0.35,
              top: height * 0.30,
              child: SizedBox(
                width: cardWidth,
                child: _PlaceCard(snapshot: snapshot),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.snapshot});

  final AppSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blurSigma: 18,
      boxShadow: AppShadows.mapCard,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 64,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.card),
                topRight: Radius.circular(AppRadii.card),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/map-place.jpg',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.locationName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          snapshot.locationShort.replaceAll(' ', ''),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Place is better to drink after filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blackText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Last time: ${snapshot.lastCheckedLabel}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.blackText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ProgressRing(
                  value: snapshot.waterQualityScore / 100,
                  size: 70,
                  strokeWidth: 8,
                  child: Text(
                    '${snapshot.waterQualityScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blurSigma: 12,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.search)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFF4D84C),
                  Color(0xFF76D61E),
                  Color(0xFF38D4DE),
                  Color(0xFFF06D4E),
                  Color(0xFFF4D84C),
                ],
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4DA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.blackText,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Search place',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8F8F8F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  const _PreviewBubble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.card,
      ),
      child: CircleAvatar(
        radius: 21,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            'assets/map-place.jpg',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.size,
    this.selected = false,
  });

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: size,
            color: AppColors.lime,
          ),
          if (selected)
            Positioned(
              top: size * 0.18,
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
