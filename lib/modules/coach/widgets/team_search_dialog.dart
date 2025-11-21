import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_form_field.dart';
import '../../../modules/team/models/team_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../services/coach_associations_service.dart';

/// Dialog for searching and selecting teams to add to coach profile
class TeamSearchDialog extends StatefulWidget {
  final String coachId;
  final String coachName;

  const TeamSearchDialog({
    super.key,
    required this.coachId,
    required this.coachName,
  });

  @override
  State<TeamSearchDialog> createState() => _TeamSearchDialogState();
}

class _TeamSearchDialogState extends State<TeamSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final CoachAssociationsService _associationsService =
      CoachAssociationsService();

  List<TeamModel> _teams = [];
  bool _isLoading = false;
  bool _isRequesting = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().length < 2) {
      setState(() {
        _teams = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchTeams();
    });
  }

  Future<void> _searchTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teams =
          await _associationsService.searchTeams(_searchController.text);
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching teams: $e')),
        );
      }
    }
  }

  Future<void> _requestTeamAssociation(TeamModel team) async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final success = await _associationsService.requestTeamAssociation(
        widget.coachId,
        widget.coachName,
        team,
      );

      if (mounted) {
        setState(() {
          _isRequesting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request sent to team captain'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send request or team already added'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        width: double.maxFinite,
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(16.h),
            _buildSearchField(),
            Gap(16.h),
            Expanded(child: _buildTeamsList()),
            Gap(16.h),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.group_add,
          color: ColorsManager.primary,
          size: 24.sp,
        ),
        Gap(8.w),
        Expanded(
          child: Text(
            'Add Team',
            style: TextStyles.font18DarkBlueBold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearchChanged,
      style: TextStyles.font14DarkBlue500Weight,
      decoration: InputDecoration(
        hintText: 'Search teams by name or location...',
        hintStyle: TextStyles.font14Hint500Weight,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _isLoading
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _teams = [];
                      });
                    },
                  )
                : null,
        filled: true,
        fillColor: ColorsManager.lightShadeOfGray,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.gray93Color,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.mainBlue,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    if (_searchController.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48.sp,
              color: Colors.grey,
            ),
            Gap(16.h),
            Text(
              'Type at least 2 characters to search',
              style: TextStyles.font14Grey400Weight,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 48.sp,
              color: Colors.grey,
            ),
            Gap(16.h),
            Text(
              'No teams found',
              style: TextStyles.font14Grey400Weight,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    final isRequesting = _isRequesting;
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: isRequesting ? null : () => _requestTeamAssociation(team),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorsManager.primary.withAlpha(51),
                radius: 28.r,
                backgroundImage: team.profileImageUrl != null
                    ? NetworkImage(team.profileImageUrl!)
                    : null,
                child: team.profileImageUrl == null
                    ? Icon(
                        Icons.group,
                        color: ColorsManager.primary,
                        size: 24.sp,
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyles.font16DarkBlue500Weight,
                    ),
                    Gap(4.h),
                    if (team.description != null)
                      Text(
                        team.description!,
                        style: TextStyles.font12Grey400Weight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (team.description != null) Gap(2.h),
                    if (team.city != null)
                      Text(
                        'Location: ${team.city}',
                        style: TextStyles.font12Grey400Weight,
                      ),
                    Gap(2.h),
                    Text(
                      '${team.players.length}/${team.maxPlayers} players',
                      style: TextStyles.font12Grey400Weight,
                    ),
                    Gap(2.h),
                    Text(
                      'Sport: ${team.sportType.displayName}',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              ElevatedButton(
                onPressed: isRequesting ? null : () => _requestTeamAssociation(team),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(90.w, 36.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: isRequesting
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
