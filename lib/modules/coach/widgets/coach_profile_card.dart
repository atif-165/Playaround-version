import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/coach_profile.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Card widget for displaying coach profile information with vibrant styling.
class CoachProfileCard extends StatelessWidget {
  final CoachProfile coach;
  final VoidCallback onTap;
  final bool showFullBio;

  const CoachProfileCard({
    super.key,
    required this.coach,
    required this.onTap,
    this.showFullBio = false,
  });

  Color get _accentColor {
    if (coach.specializationSports.isEmpty) {
      return ColorsManager.primary;
    }

    final seed = coach.specializationSports.first.codeUnitAt(0);
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D1FF),
      const Color(0xFFFF6CAB),
      const Color(0xFFFFAA4C),
      const Color(0xFF4ADE80),
    ];
    return colors[seed % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.18),
                const Color(0xFF0D0A2A),
              ],
            ),
            border: Border.all(
              color: accent.withOpacity(0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accent),
                Gap(16.h),
                _buildBioSection(),
                Gap(16.h),
                _buildSpecializations(accent),
                Gap(16.h),
                _buildFooter(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(accent),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      coach.fullName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildCoachBadge(accent),
                ],
              ),
              Gap(6.h),
              _buildRatingRow(),
              Gap(6.h),
              _buildQuickStats(accent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachBadge(Color accent) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            accent,
            accent.withOpacity(0.6),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: 14.sp,
          ),
          Gap(4.w),
          Text(
            'COACH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color accent) {
    final borderGradient = LinearGradient(
      colors: [
        accent,
        accent.withOpacity(0.4),
      ],
    );

    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderGradient,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(3.w),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: coach.profilePictureUrl ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFF1F1B44),
            child: Icon(
              Icons.person,
              color: Colors.white.withOpacity(0.6),
              size: 32.sp,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF1F1B44),
            child: Icon(
              Icons.person,
              color: Colors.white.withOpacity(0.6),
              size: 32.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    const rating = 4.7;
    const reviews = 32;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFF18143A),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 16.sp,
                color: const Color(0xFFFFD76F),
              ),
              Gap(4.w),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        Gap(8.w),
        Text(
          '$reviews reviews',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Color accent) {
    final sessions = max(coach.experienceYears * 30, 40);
    return Wrap(
      spacing: 10.w,
      runSpacing: 8.h,
      children: [
        _StatChip(
          icon: Icons.work_outline_rounded,
          label: '${coach.experienceYears} yrs experience',
          accent: accent,
        ),
        _StatChip(
          icon: Icons.school_rounded,
          label:
              '${coach.certifications?.length ?? 2}+ certifications',
          accent: accent,
        ),
        _StatChip(
          icon: Icons.timeline_rounded,
          label: '$sessions sessions',
          accent: accent,
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    final copy = coach.bio?.isNotEmpty == true
        ? coach.bio!
        : 'Elite ${coach.specializationSports.firstOrNull ?? 'sports'} coach helping athletes unlock peak performance with custom programs and weekly progress insights.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coaching Philosophy',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        Gap(6.h),
        Text(
          copy,
          style: TextStyle(
            fontSize: 13.sp,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.88),
          ),
          maxLines: showFullBio ? null : 3,
          overflow:
              showFullBio ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSpecializations(Color accent) {
    if (coach.specializationSports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature Programs',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            letterSpacing: 0.2,
          ),
        ),
        Gap(10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: coach.specializationSports.take(4).map((sport) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: accent.withOpacity(0.12),
                border: Border.all(
                  color: accent.withOpacity(0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: accent,
                    size: 14.sp,
                  ),
                  Gap(6.w),
                  Text(
                    sport,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter(Color accent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${coach.hourlyRate.toStringAsFixed(0)}/session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(4.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  Gap(4.w),
                  Expanded(
                    child: Text(
                      coach.location,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Gap(16.w),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent,
                accent.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(18.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
              Gap(6.w),
              Text(
                'View Profile',
                style: TextStyles.font12White600Weight.copyWith(
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: accent,
            size: 14.sp,
          ),
          Gap(6.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
