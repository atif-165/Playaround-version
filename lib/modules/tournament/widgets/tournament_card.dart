import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';

/// Card widget for displaying tournament information
class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Gap(12.h),
              _buildDescription(),
              Gap(12.h),
              _buildDetails(),
              Gap(12.h),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Icon(
            _getSportIcon(),
            color: _getStatusColor(),
            size: 24.sp,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.name,
                style: TextStyles.font16DarkBlueBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(4.h),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14.sp,
                    color: Colors.grey[600],
                  ),
                  Gap(4.w),
                  Expanded(
                    child: Text(
                      tournament.organizerName,
                      style: TextStyles.font12Grey400Weight,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_hasWinner()) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: ColorsManager.success,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 10.sp,
                      color: Colors.white,
                    ),
                    Gap(2.w),
                    Text(
                      'WINNER',
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(4.h),
            ],
            _buildStatusChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        tournament.status.displayName,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      tournament.description,
      style: TextStyles.font14Grey400Weight,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                icon: Icons.sports,
                text: tournament.sportType.displayName,
              ),
            ),
            Expanded(
              child: _buildDetailItem(
                icon: Icons.emoji_events,
                text: tournament.format.displayName,
              ),
            ),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                icon: Icons.calendar_today,
                text: DateFormat('MMM dd, yyyy').format(tournament.startDate),
              ),
            ),
            if (tournament.location != null)
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.location_on,
                  text: tournament.location!,
                ),
              ),
          ],
        ),
        if (tournament.entryFee != null || tournament.winningPrize != null) ...[
          Gap(8.h),
          Row(
            children: [
              if (tournament.entryFee != null)
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.attach_money,
                    text: 'Entry: \$${tournament.entryFee!.toStringAsFixed(0)}',
                    color: ColorsManager.warning,
                  ),
                ),
              if (tournament.winningPrize != null)
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.emoji_events,
                    text: 'Prize: \$${tournament.winningPrize!.toStringAsFixed(0)}',
                    color: ColorsManager.success,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final itemColor = color ?? ColorsManager.mainBlue;

    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: itemColor,
        ),
        Gap(4.w),
        Expanded(
          child: Text(
            text,
            style: TextStyles.font12BlueRegular.copyWith(
              color: itemColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teams: ${tournament.currentTeamsCount}/${tournament.maxTeams}',
                style: TextStyles.font14DarkBlueMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Gap(2.h),
              Text(
                'Registration ends: ${DateFormat('MMM dd').format(tournament.registrationEndDate)}',
                style: TextStyles.font12Grey400Weight,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Gap(8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: _canRegister() ? ColorsManager.mainBlue : Colors.grey,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            _getActionText(),
            style: TextStyles.font12WhiteMedium,
          ),
        ),
      ],
    );
  }

  IconData _getSportIcon() {
    // Convert team SportType to listing SportType for icon display
    final sportName = tournament.sportType.displayName;
    if (sportName.contains('Cricket')) return Icons.sports_cricket;
    if (sportName.contains('Football')) return Icons.sports_soccer;
    if (sportName.contains('Basketball')) return Icons.sports_basketball;
    if (sportName.contains('Tennis')) return Icons.sports_tennis;
    if (sportName.contains('Badminton')) return Icons.sports_tennis;
    if (sportName.contains('Volleyball')) return Icons.sports_volleyball;
    if (sportName.contains('Swimming')) return Icons.pool;
    if (sportName.contains('Running')) return Icons.directions_run;
    if (sportName.contains('Cycling')) return Icons.directions_bike;
    return Icons.sports; // Default for other sports
  }

  Color _getStatusColor() {
    switch (tournament.status) {
      case TournamentStatus.upcoming:
        return Colors.blue;
      case TournamentStatus.registrationOpen:
        return Colors.green;
      case TournamentStatus.registrationClosed:
        return Colors.orange;
      case TournamentStatus.ongoing:
        return Colors.purple;
      case TournamentStatus.inProgress:
        return Colors.purple;
      case TournamentStatus.completed:
        return Colors.grey;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  bool _canRegister() {
    return tournament.status == TournamentStatus.registrationOpen &&
           tournament.currentTeamsCount < tournament.maxTeams &&
           tournament.registrationEndDate.isAfter(DateTime.now());
  }

  String _getActionText() {
    if (tournament.status == TournamentStatus.completed) {
      return 'View Results';
    } else if (tournament.status == TournamentStatus.ongoing) {
      return 'View Progress';
    } else if (_canRegister()) {
      return 'Register';
    } else if (tournament.currentTeamsCount >= tournament.maxTeams) {
      return 'Full';
    } else if (tournament.registrationEndDate.isBefore(DateTime.now())) {
      return 'Closed';
    } else {
      return 'View Details';
    }
  }

  /// Check if tournament has a winner
  bool _hasWinner() {
    return tournament.status == TournamentStatus.completed &&
           tournament.winnerTeamId != null;
  }
}
