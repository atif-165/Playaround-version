import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/material3/material3_components.dart';
import '../../../services/cloudinary_service.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../models/team_match_model.dart';
import '../models/team_profile_models.dart';
import '../services/team_service.dart';
import '../screens/team_join_requests_screen.dart';
import '../screens/team_matches_overview_screen.dart';
import '../screens/team_schedule_screen.dart';
import '../widgets/team_member_card.dart';

/// Glass-themed admin panel that mirrors the public profile admin experience.
class TeamAdminPanelSheet extends StatefulWidget {
  const TeamAdminPanelSheet({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.team,
    required this.canEdit,
  });

  final String teamId;
  final String teamName;
  final Team team;
  final bool canEdit;

  static Future<void> show({
    required BuildContext context,
    required String teamId,
    required String teamName,
    required Team team,
    required bool canEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          maxChildSize: 0.97,
          minChildSize: 0.6,
          builder: (context, controller) {
            return TeamAdminPanelSheet(
              teamId: teamId,
              teamName: teamName,
              team: team,
              canEdit: canEdit,
            );
          },
        );
      },
    );
  }

  @override
  State<TeamAdminPanelSheet> createState() => _TeamAdminPanelSheetState();
}

class _TeamAdminPanelSheetState extends State<TeamAdminPanelSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeamService _teamService = TeamService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  late Team _teamSnapshot;
  StreamSubscription<Team?>? _teamSubscription;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  SportType? _selectedSport;
  File? _profileImage;
  File? _bannerImage;
  bool _isSavingOverview = false;

  @override
  void initState() {
    super.initState();
    _teamSnapshot = widget.team;
    _tabController = TabController(length: 5, vsync: this);
    _initialiseControllers();
    _teamSubscription = _teamService.watchTeam(widget.teamId).listen((team) {
      if (team != null && mounted) {
        setState(() {
          _teamSnapshot = team;
        });
      }
    });
  }

  void _initialiseControllers() {
    _nameController = TextEditingController(text: widget.team.name);
    _descriptionController =
        TextEditingController(text: widget.team.description);
    _bioController = TextEditingController(text: widget.team.bio ?? '');
    _cityController = TextEditingController(text: widget.team.city ?? '');
    _selectedSport = widget.team.sportType;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamSubscription?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.canEdit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28.r),
        topRight: Radius.circular(28.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Gap(12.h),
            _buildHandle(),
            Gap(12.h),
            Text(
              'Team Admin Panel',
              style: TextStyles.font18DarkBlue600Weight
                  .copyWith(color: Colors.white),
            ),
            Gap(4.h),
            Text(
              widget.teamName,
              style: TextStyles.font14White500Weight,
            ),
            Gap(16.h),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: PublicProfileTheme.panelAccentColor,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.white.withOpacity(0.08),
              indicatorColor: PublicProfileTheme.panelAccentColor,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Members'),
                Tab(text: 'Schedule'),
                Tab(text: 'Performance'),
                Tab(text: 'Records'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildMembersTab(),
                  _buildScheduleTab(),
                  _buildPerformanceTab(),
                  _buildRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 50.w,
      height: 5.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaRow(),
          Gap(20.h),
          _buildGlassCard(
            title: 'Team Identity',
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Team Name',
                  enabled: _canEdit,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Name is required'
                          : null,
                ),
                Gap(12.h),
                _buildTextField(
                  controller: _bioController,
                  label: 'Tagline / Bio',
                  maxLines: 2,
                  enabled: _canEdit,
                ),
                Gap(12.h),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'About',
                  maxLines: 3,
                  enabled: _canEdit,
                ),
                Gap(12.h),
                _buildTextField(
                  controller: _cityController,
                  label: 'City / Home base',
                  enabled: _canEdit,
                ),
                Gap(12.h),
                _buildSportPicker(),
                Gap(20.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppFilledButton(
                    text: _canEdit ? 'Save Changes' : 'View Only',
                    onPressed: !_canEdit || _isSavingOverview
                        ? null
                        : _saveOverviewChanges,
                    isLoading: _isSavingOverview,
                    size: ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMediaPicker(
            label: 'Profile Picture',
            imageFile: _profileImage,
            imageUrl: _teamSnapshot.teamImageUrl,
            onTap: !_canEdit ? null : () => _pickImage(isProfile: true),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: _buildMediaPicker(
            label: 'Banner Image',
            imageFile: _bannerImage,
            imageUrl: _teamSnapshot.backgroundImageUrl,
            onTap: !_canEdit ? null : () => _pickImage(isProfile: false),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPicker({
    required String label,
    required File? imageFile,
    required String? imageUrl,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140.h,
        decoration: BoxDecoration(
          gradient: PublicProfileTheme.panelGradient,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: imageFile != null
                    ? Image.file(imageFile, fit: BoxFit.cover)
                    : (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildMediaPlaceholder(
                              label,
                            ),
                          )
                        : _buildMediaPlaceholder(label),
              ),
            ),
            if (onTap != null)
              Positioned(
                right: 12.w,
                top: 12.h,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Change',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder(String label) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
      ),
      child: Text(
        label,
        style: TextStyles.font14White500Weight
            .copyWith(color: Colors.white.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyles.font14White500Weight,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyles.font12White500Weight.copyWith(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSportPicker() {
    return DropdownButtonFormField<SportType>(
      value: _selectedSport,
      onChanged: _canEdit
          ? (value) => setState(() {
                _selectedSport = value;
              })
          : null,
      dropdownColor: Colors.black87,
      decoration: InputDecoration(
        labelText: 'Sport',
        labelStyle:
            TextStyles.font12White500Weight.copyWith(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      items: SportType.values
          .map(
            (sport) => DropdownMenuItem(
              value: sport,
              child: Text(
                sport.displayName,
                style: TextStyles.font14White500Weight,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMembersTab() {
    final members = _teamSnapshot.members;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: AppOutlinedButton(
              text: 'Join Requests',
              onPressed: () => _openJoinRequests(context),
              icon: const Icon(Icons.inbox),
            ),
          ),
          Gap(12.h),
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Text(
                      'No members yet.',
                      style: TextStyles.font14White500Weight,
                    ),
                  )
                : ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Gap(8.h),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return TeamMemberCard(
                        member: member,
                        isAdmin: _canEdit,
                        onEdit: _canEdit
                            ? () => _showRolePicker(member)
                            : null,
                        onRemove:
                            _canEdit ? () => _removeMember(member) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return StreamBuilder<List<TeamMatch>>(
      stream: _teamService.watchTeamScheduleMatches(widget.teamId),
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'Open Schedule',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TeamScheduleScreen(
                              teamId: widget.teamId,
                              teamName: widget.teamName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: AppFilledButton(
                      text: 'Create Match',
                      onPressed: _canEdit ? _showMatchForm : null,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          'No scheduled matches yet.',
                          style: TextStyles.font14White500Weight,
                        ),
                      )
                    : ListView.separated(
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => Gap(10.h),
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return _buildMatchCard(match);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return StreamBuilder<TeamPerformance>(
      stream: _teamService.watchTeamPerformance(widget.teamId),
      builder: (context, snapshot) {
        final performance = snapshot.data;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            children: [
              _buildPerformanceEditor(performance),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    return _TeamRecordsManager(
      teamId: widget.teamId,
      canEdit: _canEdit,
    );
  }

  Widget _buildGlassCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: PublicProfileTheme.glassPanelDecoration(
        borderRadius: 20.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16White600Weight,
          ),
          Gap(16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildMatchCard(TeamMatch match) {
    final statusColor = _matchStatusColor(match.status);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: PublicProfileTheme.glassPanelDecoration(
        borderRadius: 18.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.homeTeam.teamName} vs ${match.awayTeam.teamName}',
                  style: TextStyles.font14White600Weight,
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  match.status.name.toUpperCase(),
                  style: TextStyles.font10White500Weight
                      .copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          Gap(6.h),
          Text(
            '${_dateFormat.format(match.scheduledTime)} • ${match.venueName ?? 'Venue TBD'}',
            style:
                TextStyles.font12White500Weight.copyWith(color: Colors.white70),
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  text: 'Details',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TeamMatchesOverviewScreen(
                          teamId: widget.teamId,
                          teamName: widget.teamName,
                        ),
                      ),
                    );
                  },
                  size: ButtonSize.small,
                ),
              ),
              Gap(8.w),
              Expanded(
                child: AppFilledButton(
                  text: 'Update',
                  onPressed: _canEdit ? () => _showMatchUpdateForm(match) : null,
                  size: ButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceEditor(TeamPerformance? performance) {
    final winsController = TextEditingController(
        text: '${performance?.wins ?? _teamSnapshot.stat['matchesWon'] ?? 0}');
    final lossesController = TextEditingController(
        text:
            '${performance?.losses ?? _teamSnapshot.stat['matchesLost'] ?? 0}');
    final drawsController = TextEditingController(
        text:
            '${performance?.draws ?? _teamSnapshot.stat['matchesDrawn'] ?? 0}');
    final goalsForController = TextEditingController(
        text:
            '${performance?.goalsScored ?? _teamSnapshot.stat['goalsScored'] ?? 0}');
    final goalsAgainstController = TextEditingController(
        text:
            '${performance?.goalsConceded ?? _teamSnapshot.stat['goalsConceded'] ?? 0}');

    return _buildGlassCard(
      title: 'Results & Form',
      child: Column(
        children: [
          _buildNumberRow('Wins', winsController),
          Gap(12.h),
          _buildNumberRow('Losses', lossesController),
          Gap(12.h),
          _buildNumberRow('Draws', drawsController),
          Gap(12.h),
          _buildNumberRow('Goals For', goalsForController),
          Gap(12.h),
          _buildNumberRow('Goals Against', goalsAgainstController),
          Gap(20.h),
          Align(
            alignment: Alignment.centerRight,
            child: AppFilledButton(
              text: 'Save Performance',
              onPressed: _canEdit
                  ? () => _savePerformance(
                        winsController,
                        lossesController,
                        drawsController,
                        goalsForController,
                        goalsAgainstController,
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyles.font14White500Weight,
          ),
        ),
        SizedBox(
          width: 90.w,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            enabled: _canEdit,
            style: TextStyles.font14White500Weight,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage({required bool isProfile}) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
    );
    if (file == null) return;
    setState(() {
      if (isProfile) {
        _profileImage = File(file.path);
      } else {
        _bannerImage = File(file.path);
      }
    });
  }

  Future<void> _saveOverviewChanges() async {
    setState(() => _isSavingOverview = true);

    try {
      String? profileUrl = _teamSnapshot.teamImageUrl;
      String? bannerUrl = _teamSnapshot.backgroundImageUrl;

      if (_profileImage != null) {
        profileUrl = await _cloudinaryService.uploadImage(
          _profileImage!,
          folder: 'team_profiles',
        );
      }
      if (_bannerImage != null) {
        bannerUrl = await _cloudinaryService.uploadImage(
          _bannerImage!,
          folder: 'team_banners',
        );
      }

      await _teamService.updateTeam(
        teamId: widget.teamId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        bio: _bioController.text.trim(),
        location: _cityController.text.trim(),
        sportType: _selectedSport,
        teamImageUrl: profileUrl,
        bannerImageUrl: bannerUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team profile updated'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingOverview = false);
      }
    }
  }

  Future<void> _openJoinRequests(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TeamJoinRequestsScreen(teamId: widget.teamId),
      ),
    );
  }

  Future<void> _showRolePicker(TeamMember member) async {
    final newRole = await showModalBottomSheet<TeamRole>(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TeamRole.values.map((role) {
              return ListTile(
                title: Text(role.displayName, style: TextStyles.font14White500Weight),
                onTap: () => Navigator.of(context).pop(role),
              );
            }).toList(),
          ),
        );
      },
    );

    if (newRole == null || newRole == member.role) return;
    try {
      await _teamService.updateMemberRole(widget.teamId, member.userId, newRole);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update member: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(TeamMember member) async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove member'),
            content: Text('Remove ${member.userName} from the team?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldRemove) return;

    try {
      await _teamService.removeMemberFromTeam(
        teamId: widget.teamId,
        userId: member.userId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _savePerformance(
    TextEditingController wins,
    TextEditingController losses,
    TextEditingController draws,
    TextEditingController goalsFor,
    TextEditingController goalsAgainst,
  ) async {
    try {
      final performance = TeamPerformance(
        teamId: widget.teamId,
        teamName: widget.teamName,
        wins: int.tryParse(wins.text) ?? 0,
        losses: int.tryParse(losses.text) ?? 0,
        draws: int.tryParse(draws.text) ?? 0,
        goalsScored: int.tryParse(goalsFor.text) ?? 0,
        goalsConceded: int.tryParse(goalsAgainst.text) ?? 0,
        winPercentage: 0,
        totalMatches: 0,
      );
      await _teamService.upsertTeamPerformance(widget.teamId, performance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save performance: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showMatchForm() async {
    if (!_canEdit) return;
    final opponentController = TextEditingController();
    final venueController = TextEditingController();
    final notesController = TextEditingController();
    DateTime scheduled = DateTime.now().add(const Duration(days: 1));
    TeamMatchStatus status = TeamMatchStatus.scheduled;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 24.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create Manual Match',
                  style: TextStyles.font16White600Weight),
              Gap(16.h),
              TextFormField(
                controller: opponentController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Opponent'),
              ),
              Gap(12.h),
              TextFormField(
                controller: venueController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              Gap(12.h),
              TextFormField(
                controller: notesController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              Gap(12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dateFormat.format(scheduled),
                  style: TextStyles.font14White500Weight,
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.white),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: scheduled,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => scheduled = picked);
                  }
                },
              ),
              Gap(12.h),
              DropdownButtonFormField<TeamMatchStatus>(
                value: status,
                dropdownColor: Colors.black,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Status'),
                onChanged: (value) {
                  if (value != null) {
                    status = value;
                  }
                },
                items: TeamMatchStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
              ),
              Gap(20.h),
              AppFilledButton(
                text: 'Save Match',
                onPressed: () async {
                  final match = TeamMatch(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    homeTeamId: widget.teamId,
                    awayTeamId: 'custom_${opponentController.text.trim()}',
                    homeTeam: TeamScore(
                      teamId: widget.teamId,
                      teamName: widget.teamName,
                      score: 0,
                    ),
                    awayTeam: TeamScore(
                      teamId: 'opponent',
                      teamName: opponentController.text.trim(),
                      score: 0,
                    ),
                    sportType: _selectedSport ?? widget.team.sportType,
                    matchType: TeamMatchType.friendly,
                    status: status,
                    scheduledTime: scheduled,
                    venueName: venueController.text.trim(),
                    notes: notesController.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await _teamService.upsertTeamMatch(widget.teamId, match);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMatchUpdateForm(TeamMatch match) async {
    if (!_canEdit) return;
    final notesController =
        TextEditingController(text: match.notes ?? '');
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Match Result',
                  style: TextStyles.font16White600Weight),
              Gap(12.h),
              TextFormField(
                controller: notesController,
                style: TextStyles.font14White500Weight,
                decoration:
                    const InputDecoration(labelText: 'Result / Notes'),
              ),
              Gap(16.h),
              AppFilledButton(
                text: 'Save',
                onPressed: () async {
                  await _teamService.upsertTeamMatch(
                    widget.teamId,
                    match.copyWith(
                      notes: notesController.text.trim(),
                      status: TeamMatchStatus.completed,
                    ),
                  );
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _matchStatusColor(TeamMatchStatus status) {
    switch (status) {
      case TeamMatchStatus.live:
        return Colors.redAccent;
      case TeamMatchStatus.completed:
        return Colors.greenAccent;
      case TeamMatchStatus.scheduled:
      default:
        return PublicProfileTheme.panelAccentColor;
    }
  }
}

/// Records tab for achievements, history, custom stats, and tournaments.
class _TeamRecordsManager extends StatefulWidget {
  const _TeamRecordsManager({
    required this.teamId,
    required this.canEdit,
  });

  final String teamId;
  final bool canEdit;

  @override
  State<_TeamRecordsManager> createState() => _TeamRecordsManagerState();
}

class _TeamRecordsManagerState extends State<_TeamRecordsManager> {
  final TeamService _teamService = TeamService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final Uuid _uuid = const Uuid();

  bool get _canEdit => widget.canEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
          _buildAchievementsSection(),
          Gap(16.h),
          _buildCustomStatsSection(),
          Gap(16.h),
          _buildHistorySection(),
          Gap(16.h),
          _buildTournamentsSection(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: PublicProfileTheme.glassPanelDecoration(
        borderRadius: 20.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyles.font16White600Weight,
                ),
              ),
              if (_canEdit && onAdd != null)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
            ],
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return _buildSection(
      title: 'Achievements',
      onAdd: _canEdit ? _showAchievementForm : null,
      child: StreamBuilder<List<TeamAchievement>>(
        stream: _teamService.watchTeamAchievements(widget.teamId),
        builder: (context, snapshot) {
          final achievements = snapshot.data ?? [];
          if (achievements.isEmpty) {
            return _buildEmptyState('Nothing recorded yet.');
          }
          return Column(
            children: achievements.map((achievement) {
              final dateLabel = _dateFormat.format(achievement.achievedAt);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  achievement.title,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '${achievement.description ?? ''}\n$dateLabel',
                  style: TextStyles.font12White500Weight,
                ),
                isThreeLine: true,
                trailing: _canEdit
                    ? IconButton(
                        onPressed: () =>
                            _teamService.deleteTeamAchievement(
                                widget.teamId, achievement.id),
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                      )
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCustomStatsSection() {
    return _buildSection(
      title: 'Custom Stats',
      onAdd: _canEdit ? _showCustomStatForm : null,
      child: StreamBuilder<List<TeamCustomStat>>(
        stream: _teamService.watchTeamCustomStats(widget.teamId),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? [];
          if (stats.isEmpty) return _buildEmptyState('No custom stats yet.');
          return Column(
            children: stats.map((stat) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  stat.label,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  stat.description ?? '',
                  style: TextStyles.font12White500Weight,
                ),
                trailing: Text(
                  stat.units != null ? '${stat.value} ${stat.units}' : stat.value,
                  style: TextStyles.font14White600Weight,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHistorySection() {
    return _buildSection(
      title: 'Venue History',
      onAdd: _canEdit ? _showHistoryForm : null,
      child: StreamBuilder<List<TeamHistoryEntry>>(
        stream: _teamService.watchTeamHistory(widget.teamId, limit: 10),
        builder: (context, snapshot) {
          final history = snapshot.data ?? [];
          if (history.isEmpty) {
            return _buildEmptyState('No history entries yet.');
          }
          return Column(
            children: history.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.venue,
                    style: TextStyles.font14White600Weight),
                subtitle: Text(
                  '${entry.opponent} • ${_dateFormat.format(entry.date)}',
                  style: TextStyles.font12White500Weight,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTournamentsSection() {
    return _buildSection(
      title: 'Tournaments',
      onAdd: _canEdit ? _showTournamentForm : null,
      child: StreamBuilder<List<TeamTournamentEntry>>(
        stream: _teamService.watchTeamTournaments(widget.teamId),
        builder: (context, snapshot) {
          final tournaments = snapshot.data ?? [];
          if (tournaments.isEmpty) {
            return _buildEmptyState('No tournaments yet.');
          }
          return Column(
            children: tournaments.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.tournamentName,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '${entry.stage} • ${entry.status}',
                  style: TextStyles.font12White500Weight,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyles.font12White500Weight,
        ),
      ),
    );
  }

  Future<void> _showAchievementForm() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime achievedAt = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 24.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Achievement', style: TextStyles.font16White600Weight),
              Gap(16.h),
              TextFormField(
                controller: titleController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              Gap(12.h),
              TextFormField(
                controller: descriptionController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              Gap(12.h),
              ListTile(
                title: Text(
                  _dateFormat.format(achievedAt),
                  style: TextStyles.font14White500Weight,
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.white),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: achievedAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => achievedAt = picked);
                  }
                },
              ),
              Gap(16.h),
              AppFilledButton(
                text: 'Save Achievement',
                onPressed: () async {
                  final achievement = TeamAchievement(
                    id: _uuid.v4(),
                    teamId: widget.teamId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    type: 'custom',
                    achievedAt: achievedAt,
                  );
                  await _teamService.upsertTeamAchievement(
                    widget.teamId,
                    achievement,
                  );
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomStatForm() async {
    final labelController = TextEditingController();
    final valueController = TextEditingController();
    final unitsController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Custom Stat',
                  style: TextStyles.font16White600Weight),
              Gap(12.h),
              TextFormField(
                controller: labelController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              Gap(12.h),
              TextFormField(
                controller: valueController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
              Gap(12.h),
              TextFormField(
                controller: unitsController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Units'),
              ),
              Gap(16.h),
              AppFilledButton(
                text: 'Save Stat',
                onPressed: () async {
                  final stat = TeamCustomStat(
                    id: _uuid.v4(),
                    label: labelController.text.trim(),
                    value: valueController.text.trim(),
                    units: unitsController.text.trim().isEmpty
                        ? null
                        : unitsController.text.trim(),
                  );
                  await _teamService.upsertCustomStat(widget.teamId, stat);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHistoryForm() async {
    final venueController = TextEditingController();
    final opponentController = TextEditingController();
    final summaryController = TextEditingController();
    final locationController = TextEditingController();
    DateTime date = DateTime.now();

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add History Entry',
                  style: TextStyles.font16White600Weight),
              Gap(12.h),
              TextFormField(
                controller: venueController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Venue'),
              ),
              Gap(12.h),
              TextFormField(
                controller: opponentController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Opponent'),
              ),
              Gap(12.h),
              TextFormField(
                controller: summaryController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Summary'),
              ),
              Gap(12.h),
              TextFormField(
                controller: locationController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              Gap(12.h),
              ListTile(
                title: Text(
                  _dateFormat.format(date),
                  style: TextStyles.font14White500Weight,
                ),
                trailing: const Icon(Icons.calendar_month, color: Colors.white),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => date = picked);
                  }
                },
              ),
              Gap(16.h),
              AppFilledButton(
                text: 'Save Entry',
                onPressed: () async {
                  final entry = TeamHistoryEntry(
                    id: _uuid.v4(),
                    venue: venueController.text.trim(),
                    opponent: opponentController.text.trim(),
                    date: date,
                    matchType: 'Friendly',
                    result: 'Pending',
                    summary: summaryController.text.trim(),
                    location: locationController.text.trim(),
                  );
                  await _teamService.upsertHistoryEntry(widget.teamId, entry);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTournamentForm() async {
    final nameController = TextEditingController();
    final statusController = TextEditingController(text: 'Upcoming');
    final stageController = TextEditingController(text: 'Group Stage');

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Tournament',
                  style: TextStyles.font16White600Weight),
              Gap(12.h),
              TextFormField(
                controller: nameController,
                style: TextStyles.font14White500Weight,
                decoration:
                    const InputDecoration(labelText: 'Tournament Name'),
              ),
              Gap(12.h),
              TextFormField(
                controller: statusController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              Gap(12.h),
              TextFormField(
                controller: stageController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(labelText: 'Stage'),
              ),
              Gap(16.h),
              AppFilledButton(
                text: 'Save Tournament',
                onPressed: () async {
                  final entry = TeamTournamentEntry(
                    id: _uuid.v4(),
                    tournamentName: nameController.text.trim(),
                    status: statusController.text.trim(),
                    stage: stageController.text.trim(),
                    startDate: DateTime.now(),
                  );
                  await _teamService.upsertTournamentEntry(
                      widget.teamId, entry);
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

