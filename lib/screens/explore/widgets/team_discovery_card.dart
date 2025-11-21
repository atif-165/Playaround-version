import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../data/models/team_model.dart';
import '../../../theming/colors.dart';

class TeamDiscoveryCard extends StatelessWidget {
  const TeamDiscoveryCard({
    super.key,
    required this.team,
    this.distanceKm,
    required this.onTap,
  });

  final TeamModel team;
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
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(name: team.name),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Gap(4.h),
                        Text(
                          '${team.sport} · ${team.city}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              Gap(12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  Chip(
                    label: Text(
                      team.tags.isNotEmpty ? team.tags.first : 'Open team',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: ColorsManager.mainBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    side: BorderSide.none,
                    backgroundColor:
                        ColorsManager.mainBlue.withValues(alpha: 0.08),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
                  ),
                  Chip(
                    label: Text(
                      'Rating ${team.rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    avatar:
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                    side: BorderSide.none,
                    backgroundColor: Colors.orange.withValues(alpha: 0.12),
                  ),
                  if (distanceKm != null)
                    Chip(
                      label: Text(
                        '${distanceKm!.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      side: BorderSide.none,
                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                    ),
                ],
              ),
              Gap(12.h),
              Row(
                children: [
                  _StatChip(
                    icon: Icons.emoji_events_outlined,
                    label: '${team.wins}W-${team.losses}L',
                    color: ColorsManager.mainBlue,
                  ),
                  Gap(8.w),
                  _StatChip(
                    icon: Icons.groups_outlined,
                    label: '${team.memberIds.length} players',
                    color: Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [
            ColorsManager.mainBlue,
            ColorsManager.mainBlue.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          Gap(4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
