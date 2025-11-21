import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/team_match_model.dart';
import '../services/team_service.dart';
import '../widgets/team_match_card.dart';

class TeamMatchesOverviewScreen extends StatefulWidget {
  const TeamMatchesOverviewScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    this.showAppBar = true,
  });

  final String teamId;
  final String teamName;
  final bool showAppBar;

  @override
  State<TeamMatchesOverviewScreen> createState() =>
      _TeamMatchesOverviewScreenState();
}

class _TeamMatchesOverviewScreenState extends State<TeamMatchesOverviewScreen> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<TeamMatch>>(
      stream: _teamService.watchTeamScheduleMatches(widget.teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ColorsManager.mainBlue),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Unable to load matches. Please try again later.',
          );
        }

        final matches = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: matches.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemBuilder: (context, index) =>
                          _buildMatchCard(matches[index]),
                      separatorBuilder: (_, __) => Gap(16.h),
                      itemCount: matches.length,
                    ),
            ),
          ],
        );
      },
    );

    if (!widget.showAppBar) {
      return Container(
        color: Colors.transparent,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.teamName} Matches',
          style: TextStyles.font16White600Weight,
        ),
      ),
      body: body,
    );
  }

  // Filters removed as per requirement; always show all matches in chronological order

  Widget _buildMatchCard(TeamMatch match) {
    return TeamMatchCard(
      match: match,
      teamId: widget.teamId,
      onTap: () => _openMatchDetail(match),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 48, color: Colors.white38),
          Gap(12.h),
          Text(
            'No matches to show',
            style: TextStyles.font14White600Weight,
          ),
          Gap(6.h),
          Text(
            'Matches you add will appear here automatically.',
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          Gap(12.h),
          Text(
            'Something went wrong',
            style: TextStyles.font14White600Weight,
          ),
          Gap(6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              message,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMatchDetail(TeamMatch match) async {
    await DetailNavigator.openMatch(
      context,
      teamMatch: match,
    );
  }
}

