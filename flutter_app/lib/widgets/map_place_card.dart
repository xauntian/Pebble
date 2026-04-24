import 'package:flutter/material.dart';

import '../models/app_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'pebble_glass_card.dart';
import 'progress_ring.dart';

class MapPlaceCard extends StatelessWidget {
  const MapPlaceCard({
    super.key,
    required this.snapshot,
    this.scale = 1,
  });

  final AppSnapshot snapshot;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return PebbleGlassCard(
      blurSigma: 46.25 * scale,
      boxShadow: AppShadows.mapCard,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 58 * scale,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card * scale),
                topRight: Radius.circular(AppRadius.card * scale),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6DA66A), Color(0xFF244D3F)],
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 24,
                    top: -20,
                    child: Icon(
                      Icons.park_rounded,
                      size: 84,
                      color: Color(0x33FFFFFF),
                    ),
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
                    padding: EdgeInsets.all(AppSpacing.md * scale),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        Text(
                          snapshot.locationShort.replaceAll(' ', ''),
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
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
            padding: EdgeInsets.fromLTRB(
              10 * scale,
              8 * scale,
              10 * scale,
              8 * scale,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Place is better to drink after filter',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 14 * scale),
                      Text(
                        'Last time: ${snapshot.lastCheckedLabel}',
                        style: TextStyle(
                          fontSize: 10 * scale,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12 * scale),
                ProgressRing(
                  value: snapshot.waterQualityScore / 100,
                  size: 62 * scale,
                  strokeWidth: 7 * scale,
                  child: Text(
                    '${snapshot.waterQualityScore}',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
