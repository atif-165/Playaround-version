import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/safe_cached_image.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';

/// Widget for displaying a list of tournaments
class TournamentListWidget extends StatelessWidget {
  final List<Tournament> tournaments;
  final Function(Tournament)? onTournamentTap;
  final Function(Tournament)? onRegisterTournament;
  final bool showRegisterButton;
  final bool isLoading;

  const TournamentListWidget({
    super.key,
    required this.tournaments,
    this.onTournamentTap,
    this.onRegisterTournament,
    this.showRegisterButton = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64.sp,
              color: ColorsManager.gray,
            ),
            Gap(16.h),
            Text(
              'No tournaments found',
              style: TextStyles.font16DarkBlue500Weight,
            ),
            Gap(8.h),
            Text(
              showRegisterButton
                  ? 'No tournaments available to register at the moment'
                  : 'You haven\'t registered for any tournaments yet',
              style: TextStyles.font13Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return TournamentCard(
          tournament: tournament,
          onTap: onTournamentTap != null
              ? () => onTournamentTap!(tournament)
              : null,
          onRegister: onRegisterTournament != null
              ? () => onRegisterTournament!(tournament)
              : null,
          showRegisterButton: showRegisterButton,
        );
      },
    );
  }
}

/// Individual tournament card widget
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final bool showRegisterButton;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
    this.onRegister,
    this.showRegisterButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTournamentAvatar(),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: TextStyles.font16DarkBlue600Weight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Gap(4.h),
                          Text(
                            '${tournament.sportType.displayName} • ${tournament.format.displayName}',
                            style: TextStyles.font13Grey400Weight,
                          ),
                        ],
                      ),
                    ),
                    if (showRegisterButton && onRegister != null)
                      _buildRegisterButton(),
                  ],
                ),
                Gap(12.h),
                Text(
                  tournament.description,
                  style: TextStyles.font14Blue400Weight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(12.h),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.people,
                      text:
                          '${tournament.currentTeamsCount}/${tournament.maxTeams}',
                      color: tournament.isFull ? Colors.red : Colors.green,
                    ),
                    Gap(8.w),
                    _buildStatusChip(),
                    Gap(8.w),
                    if (tournament.location != null)
                      _buildInfoChip(
                        icon: Icons.location_on,
                        text: tournament.location!,
                        color: Colors.blue,
                      ),
                  ],
                ),
                Gap(8.h),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: ColorsManager.gray,
                    ),
                    Gap(4.w),
                    Text(
                      'Starts: ${_formatDate(tournament.startDate)}',
                      style: TextStyles.font12DarkBlue400Weight,
                    ),
                    Gap(16.w),
                    Icon(
                      Icons.app_registration,
                      size: 14.sp,
                      color: ColorsManager.gray,
                    ),
                    Gap(4.w),
                    Text(
                      'Registration: ${_formatDate(tournament.registrationEndDate)}',
                      style: TextStyles.font12DarkBlue400Weight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentAvatar() {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: tournament.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SafeCachedImage(
                imageUrl: tournament.imageUrl!,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8.r),
                backgroundColor: ColorsManager.mainBlue.withValues(alpha: 0.05),
                fallbackIcon: Icons.emoji_events,
                fallbackIconColor: ColorsManager.mainBlue,
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.emoji_events,
      color: ColorsManager.mainBlue,
      size: 24.sp,
    );
  }

  Widget _buildRegisterButton() {
    final canRegister = tournament.isRegistrationOpen && !tournament.isFull;

    return SizedBox(
      height: 32.h,
      child: ElevatedButton(
        onPressed: canRegister ? onRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canRegister ? ColorsManager.mainBlue : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Text(
          tournament.isFull
              ? 'Full'
              : tournament.isRegistrationOpen
                  ? 'Register'
                  : 'Closed',
          style: TextStyles.font13White400Weight,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    switch (tournament.status) {
      case TournamentStatus.upcoming:
        color = Colors.blue;
        break;
      case TournamentStatus.registrationOpen:
        color = Colors.green;
        break;
      case TournamentStatus.registrationClosed:
        color = Colors.orange;
        break;
      case TournamentStatus.ongoing:
      case TournamentStatus.running:
      case TournamentStatus.inProgress:
        color = Colors.purple;
        break;
      case TournamentStatus.completed:
        color = Colors.grey;
        break;
      case TournamentStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        tournament.status.displayName,
        style: TextStyles.font12DarkBlue400Weight.copyWith(color: color),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          Gap(4.w),
          Text(
            text,
            style: TextStyles.font12DarkBlue400Weight.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
