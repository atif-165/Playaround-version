import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';

class TeamAchievementsScreen extends StatelessWidget {
  TeamAchievementsScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '$teamName Achievements',
          style: TextStyles.font16White600Weight,
        ),
      ),
      body: StreamBuilder<List<TeamAchievement>>(
        stream: _teamService.watchTeamAchievements(teamId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ColorsManager.mainBlue),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              'Failed to load achievements. Please try again later.',
            );
          }

          final achievements = snapshot.data ?? [];
          if (achievements.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemBuilder: (context, index) =>
                _buildAchievementCard(achievements[index]),
            separatorBuilder: (_, __) => Gap(16.h),
            itemCount: achievements.length,
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(TeamAchievement achievement) {
    final achievedAt = DateFormat('MMMM d, yyyy').format(achievement.achievedAt);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: ColorsManager.warning.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: ColorsManager.warning,
                  size: 20.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  achievement.title,
                  style: TextStyles.font16White600Weight,
                ),
              ),
            ],
          ),
          Gap(12.h),
          if (achievement.description.trim().isNotEmpty)
            Text(
              achievement.description,
              style: TextStyles.font13White500Weight
                  .copyWith(color: Colors.white70),
            ),
          Gap(12.h),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Colors.white54, size: 16),
              Gap(6.w),
              Text(
                achievedAt,
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white54),
              ),
            ],
          ),
          if (achievement.type != null && achievement.type!.isNotEmpty) ...[
            Gap(8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.mainBlue.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                achievement.type!.replaceAll('_', ' ').toUpperCase(),
                style: TextStyles.font12White500Weight
                    .copyWith(color: ColorsManager.mainBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 48, color: Colors.white38),
            Gap(16.h),
            Text(
              'No achievements yet',
              style: TextStyles.font16White600Weight,
            ),
            Gap(8.h),
            Text(
              'Add achievements from the team admin panel to showcase them here.',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            Gap(12.h),
            Text(
              'Something went wrong',
              style: TextStyles.font14White600Weight,
            ),
            Gap(6.h),
            Text(
              message,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


