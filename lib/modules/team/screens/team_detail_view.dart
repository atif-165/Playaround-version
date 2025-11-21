import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';
import 'team_detail_screen_enhanced.dart';

class TeamDetailView extends StatefulWidget {
  const TeamDetailView(this.teamId, {super.key});

  final String teamId;

  @override
  State<TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends State<TeamDetailView> {
  final TeamService _teamService = TeamService();
  late Future<TeamModel?> _teamFuture;

  @override
  void initState() {
    super.initState();
    _teamFuture = _teamService.getTeamById(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeamModel?>(
      future: _teamFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: ColorsManager.background,
            body: const Center(
              child: CircularProgressIndicator(color: ColorsManager.mainBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildFallback(
            context,
            'Couldn\'t load this team right now.',
            onRetry: () {
              setState(() {
                _teamFuture = _teamService.getTeamById(widget.teamId);
              });
            },
          );
        }

        final team = snapshot.data;
        if (team == null) {
          return _buildFallback(
            context,
            'This team profile is no longer available.',
          );
        }

        return TeamDetailScreenEnhanced(team: team);
      },
    );
  }

  Widget _buildFallback(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    return Scaffold(
      backgroundColor: ColorsManager.background,
      appBar: AppBar(
        title: const Text('Team detail'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyles.font16White600Weight,
              ),
              Gap(16.h),
              if (onRetry != null)
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                  ),
                  child: const Text('Try again'),
                )
              else
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                  ),
                  child: const Text('Close'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

