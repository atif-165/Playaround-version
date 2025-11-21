import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/styles.dart';
import '../models/models.dart';
import 'team_card.dart';

/// Widget for displaying a list of teams
class TeamListWidget extends StatelessWidget {
  final List<Team> teams;
  final Function(Team)? onTeamTap;
  final Function(Team)? onJoinTeam;
  final bool showJoinButton;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const TeamListWidget({
    super.key,
    required this.teams,
    this.onTeamTap,
    this.onJoinTeam,
    this.showJoinButton = false,
    this.isLoading = false,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No teams found',
              style: TextStyles.font16DarkBlue500Weight,
            ),
            Gap(8.h),
            Text(
              showJoinButton
                  ? 'No teams available to join at the moment'
                  : 'You haven\'t joined any teams yet',
              style: TextStyles.font13Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: teams.length,
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      physics: physics ?? const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => Gap(18.h),
      itemBuilder: (context, index) {
        final team = teams[index];
        return TeamCard(
          team: team,
          onTap: onTeamTap != null ? () => onTeamTap!(team) : null,
          onJoinTap: onJoinTeam != null ? () => onJoinTeam!(team) : null,
          showJoinButton: showJoinButton,
        );
      },
    );
  }
}
