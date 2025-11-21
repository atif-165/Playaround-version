import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../data/models/player_model.dart';
import '../../../services/location_service.dart';
import '../../../theming/colors.dart';

class PlayerDiscoveryCard extends StatelessWidget {
  const PlayerDiscoveryCard({
    super.key,
    required this.player,
    this.distanceKm,
    required this.onTap,
  });

  final PlayerModel player;
  final double? distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              _Avatar(url: player.avatarUrl),
              Gap(16.w),
              Expanded(child: _Info(player: player, distanceKm: distanceKm)),
              const Icon(Icons.chevron_right, color: ColorsManager.mainBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: SizedBox(
        width: 72.w,
        height: 72.w,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
              )
            : Container(
                color: ColorsManager.lightShadeOfGray,
                child: const Icon(Icons.person, color: ColorsManager.gray),
              ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.player, this.distanceKm});

  final PlayerModel player;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final skillAverage = player.skillRatings.isEmpty
        ? player.experienceLevel * 100
        : player.skillRatings.values.reduce((a, b) => a + b) /
            player.skillRatings.length *
            100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                player.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              '${player.age}y',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Gap(4.h),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: ColorsManager.gray),
            Gap(4.w),
            Expanded(
              child: Text(
                player.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (distanceKm != null)
              Text(
                LocationService().formatDistance(distanceKm!),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: ColorsManager.mainBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        Gap(8.h),
        if (player.sports.isNotEmpty)
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: player.sports.take(3).map((sport) {
              return Chip(
                label: Text(
                  sport,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: ColorsManager.mainBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                side: BorderSide.none,
                backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.08),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
              );
            }).toList(),
          ),
        Gap(8.h),
        Row(
          children: [
            _SkillChip(score: skillAverage),
            Gap(8.w),
            if (player.availability.isNotEmpty)
              _AvailabilityChip(count: player.availability.length),
          ],
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? Colors.green
        : score >= 50
            ? Colors.orange
            : Colors.blue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 14.sp, color: color),
          Gap(4.w),
          Text(
            '${score.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '$count slots',
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.green[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
