import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../models/team_match_model.dart';

class TeamMatchCard extends StatelessWidget {
  final TeamMatch match;
  final String teamId;
  final VoidCallback onTap;

  const TeamMatchCard({
    super.key,
    required this.match,
    required this.teamId,
    required this.onTap,
  });

  bool get _isHomeTeam => match.homeTeamId == teamId;
  TeamScore get _ourTeam => _isHomeTeam ? match.homeTeam : match.awayTeam;
  TeamScore get _opponentTeam => _isHomeTeam ? match.awayTeam : match.homeTeam;

  @override
  Widget build(BuildContext context) {
    final matchTypeColor = _getMatchTypeColor(match.matchType);
    final isLive = match.isLive;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          gradient: PublicProfileTheme.panelGradient,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isLive 
                ? Colors.red.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: PublicProfileTheme.defaultShadow(),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match header
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  matchTypeColor.withOpacity(0.25),
                                  matchTypeColor.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: matchTypeColor.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              match.matchType.displayName,
                              style: TextStyle(
                                color: matchTypeColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isLive) ...[
                            Gap(8.w),
                            _buildLiveBadge(),
                          ],
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12.sp,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            Gap(6.w),
                            Text(
                              DateFormat('MMM dd, HH:mm')
                                  .format(match.scheduledTime),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Gap(20.h),

                  // Score section
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTeamInfo(_ourTeam, isHome: _isHomeTeam),
                        ),
                        Gap(16.w),
                        Column(
                          children: [
                            if (match.isUpcoming)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Text(
                                    '${_ourTeam.score} - ${_opponentTeam.score}',
                                    style: TextStyle(
                                      color: isLive 
                                          ? Colors.red 
                                          : Colors.white,
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  if (match.isCompleted && match.result != null) ...[
                                    Gap(8.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getResultColor().withOpacity(0.8),
                                            _getResultColor().withOpacity(0.6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getResultColor().withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _getResultText(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                        Gap(16.w),
                        Expanded(
                          child: _buildTeamInfo(_opponentTeam, isHome: !_isHomeTeam),
                        ),
                      ],
                    ),
                  ),

                  // Venue info
                  if (match.venueName != null) ...[
                    Gap(16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 16.sp,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Gap(10.w),
                          Expanded(
                            child: Text(
                              match.venueName!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(TeamScore team, {required bool isHome}) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: isHome 
                  ? ColorsManager.mainBlue.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: team.teamLogoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child: Image.network(
                    team.teamLogoUrl!,
                    width: 48.w,
                    height: 48.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildTeamIcon(),
                  ),
                )
              : _buildTeamIcon(),
        ),
        Gap(10.h),
        Text(
          team.teamName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (isHome) ...[
          Gap(4.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: 3.h,
            ),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: ColorsManager.mainBlue.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              'Home',
              style: TextStyle(
                color: ColorsManager.mainBlue,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamIcon() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.mainBlue.withOpacity(0.3),
            ColorsManager.mainBlue.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: ColorsManager.mainBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.shield,
        color: ColorsManager.mainBlue,
        size: 28.sp,
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red,
            Colors.red.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Gap(6.w),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchTypeColor(TeamMatchType type) {
    switch (type) {
      case TeamMatchType.tournament:
        return Colors.purple;
      case TeamMatchType.friendly:
        return Colors.green;
      case TeamMatchType.practice:
        return Colors.blue;
      case TeamMatchType.league:
        return Colors.orange;
    }
  }

  Color _getResultColor() {
    if (match.winnerTeamId == teamId) {
      return Colors.green;
    } else if (match.winnerTeamId == null) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getResultText() {
    if (match.winnerTeamId == teamId) {
      return 'W';
    } else if (match.winnerTeamId == null) {
      return 'D';
    } else {
      return 'L';
    }
  }
}
