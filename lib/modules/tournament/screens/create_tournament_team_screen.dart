import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../models/tournament_match_model.dart';
import '../services/tournament_join_request_service.dart';
import '../services/tournament_team_service.dart';

class CreateTournamentTeamScreen extends StatefulWidget {
  final String tournamentId;

  const CreateTournamentTeamScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<CreateTournamentTeamScreen> createState() =>
      _CreateTournamentTeamScreenState();
}

class _CreateTournamentTeamScreenState
    extends State<CreateTournamentTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _joinRequestService = TournamentJoinRequestService();
  final _teamService = TournamentTeamService();

  final List<String> _selectedPlayerIds = [];
  final List<String> _selectedPlayerNames = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Color get _accentColor => ColorsManager.primary;

  BoxDecoration _panelDecoration({double radius = 16}) {
    return BoxDecoration(
      gradient: PublicProfileTheme.panelGradient,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
      boxShadow: PublicProfileTheme.defaultShadow(),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      fillColor: Colors.white.withOpacity(0.05),
      filled: true,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: _accentColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Tournament Team'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: StreamBuilder<List<TournamentJoinRequest>>(
        stream: _joinRequestService.watchIndividualRequests(
          widget.tournamentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ColorsManager.primary,
                  ),
                );
          }

          // For this demo, showing pending requests
          // In production, you'd filter for ACCEPTED requests
          final requests = snapshot.data ?? [];
          final individualRequests =
              requests.where((r) => !r.isTeamRequest).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  Gap(24.h),
                  _buildTeamNameField(),
                  Gap(24.h),
                  _buildPlayerSelectionSection(individualRequests),
                  Gap(32.h),
                  _buildSelectedPlayersSection(),
                  Gap(32.h),
                  _buildCreateButton(),
                ],
              ),
            ),
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _accentColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _accentColor, size: 24.sp),
          Gap(12.w),
          Expanded(
            child: Text(
              'Select players from accepted requests to create a team for this tournament',
              style: TextStyle(
                color: _accentColor,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Name',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _teamNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration('Enter team name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter team name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPlayerSelectionSection(List<TournamentJoinRequest> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Players',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
          ),
        ),
        Gap(8.h),
        Text(
          'Tap on players to add them to the team',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12.sp,
          ),
        ),
        Gap(16.h),
        if (requests.isEmpty)
          _buildEmptyState()
        else
          ...requests.map((request) => _buildPlayerCard(request)),
      ],
    );
  }

  Widget _buildPlayerCard(TournamentJoinRequest request) {
    final isSelected = _selectedPlayerIds.contains(request.requesterId);
    final metadata = request.metadata ?? const {};
    final city = metadata['City']?.toString();
    final position =
        metadata['Playing Position']?.toString() ?? request.position;
    final contact = metadata['Contact']?.toString();
    final skillLabel = metadata['Skill Level']?.toString();
    final selfRating = metadata['Self Rating']?.toString() ??
        (request.skillLevel != null ? '${request.skillLevel}/10' : null);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPlayerIds.remove(request.requesterId);
            _selectedPlayerNames.remove(request.requesterName);
          } else {
            _selectedPlayerIds.add(request.requesterId);
            _selectedPlayerNames.add(request.requesterName);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.25),
                    _accentColor.withOpacity(0.1),
                  ],
                )
              : PublicProfileTheme.panelGradient,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? _accentColor : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _accentColor : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? _accentColor : Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16.sp,
                    )
                  : null,
            ),
            Gap(12.w),

            // Player Avatar
            CircleAvatar(
              radius: 24.r,
              backgroundImage: request.requesterProfileUrl != null
                  ? NetworkImage(request.requesterProfileUrl!)
                  : null,
              child: request.requesterProfileUrl == null
                  ? Text(
                      request.requesterName[0].toUpperCase(),
                      style: TextStyle(fontSize: 18.sp),
                    )
                  : null,
            ),
            Gap(12.w),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (city != null) _buildPlayerMetaRow('City', city),
                  if (position != null)
                    _buildPlayerMetaRow('Position', position),
                  if (contact != null)
                    _buildPlayerMetaRow('Contact', contact),
                  if (skillLabel != null)
                    _buildPlayerMetaRow('Skill Level', skillLabel),
                  if (selfRating != null) ...[
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14.sp),
                        Gap(4.w),
                        Text(
                          selfRating,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPlayersSection() {
    if (_selectedPlayerIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _accentColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Players (${_selectedPlayerIds.length})',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _selectedPlayerNames.map((name) {
              return Chip(
                label: Text(name),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final index = _selectedPlayerNames.indexOf(name);
                  setState(() {
                    _selectedPlayerNames.removeAt(index);
                    _selectedPlayerIds.removeAt(index);
                  });
                },
                backgroundColor: _accentColor.withOpacity(0.25),
                labelStyle: const TextStyle(color: Colors.white),
                deleteIconColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMetaRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12.sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading || _selectedPlayerIds.isEmpty ? null : _createTeam,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Create Team (${_selectedPlayerIds.length} players)',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64.sp,
              color: Colors.white.withOpacity(0.5),
            ),
            Gap(16.h),
            Text(
              'No accepted players yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16.sp,
              ),
            ),
            Gap(8.h),
            Text(
              'Accept join requests first to create teams',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one player'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _teamService.createTeam(
        tournamentId: widget.tournamentId,
        name: _teamNameController.text.trim(),
        playerIds: _selectedPlayerIds,
        playerNames: _selectedPlayerNames,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create team: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
