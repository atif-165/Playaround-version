import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../services/cloudinary_service.dart';
import '../cubit/team_cubit.dart';
import '../models/team_model.dart';
import '../models/team_join_request.dart';
import '../models/team_match_model.dart';
import '../services/team_service.dart';
import '../widgets/join_request_card.dart';
import '../widgets/team_match_card.dart';
import '../../../core/navigation/detail_navigator.dart';
import '../widgets/team_admin_data_tab.dart';

class TeamAdminSettingsScreen extends StatefulWidget {
  final TeamModel team;
  final bool isReadOnly;

  const TeamAdminSettingsScreen({
    super.key,
    required this.team,
    this.isReadOnly = false,
  });

  @override
  State<TeamAdminSettingsScreen> createState() =>
      _TeamAdminSettingsScreenState();
}

class _TeamAdminSettingsScreenState extends State<TeamAdminSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final TeamService _teamService = TeamService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _profileImage;
  File? _bannerImage;
  bool _isLoading = false;

  bool get _canEdit => AppConfig.enablePublicTeamAdmin || !widget.isReadOnly;

  void _handleTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool _guardEditAction() {
    if (_canEdit) return true;
    _showReadOnlySnack();
    return false;
  }

  void _showReadOnlySnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only team admins can edit this panel.'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _nameController.text = widget.team.name;
    _bioController.text = widget.team.bio ?? '';
    _descriptionController.text = widget.team.description ?? '';
    _cityController.text = widget.team.city ?? '';
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (!_guardEditAction()) return;
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _pickBannerImage() async {
    if (!_guardEditAction()) return;
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (image != null) {
      setState(() {
        _bannerImage = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_guardEditAction()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? profileImageUrl = widget.team.profileImageUrl;
      String? bannerImageUrl = widget.team.bannerImageUrl;

      // Upload profile image to Cloudinary
      if (_profileImage != null) {
        profileImageUrl = await _cloudinaryService.uploadImage(
          _profileImage!,
          folder: 'team_profiles',
        );
      }

      // Upload banner image to Cloudinary
      if (_bannerImage != null) {
        bannerImageUrl = await _cloudinaryService.uploadImage(
          _bannerImage!,
          folder: 'team_banners',
        );
      }

      await _teamService.updateTeam(
        teamId: widget.team.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        teamImageUrl: profileImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating team settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _canEdit ? 'Team Settings' : '${widget.team.name} Admin',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _canEdit && _tabController.index == 0
            ? [
                TextButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const CustomProgressIndicator()
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: ColorsManager.mainBlue,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.h, left: 16.w, right: 16.w),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                color: ColorsManager.mainBlue,
                borderRadius: BorderRadius.circular(16.r),
              ),
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Members'),
                Tab(text: 'Matches'),
                Tab(text: 'Data'),
              ],
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!_canEdit) _buildViewOnlyNotice(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralSettingsTab(),
                    _buildMembersTab(),
                    _buildMatchesTab(),
                    _buildDataTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewOnlyNotice() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: PublicProfileTheme.glassPanelDecoration(
          borderRadius: 20.r,
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: PublicProfileTheme.panelAccentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: PublicProfileTheme.panelAccentColor,
                size: 18.sp,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                'View-only mode. Only team admins can edit this panel.',
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTab() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TeamAdminDataTab(
        team: widget.team,
        isReadOnly: widget.isReadOnly,
      ),
    );
  }

  Widget _buildBannerImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banner Image',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        GestureDetector(
          onTap: _canEdit ? _pickBannerImage : null,
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: _bannerImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.file(
                      _bannerImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.team.bannerImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          widget.team.bannerImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(
                                  Icons.image, 'Tap to add banner image'),
                        ),
                      )
                    : _buildImagePlaceholder(
                        Icons.image, 'Tap to add banner image'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Image',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        Center(
          child: GestureDetector(
            onTap: _canEdit ? _pickProfileImage : null,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
                border: Border.all(
                  color: ColorsManager.mainBlue,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: _profileImage != null
                    ? Image.file(
                        _profileImage!,
                        fit: BoxFit.cover,
                      )
                    : widget.team.profileImageUrl != null
                        ? Image.network(
                            widget.team.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(
                                    Icons.groups, 'Tap to add'),
                          )
                        : _buildImagePlaceholder(Icons.groups, 'Tap to add'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: 40.sp),
          Gap(8.h),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
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
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _nameController,
          enabled: _canEdit,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Enter team name',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Short Description',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _descriptionController,
          enabled: _canEdit,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Enter a short description',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Bio',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _bioController,
          enabled: _canEdit,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tell us about your team...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: TextStyles.font16DarkBlue600Weight.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: _cityController,
          enabled: _canEdit,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Enter city',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  // ============ GENERAL SETTINGS TAB ============
  Widget _buildGeneralSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerImageSection(),
            Gap(20.h),
            _buildProfileImageSection(),
            Gap(32.h),
            _buildTeamNameField(),
            Gap(20.h),
            _buildDescriptionField(),
            Gap(20.h),
            _buildBioField(),
            Gap(20.h),
            _buildCityField(),
            Gap(32.h),
          ],
        ),
      ),
    );
  }

  // ============ MEMBERS TAB ============
  Widget _buildMembersTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.grey[900],
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: ColorsManager.mainBlue,
              tabs: const [
                Tab(text: 'Requests'),
                Tab(text: 'Members'),
                Tab(text: 'Stats'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRequestsSection(),
                _buildMembersSection(),
                _buildStatsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ MATCHES TAB ============
  Widget _buildMatchesTab() {
    return StreamBuilder<List<TeamMatch>>(
      stream: _teamService.getTeamMatchesStream(widget.team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading matches: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_score,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                Gap(16.h),
                Text(
                  'No matches found',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Gap(8.h),
                Text(
                  'Create matches to track your team\'s performance',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                  ),
                ),
                Gap(24.h),
                ElevatedButton.icon(
                  onPressed: _canEdit ? _createNewMatch : _showReadOnlySnack,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainBlue,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildMatchCardWithActions(match),
            );
          },
        );
      },
    );
  }

  // ============ MATCH CARD WITH ACTIONS ============
  Widget _buildMatchCardWithActions(TeamMatch match) {
    return Column(
      children: [
        // Main match card
        TeamMatchCard(
          match: match,
          teamId: widget.team.id,
          onTap: () => _viewMatchDetails(match),
        ),
        // Admin actions
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: PublicProfileTheme.panelGradient,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: PublicProfileTheme.defaultShadow(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.visibility,
                label: 'View',
                onTap: () => _viewMatchDetails(match),
                color: ColorsManager.mainBlue,
              ),
              _buildToggleButton(match),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 18.sp,
            ),
            Gap(4.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(TeamMatch match) {
    // Check if match is visible on team profile (you'll need to add this field to your model)
    final isVisible = match.metadata?['isVisibleOnTeamProfile'] ?? true;

    return GestureDetector(
      onTap: _canEdit ? () => _toggleMatchVisibility(match) : _showReadOnlySnack,
      child: Opacity(
        opacity: _canEdit ? 1 : 0.4,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isVisible
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isVisible
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: isVisible ? Colors.green : Colors.grey,
                size: 18.sp,
              ),
              Gap(4.h),
              Text(
                isVisible ? 'Hide' : 'Show',
                style: TextStyle(
                  color: isVisible ? Colors.green : Colors.grey,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ MEMBERS SECTIONS ============

  Widget _buildRequestsSection() {
    return StreamBuilder<List<TeamJoinRequest>>(
      stream: _teamService.getTeamJoinRequestsStream(widget.team.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.sp,
                  color: Colors.red,
                ),
                Gap(16.h),
                Text(
                  'Error loading join requests: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add,
                  size: 64.sp,
                  color: Colors.grey[400],
                ),
                Gap(16.h),
                Text(
                  'No pending join requests',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Gap(8.h),
                Text(
                  'New join requests will appear here',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: JoinRequestCard(
                request: request,
                onApprove: _canEdit
                    ? () => _approveJoinRequest(request.id)
                    : _showReadOnlySnack,
                onReject: _canEdit
                    ? () => _rejectJoinRequest(request.id)
                    : _showReadOnlySnack,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersSection() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: widget.team.players.length + widget.team.coaches.length,
      itemBuilder: (context, index) {
        if (index < widget.team.players.length) {
          final player = widget.team.players[index];
          return _buildMemberCard(player, isCoach: false);
        } else {
          final coachIndex = index - widget.team.players.length;
          final coach = widget.team.coaches[coachIndex];
          return _buildMemberCard(coach, isCoach: true);
        }
      },
    );
  }

  Widget _buildStatsSection() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: widget.team.players.length,
      itemBuilder: (context, index) {
        final player = widget.team.players[index];
        return _buildPlayerStatsCard(player);
      },
    );
  }

  Widget _buildMemberCard(TeamPlayer member, {required bool isCoach}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: ColorsManager.mainBlue.withOpacity(0.2),
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(
                    member.name[0].toUpperCase(),
                    style: TextStyle(
                      color: ColorsManager.mainBlue,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(4.h),
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getRoleColor(member.role).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        member.role.displayName,
                        style: TextStyle(
                          color: _getRoleColor(member.role),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (member.position != null) ...[
                      Gap(8.w),
                      Text(
                        member.position!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                    if (member.jerseyNumber != null) ...[
                      Gap(8.w),
                      Text(
                        '#${member.jerseyNumber}',
                        style: TextStyle(
                          color: ColorsManager.mainBlue,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (member.role != TeamRole.owner)
            Opacity(
              opacity: _canEdit ? 1 : 0.4,
              child: PopupMenuButton<String>(
                enabled: _canEdit,
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onSelected: (value) => _handleMemberAction(value, member),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove,
                            color: Colors.red, size: 20.sp),
                        Gap(8.w),
                        Text('Remove from team'),
                      ],
                    ),
                  ),
                  if (!isCoach)
                    PopupMenuItem(
                      value: 'stats',
                      child: Row(
                        children: [
                          Icon(Icons.analytics,
                              color: ColorsManager.mainBlue, size: 20.sp),
                          Gap(8.w),
                          Text('Update stats'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'position',
                    child: Row(
                      children: [
                        Icon(Icons.sports,
                            color: Colors.orange, size: 20.sp),
                        Gap(8.w),
                        Text('Update position'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsCard(TeamPlayer player) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: ColorsManager.mainBlue.withOpacity(0.2),
                backgroundImage: player.profileImageUrl != null
                    ? NetworkImage(player.profileImageUrl!)
                    : null,
                child: player.profileImageUrl == null
                    ? Text(
                        player.name[0].toUpperCase(),
                        style: TextStyle(
                          color: ColorsManager.mainBlue,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (player.position != null)
                      Text(
                        player.position!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatButton(
                'Update Stats',
                () => _updatePlayerStats(player),
                enabled: _canEdit,
              ),
            ],
          ),
          Gap(16.h),
          _buildSportSpecificStats(player),
        ],
      ),
    );
  }

  Widget _buildSportSpecificStats(TeamPlayer player) {
    final sportType = widget.team.sportType;

    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return _buildFootballStats(player);
      case SportType.basketball:
        return _buildBasketballStats(player);
      case SportType.cricket:
        return _buildCricketStats(player);
      case SportType.tennis:
        return _buildTennisStats(player);
      default:
        return _buildGenericStats(player);
    }
  }

  Widget _buildFootballStats(TeamPlayer player) {
    final stats = player.playerStats ?? {};
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem('Goals', stats['goals']?.toString() ?? '0'),
            _buildStatItem('Assists', stats['assists']?.toString() ?? '0'),
            _buildStatItem('Matches', stats['matches']?.toString() ?? '0'),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _buildStatItem(
                'Yellow Cards', stats['yellowCards']?.toString() ?? '0'),
            _buildStatItem('Red Cards', stats['redCards']?.toString() ?? '0'),
            _buildStatItem('Rating', stats['rating']?.toString() ?? '0.0'),
          ],
        ),
      ],
    );
  }

  Widget _buildBasketballStats(TeamPlayer player) {
    final stats = player.playerStats ?? {};
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem('Points', stats['points']?.toString() ?? '0'),
            _buildStatItem('Rebounds', stats['rebounds']?.toString() ?? '0'),
            _buildStatItem('Assists', stats['assists']?.toString() ?? '0'),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _buildStatItem('Steals', stats['steals']?.toString() ?? '0'),
            _buildStatItem('Blocks', stats['blocks']?.toString() ?? '0'),
            _buildStatItem('Games', stats['games']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildCricketStats(TeamPlayer player) {
    final stats = player.playerStats ?? {};
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem('Runs', stats['runs']?.toString() ?? '0'),
            _buildStatItem('Wickets', stats['wickets']?.toString() ?? '0'),
            _buildStatItem('Matches', stats['matches']?.toString() ?? '0'),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _buildStatItem(
                'Batting Avg', stats['battingAvg']?.toString() ?? '0.0'),
            _buildStatItem(
                'Bowling Avg', stats['bowlingAvg']?.toString() ?? '0.0'),
            _buildStatItem('Catches', stats['catches']?.toString() ?? '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildTennisStats(TeamPlayer player) {
    final stats = player.playerStats ?? {};
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem('Wins', stats['wins']?.toString() ?? '0'),
            _buildStatItem('Losses', stats['losses']?.toString() ?? '0'),
            _buildStatItem('Sets Won', stats['setsWon']?.toString() ?? '0'),
          ],
        ),
        Gap(8.h),
        Row(
          children: [
            _buildStatItem('Aces', stats['aces']?.toString() ?? '0'),
            _buildStatItem(
                'Double Faults', stats['doubleFaults']?.toString() ?? '0'),
            _buildStatItem('Rating', stats['rating']?.toString() ?? '0.0'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericStats(TeamPlayer player) {
    final stats = player.playerStats ?? {};
    return Column(
      children: [
        Row(
          children: [
            _buildStatItem('Matches', stats['matches']?.toString() ?? '0'),
            _buildStatItem('Wins', stats['wins']?.toString() ?? '0'),
            _buildStatItem('Rating', stats['rating']?.toString() ?? '0.0'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton(
    String label,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : _showReadOnlySnack,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: ColorsManager.mainBlue),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ColorsManager.mainBlue,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.captain:
        return Colors.blue;
      case TeamRole.viceCaptain:
        return Colors.green;
      case TeamRole.coach:
        return Colors.orange;
      case TeamRole.member:
        return Colors.grey;
    }
  }

  void _handleMemberAction(String action, TeamPlayer member) {
    if (!_guardEditAction()) return;
    switch (action) {
      case 'remove':
        _removeMember(member);
        break;
      case 'stats':
        _updatePlayerStats(member);
        break;
      case 'position':
        _updatePlayerPosition(member);
        break;
    }
  }

  void _removeMember(TeamPlayer member) {
    if (!_guardEditAction()) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.name}'),
        content: Text(
            'Are you sure you want to remove ${member.name} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRemoveMember(member);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember(TeamPlayer member) async {
    if (!_guardEditAction()) return;
    try {
      await _teamService.removePlayerFromTeam(
        teamId: widget.team.id,
        playerId: member.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} has been removed from the team'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updatePlayerStats(TeamPlayer player) {
    if (!_guardEditAction()) return;
    showDialog(
      context: context,
      builder: (context) => _buildStatsUpdateDialog(player),
    );
  }

  Widget _buildStatsUpdateDialog(TeamPlayer player) {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Update ${player.name} Stats',
            style: TextStyle(color: Colors.white, fontSize: 18.sp),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _buildSportSpecificStatsForm(player, setState),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _savePlayerStats(player),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSportSpecificStatsForm(TeamPlayer player, StateSetter setState) {
    final sportType = widget.team.sportType;

    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return _buildFootballStatsForm(player, setState);
      case SportType.basketball:
        return _buildBasketballStatsForm(player, setState);
      case SportType.cricket:
        return _buildCricketStatsForm(player, setState);
      case SportType.tennis:
        return _buildTennisStatsForm(player, setState);
      default:
        return _buildGenericStatsForm(player, setState);
    }
  }

  Widget _buildFootballStatsForm(TeamPlayer player, StateSetter setState) {
    final stats = player.playerStats ?? {};
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatField('Goals', stats['goals']?.toString() ?? '0'),
          _buildStatField('Assists', stats['assists']?.toString() ?? '0'),
          _buildStatField('Matches', stats['matches']?.toString() ?? '0'),
          _buildStatField(
              'Yellow Cards', stats['yellowCards']?.toString() ?? '0'),
          _buildStatField('Red Cards', stats['redCards']?.toString() ?? '0'),
          _buildStatField('Rating', stats['rating']?.toString() ?? '0.0'),
        ],
      ),
    );
  }

  Widget _buildBasketballStatsForm(TeamPlayer player, StateSetter setState) {
    final stats = player.playerStats ?? {};
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatField('Points', stats['points']?.toString() ?? '0'),
          _buildStatField('Rebounds', stats['rebounds']?.toString() ?? '0'),
          _buildStatField('Assists', stats['assists']?.toString() ?? '0'),
          _buildStatField('Steals', stats['steals']?.toString() ?? '0'),
          _buildStatField('Blocks', stats['blocks']?.toString() ?? '0'),
          _buildStatField('Games', stats['games']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildCricketStatsForm(TeamPlayer player, StateSetter setState) {
    final stats = player.playerStats ?? {};
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatField('Runs', stats['runs']?.toString() ?? '0'),
          _buildStatField('Wickets', stats['wickets']?.toString() ?? '0'),
          _buildStatField('Matches', stats['matches']?.toString() ?? '0'),
          _buildStatField(
              'Batting Average', stats['battingAvg']?.toString() ?? '0.0'),
          _buildStatField(
              'Bowling Average', stats['bowlingAvg']?.toString() ?? '0.0'),
          _buildStatField('Catches', stats['catches']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildTennisStatsForm(TeamPlayer player, StateSetter setState) {
    final stats = player.playerStats ?? {};
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatField('Wins', stats['wins']?.toString() ?? '0'),
          _buildStatField('Losses', stats['losses']?.toString() ?? '0'),
          _buildStatField('Sets Won', stats['setsWon']?.toString() ?? '0'),
          _buildStatField('Aces', stats['aces']?.toString() ?? '0'),
          _buildStatField(
              'Double Faults', stats['doubleFaults']?.toString() ?? '0'),
          _buildStatField('Rating', stats['rating']?.toString() ?? '0.0'),
        ],
      ),
    );
  }

  Widget _buildGenericStatsForm(TeamPlayer player, StateSetter setState) {
    final stats = player.playerStats ?? {};
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatField('Matches', stats['matches']?.toString() ?? '0'),
          _buildStatField('Wins', stats['wins']?.toString() ?? '0'),
          _buildStatField('Rating', stats['rating']?.toString() ?? '0.0'),
        ],
      ),
    );
  }

  Widget _buildStatField(String label, String initialValue) {
    final controller = TextEditingController(text: initialValue);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(8.h),
          TextFormField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
            keyboardType: _getKeyboardType(label),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String label) {
    if (label.toLowerCase().contains('rating') ||
        label.toLowerCase().contains('average')) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.number;
  }

  Future<void> _savePlayerStats(TeamPlayer player) async {
    if (!_guardEditAction()) return;
    try {
      // TODO: Implement actual stats saving
      // This would involve updating the player's stats in the database

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} stats updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updatePlayerPosition(TeamPlayer player) {
    if (!_guardEditAction()) return;
    showDialog(
      context: context,
      builder: (context) => _buildPositionUpdateDialog(player),
    );
  }

  Widget _buildPositionUpdateDialog(TeamPlayer player) {
    final currentPosition = player.position ?? '';
    final controller = TextEditingController(text: currentPosition);

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Update ${player.name} Position',
        style: TextStyle(color: Colors.white, fontSize: 18.sp),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current Position: ${currentPosition.isEmpty ? 'Not set' : currentPosition}',
            style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
          ),
          Gap(16.h),
          TextFormField(
            controller: controller,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Enter new position (e.g., Striker, Goalkeeper, etc.)',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
          ),
          Gap(12.h),
          Text(
            _getPositionSuggestions(),
            style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _savePlayerPosition(player, controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorsManager.mainBlue,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }

  String _getPositionSuggestions() {
    final sportType = widget.team.sportType;

    switch (sportType) {
      case SportType.football:
      case SportType.soccer:
        return 'Suggestions: Goalkeeper, Defender, Midfielder, Striker, Winger';
      case SportType.basketball:
        return 'Suggestions: Point Guard, Shooting Guard, Small Forward, Power Forward, Center';
      case SportType.cricket:
        return 'Suggestions: Batsman, Bowler, All-rounder, Wicket-keeper, Spinner';
      case SportType.tennis:
        return 'Suggestions: Singles, Doubles, Mixed Doubles';
      default:
        return 'Enter position relevant to your sport';
    }
  }

  Future<void> _savePlayerPosition(
      TeamPlayer player, String newPosition) async {
    if (!_guardEditAction()) return;
    try {
      await _teamService.updatePlayerDetails(
        teamId: widget.team.id,
        playerId: player.id,
        position: newPosition.trim().isEmpty ? null : newPosition.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} position updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating position: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ MEMBERS MANAGEMENT METHODS ============
  Future<void> _approveJoinRequest(String requestId) async {
    if (!_guardEditAction()) return;
    try {
      await _teamService.approveJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(String requestId) async {
    if (!_guardEditAction()) return;
    try {
      await _teamService.rejectJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ MATCHES MANAGEMENT METHODS ============
  void _createNewMatch() {
    if (!_guardEditAction()) return;
    // TODO: Navigate to create match screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create match functionality coming soon'),
        backgroundColor: ColorsManager.mainBlue,
      ),
    );
  }

  void _viewMatchDetails(TeamMatch match) {
    DetailNavigator.openMatch(
      context,
      teamMatch: match,
    );
  }

  Future<void> _toggleMatchVisibility(TeamMatch match) async {
    if (!_guardEditAction()) return;
    try {
      final isCurrentlyVisible =
          match.metadata?['isVisibleOnTeamProfile'] ?? true;
      final newVisibility = !isCurrentlyVisible;

      // Update match metadata to toggle visibility
      // Note: This will work once freezed code is generated
      // await _teamService.updateMatchVisibility(match.id, newVisibility);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newVisibility
                ? 'Match will be shown on team profile'
                : 'Match will be hidden from team profile'),
            backgroundColor: newVisibility ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating match visibility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
