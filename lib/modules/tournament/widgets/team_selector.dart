import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../team/models/team_model.dart' as team;

/// Widget for selecting a team to join a tournament
class TeamSelector extends StatefulWidget {
  final String? selectedTeamId;
  final team.SportType sportType;
  final Function(String) onTeamSelected;

  const TeamSelector({
    super.key,
    required this.selectedTeamId,
    required this.sportType,
    required this.onTeamSelected,
  });

  @override
  State<TeamSelector> createState() => _TeamSelectorState();
}

class _TeamSelectorState extends State<TeamSelector> {
  List<team.Team> _userTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTeams();
  }

  Future<void> _loadUserTeams() async {
    // TODO: Load user's teams from service
    // For now, we'll simulate some data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _userTeams = [
        // Mock teams - replace with actual data
        team.Team(
          id: 'team1',
          name: 'Thunder Bolts',
          sportType: widget.sportType,
          ownerId: 'user1',
          description: 'A competitive team',
          maxMembers: 12,
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          members: [],
        ),
        team.Team(
          id: 'team2',
          name: 'Lightning Strikes',
          sportType: widget.sportType,
          ownerId: 'user1',
          description: 'Fast and furious',
          maxMembers: 10,
          isPublic: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          members: [],
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200.h,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorsManager.primary),
          ),
        ),
      );
    }

    if (_userTeams.isEmpty) {
      return _buildNoTeamsState();
    }

    return Column(
      children: [
        ..._userTeams.map((team) => _buildTeamCard(team)).toList(),
        Gap(16.h),
        _buildCreateTeamButton(),
      ],
    );
  }

  Widget _buildNoTeamsState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48.sp,
            color: ColorsManager.textSecondary,
          ),
          Gap(16.h),
          Text(
            'No Teams Available',
            style: TextStyles.font16DarkBlueBold,
          ),
          Gap(8.h),
          Text(
            'You need to create or join a team to participate in this tournament.',
            style: TextStyles.font14Grey400Weight.copyWith(
              color: ColorsManager.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(16.h),
          ElevatedButton.icon(
            onPressed: _createNewTeam,
            icon: const Icon(Icons.add),
            label: const Text('Create Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(team.Team team) {
    final isSelected = widget.selectedTeamId == team.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: RadioListTile<String>(
        value: team.id,
        groupValue: widget.selectedTeamId,
        onChanged: (value) {
          if (value != null) {
            widget.onTeamSelected(value);
          }
        },
        title: Text(
          team.name,
          style: TextStyles.font16DarkBlueBold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.description,
              style: TextStyles.font14Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
            Gap(4.h),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 14.sp,
                  color: ColorsManager.textSecondary,
                ),
                Gap(4.w),
                Text(
                  '${team.memberCount}/${team.maxMembers} members',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
                Gap(16.w),
                Icon(
                  Icons.sports_cricket,
                  size: 14.sp,
                  color: ColorsManager.textSecondary,
                ),
                Gap(4.w),
                Text(
                  team.sportType.displayName,
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: ColorsManager.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        activeColor: ColorsManager.primary,
        tileColor: isSelected
            ? ColorsManager.primary.withOpacity(0.1)
            : ColorsManager.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(
            color:
                isSelected ? ColorsManager.primary : ColorsManager.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildCreateTeamButton() {
    return OutlinedButton.icon(
      onPressed: _createNewTeam,
      icon: const Icon(Icons.add),
      label: const Text('Create New Team'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorsManager.primary,
        side: BorderSide(color: ColorsManager.primary),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
      ),
    );
  }

  void _createNewTeam() {
    // TODO: Navigate to create team screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create team functionality coming soon!'),
      ),
    );
  }
}
