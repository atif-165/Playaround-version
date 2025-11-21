import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/team_model.dart';

class TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTap;
  final bool showJoinButton;

  const TeamCard({
    super.key,
    required this.team,
    this.onTap,
    this.onJoinTap,
    this.showJoinButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            children: [
              if (team.bannerImageUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: Opacity(
                      opacity: 0.12,
                      child: CachedNetworkImage(
                        imageUrl: team.bannerImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorsManager.primary.withValues(alpha: 0.22),
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(22.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Gap(16.h),
                    if (_hasDescription) ...[
                      _buildDescription(),
                      Gap(14.h),
                    ],
                    if (team.coaches.isNotEmpty) ...[
                      _buildCoachRow(),
                      Gap(14.h),
                    ],
                    _buildSpecializations(),
                    Gap(14.h),
                    _buildTeamStatsRow(),
                    Gap(18.h),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ColorsManager.surfaceVariant.withValues(alpha: 0.85),
          ColorsManager.background.withValues(alpha: 0.95),
        ],
      ),
      borderRadius: BorderRadius.circular(24.r),
      border: Border.all(
        color: ColorsManager.primary.withValues(alpha: 0.25),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.32),
          blurRadius: 26.r,
          offset: Offset(0, 14.h),
        ),
        BoxShadow(
          color: ColorsManager.primary.withValues(alpha: 0.18),
          blurRadius: 18.r,
          offset: Offset(0, 10.h),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Enhanced team avatar
        Container(
          width: 70.w,
          height: 70.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: ColorsManager.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: ColorsManager.primary.withValues(alpha: 0.3),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                color: ColorsManager.background,
              ),
              child: _buildTeamAvatarContent(),
            ),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      team.name,
                      style: TextStyles.font18DarkBlueBold.copyWith(
                        color: ColorsManager.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTeamBadge(),
                ],
              ),
              Gap(6.h),
              _buildSportAndLocationRow(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamAvatarContent() {
    final String? imageUrl = team.teamImageUrl;
    final String initial = _getTeamInitial();

    return imageUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: ColorsManager.primary,
                  strokeWidth: 2.w,
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.groups,
                color: ColorsManager.primary,
                size: 32.sp,
              ),
            ),
          )
        : Icon(
            Icons.groups,
            color: ColorsManager.primary,
            size: 32.sp,
          );
  }

  Widget _buildTeamBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: ColorsManager.primaryGradient,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups,
            color: ColorsManager.onPrimary,
            size: 12.sp,
          ),
          Gap(4.w),
          Text(
            'TEAM',
            style: TextStyle(
              color: ColorsManager.onPrimary,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsRow() {
    final stats = team.stat;

    final chips = <Widget>[
      _buildStatChip(
        icon: Icons.people_alt_rounded,
        value: '${team.activeMembersCount}/${team.maxMembers}',
        label: 'Roster',
        color: ColorsManager.primary,
      ),
      _buildStatChip(
        icon: Icons.emoji_events_rounded,
        value: '${stats['matchesWon'] ?? 0}',
        label: 'Wins',
        color: ColorsManager.success,
      ),
      _buildStatChip(
        icon: Icons.handshake_rounded,
        value: '${stats['matchesDrawn'] ?? 0}',
        label: 'Draws',
        color: ColorsManager.secondary,
      ),
      _buildStatChip(
        icon: Icons.mood_bad_rounded,
        value: '${stats['matchesLost'] ?? 0}',
        label: 'Losses',
        color: Colors.redAccent,
      ),
      _buildStatChip(
        icon: Icons.sports_soccer,
        value: '${stats['matchesPlayed'] ?? 0}',
        label: 'Matches',
        color: ColorsManager.playerAccent,
      ),
    ];

    if ((stats['goalsScored'] ?? 0) > 0) {
      chips.add(
        _buildStatChip(
          icon: Icons.flash_on_rounded,
          value: '${stats['goalsScored']}',
          label: 'Goals',
          color: Colors.amberAccent,
        ),
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: chips,
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          Gap(8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: ColorsManager.onBackground,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: TextStyles.font10Grey400Weight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportAndLocationRow() {
    return Row(
      children: [
        Icon(
          _getSportIcon(team.sportType),
          size: 16.sp,
          color: ColorsManager.primary, // Red color
        ),
        Gap(4.w),
        Text(
          team.sportType.displayName,
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.primary, // Red color
          ),
        ),
        if (_hasCity) ...[
          Gap(8.w),
          Icon(
            Icons.location_on,
            size: 16.sp,
            color: Colors.grey[400],
          ),
          Gap(2.w),
          Expanded(
            child: Text(
              team.location!,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasDescription {
    return (team.description != null && team.description!.trim().isNotEmpty) ||
        (team.bio != null && team.bio!.trim().isNotEmpty);
  }

  bool get _hasCity => team.location != null && team.location!.isNotEmpty;

  Widget _buildDescription() {
    final description = team.description?.trim().isNotEmpty == true
        ? team.description!.trim()
        : (team.bio ?? '').trim();

    if (description.isEmpty) {
      return Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: ColorsManager.textSecondary,
              size: 16.sp,
            ),
            Gap(10.w),
            Expanded(
              child: Text(
                'No description available yet.',
                style: TextStyles.font14Grey400Weight.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: ColorsManager.onBackground.withOpacity(0.9),
          height: 1.5,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCoachRow() {
    final coaches = team.coaches;
    if (coaches.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final coach in coaches.take(3))
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: CircleAvatar(
              radius: 16.r,
              backgroundColor: ColorsManager.coachAccent.withOpacity(0.25),
              backgroundImage: coach.profileImageUrl != null
                  ? CachedNetworkImageProvider(coach.profileImageUrl!)
                  : null,
              child: coach.profileImageUrl == null
                  ? Text(
                      coach.userName.isNotEmpty
                          ? coach.userName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: ColorsManager.coachAccent,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        Expanded(
          child: Text(
            coaches.length == 1
                ? 'Coached by ${coaches.first.userName}'
                : 'Lead staff: ${coaches.first.userName} +${coaches.length - 1} more',
            style: TextStyles.font12Grey400Weight,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getTeamInitial() {
    if (team.name.isEmpty) return 'T';
    return team.name[0].toUpperCase();
  }

  Widget _buildFooter() {
    final updatedAt = _formatTimeAgo(team.updatedAt);
    final hasJoinButton = showJoinButton && onJoinTap != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_score_rounded,
                    color: ColorsManager.textSecondary,
                    size: 16.sp,
                  ),
                  Gap(6.w),
                  Expanded(
                    child: Text(
                      '${team.sportType.displayName} squad',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: ColorsManager.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Gap(4.h),
              Text(
                'Updated $updatedAt',
                style: TextStyles.font10Grey400Weight,
              ),
            ],
          ),
        ),
        Gap(8.w),
        if (hasJoinButton) ...[
          Flexible(
            child: _buildActionButton(
              label: 'Join Team',
              icon: Icons.sports_handball_outlined,
              gradient: ColorsManager.successGradient,
              onPressed: onJoinTap,
            ),
          ),
          Gap(8.w),
        ],
        Flexible(
          child: _buildActionButton(
            label: 'View Team',
            icon: Icons.arrow_forward,
            gradient: ColorsManager.primaryGradient,
            onPressed: onTap,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    VoidCallback? onPressed,
  }) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: ColorsManager.onPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  Gap(6.w),
                  Icon(
                    icon,
                    color: ColorsManager.onPrimary,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecializations() {
    final stats = team.stat;
    final winRate = stats['winPercentage'] is num
        ? (stats['winPercentage'] as num).toStringAsFixed(1)
        : '0';

    final tags = <Widget>[
      _buildHighlightTag(
        icon: Icons.sports,
        label: team.sportType.displayName,
        color: ColorsManager.primary,
      ),
      if (_hasCity)
        _buildHighlightTag(
          icon: Icons.location_on_rounded,
          label: team.location!,
          color: ColorsManager.playerAccent,
        ),
      _buildHighlightTag(
        icon: team.isPublic ? Icons.public : Icons.lock_rounded,
        label: team.isPublic ? 'Public Squad' : 'Invite Only',
        color: team.isPublic ? ColorsManager.success : Colors.orangeAccent,
      ),
      _buildHighlightTag(
        icon: Icons.school_rounded,
        label:
            '${team.coaches.length} coach${team.coaches.length == 1 ? '' : 'es'}',
        color: ColorsManager.coachAccent,
      ),
      _buildHighlightTag(
        icon: Icons.stacked_line_chart_rounded,
        label: '$winRate% win rate',
        color: ColorsManager.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_graph_rounded,
              color: ColorsManager.primary,
              size: 16.sp,
            ),
            Gap(6.w),
            Text(
              'Highlights',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: ColorsManager.onBackground,
              ),
            ),
          ],
        ),
        Gap(10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: tags,
        ),
      ],
    );
  }

  Widget _buildHighlightTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          Gap(6.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ColorsManager.onBackground,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(SportType sportType) {
    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return Icons.sports_soccer;
      case SportType.basketball:
        return Icons.sports_basketball;
      case SportType.cricket:
        return Icons.sports_cricket;
      case SportType.tennis:
        return Icons.sports_tennis;
      case SportType.badminton:
        return Icons.sports_tennis; // Reuse tennis icon
      case SportType.volleyball:
        return Icons.sports_volleyball;
      case SportType.hockey:
        return Icons.sports_hockey;
      case SportType.rugby:
        return Icons.sports_rugby;
      case SportType.baseball:
        return Icons.sports_baseball;
      default:
        return Icons.sports;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }
}
