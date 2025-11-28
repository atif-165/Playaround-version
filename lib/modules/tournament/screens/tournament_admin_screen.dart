import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../services/cloudinary_service.dart';
import '../models/models.dart';
import '../models/tournament_match_model.dart';
import '../models/player_match_stats.dart' show TournamentTeam;
import '../services/tournament_service.dart';
import '../services/tournament_match_service.dart';
import '../../../theming/public_profile_theme.dart';
import '../services/tournament_team_service.dart';
import '../../team/models/team_model.dart';
import 'create_tournament_team_screen.dart';
import 'admin_player_stats_screen.dart';
import 'admin_leaderboard_screen.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';

const Color _adminScaffoldColor = PublicProfileTheme.backgroundColor;
const Color _adminCardColor = PublicProfileTheme.panelColor;
const LinearGradient _adminCardGradient = PublicProfileTheme.panelGradient;

class TournamentAdminScreen extends StatefulWidget {
  final TournamentModel tournament;

  const TournamentAdminScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentAdminScreen> createState() => _TournamentAdminScreenState();
}

class LeaderboardRow {
  final String teamId;
  final String teamName;
  final String captainName;
  final List<String> roster;
  final int wins;
  final int losses;
  final int draws;
  final int goalsFor;
  final int goalsAgainst;

  const LeaderboardRow({
    required this.teamId,
    required this.teamName,
    this.captainName = 'Captain',
    this.roster = const [],
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  LeaderboardRow copyWith({
    String? teamId,
    String? teamName,
    String? captainName,
    List<String>? roster,
    int? wins,
    int? losses,
    int? draws,
    int? goalsFor,
    int? goalsAgainst,
  }) {
    return LeaderboardRow(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      captainName: captainName ?? this.captainName,
      roster: roster ?? this.roster,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
    );
  }

  int get points => wins * 3 + draws;
  int get goalDifference => goalsFor - goalsAgainst;

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'captainName': captainName,
      'roster': roster,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
    };
  }

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      captainName: json['captainName'] as String? ?? 'Captain',
      roster: (json['roster'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
    );
  }
}

enum MatchesTabSegment { schedule, live }

class _CenterBadgeFormState {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController countdownSecondsController =
      TextEditingController();
  bool countdownEnabled = false;
  String countdownDirection = 'up';
  String _lastSignature = '';

  void syncWithMetadata(dynamic metadata) {
    Map<String, dynamic>? centerBadge;
    if (metadata is Map<String, dynamic>) {
      centerBadge = metadata;
    }
    final signature = _signature(centerBadge);
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    labelController.text = centerBadge?['label']?.toString() ?? '';
    valueController.text = centerBadge?['value']?.toString() ?? '';

    final countdown = centerBadge?['countdown'];
    if (countdown is Map<String, dynamic>) {
      countdownEnabled = countdown['enabled'] == true;
      countdownDirection =
          (countdown['direction'] as String?) ?? countdownDirection;
      final seconds = countdown['initialSeconds'];
      countdownSecondsController.text =
          seconds == null ? '' : seconds.toString();
    } else {
      countdownEnabled = false;
      countdownSecondsController.text = '';
    }
  }

  String _signature(Map<String, dynamic>? centerBadge) {
    if (centerBadge == null) return '';
    final countdown = centerBadge['countdown'];
    final enabled =
        countdown is Map<String, dynamic> ? countdown['enabled'] == true : false;
    final direction = countdown is Map<String, dynamic>
        ? (countdown['direction'] as String? ?? 'up')
        : 'up';
    final seconds = countdown is Map<String, dynamic>
        ? (countdown['initialSeconds']?.toString() ?? '')
        : '';

    return '${centerBadge['label'] ?? ''}|${centerBadge['value'] ?? ''}|$enabled|$direction|$seconds';
  }

  void dispose() {
    labelController.dispose();
    valueController.dispose();
    countdownSecondsController.dispose();
  }
}

class _TournamentAdminScreenState extends State<TournamentAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService();
  final TournamentMatchService _matchService = TournamentMatchService();
  final TournamentTeamService _tournamentTeamService = TournamentTeamService();
  final NotificationService _notificationService = NotificationService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  late TournamentModel _currentTournament;
  bool _isUploading = false;
  bool _isSavingBasicInfo = false;

  final _basicInfoFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();

  SportType? _selectedSport;
  TournamentStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  final Map<String, TournamentJoinRequest> _selectedIndividuals = {};

  MatchesTabSegment _matchesSegment = MatchesTabSegment.schedule;
  String? _scheduleTeam1Id;
  String? _scheduleTeam2Id;
  DateTime? _scheduleMatchDate;
  TimeOfDay? _scheduleMatchTime;
  final TextEditingController _scheduleRoundController = TextEditingController();
  final TextEditingController _scheduleMatchNumberController = TextEditingController();
  bool _isCreatingMatch = false;
  List<TournamentTeam> _cachedTeams = [];
  bool _isLoadingTeams = true;
  Object? _teamsError;
  StreamSubscription<List<TournamentTeam>>? _teamsSubscription;
  bool _seededLeaderboardFromTeams = false;

  Timer? _liveTicker;
  final Map<String, int> _liveCountdowns = {};
  final Map<String, DateTime> _lastCommentaryUpdates = {};
  bool _isLoadingLeaderboard = false;
  List<LeaderboardRow> _leaderboardRows = [];
  String? _profileImageUrlOverride;
  String? _bannerImageUrlOverride;
  final Map<String, TextEditingController> _liveCommentaryControllers = {};
  final Map<String, _CenterBadgeFormState> _centerBadgeForms =
      <String, _CenterBadgeFormState>{};

  Color get _accentColor => ColorsManager.primary;

  BoxDecoration _cardDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: _adminCardGradient,
      borderRadius: BorderRadius.circular(radius.r),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  void _updateCachedTeams(List<TournamentTeam> teams) {
    final merged = <String, TournamentTeam>{
      for (final team in teams) team.id: team,
    };

    for (final row in _leaderboardRows) {
      if (row.teamId.isEmpty || merged.containsKey(row.teamId)) continue;
      merged[row.teamId] = TournamentTeam(
        id: row.teamId,
        tournamentId: _currentTournament.id,
        name: row.teamName,
        playerNames: row.roster,
        createdAt: DateTime.now(),
        createdBy: _currentTournament.organizerId,
      );
    }

    _cachedTeams = merged.values.toList();

    if (!_seededLeaderboardFromTeams &&
        _leaderboardRows.isEmpty &&
        _cachedTeams.isNotEmpty) {
      _leaderboardRows = _cachedTeams
          .map(
            (team) => LeaderboardRow(
              teamId: team.id,
              teamName: team.name,
              captainName: team.captainName ?? 'Captain',
              roster: team.playerNames,
            ),
          )
          .toList();
      _seededLeaderboardFromTeams = true;
    }
  }

  void _listenToTeams() {
    _teamsSubscription = _tournamentTeamService
        .getTeamsStream(_currentTournament.id)
        .listen(
      (teams) {
        if (!mounted) return;
        setState(() {
          _teamsError = null;
          _isLoadingTeams = false;
          _updateCachedTeams(teams);
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _teamsError = error;
          _isLoadingTeams = false;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _currentTournament = widget.tournament;
    _tabController = TabController(length: 4, vsync: this);
    _initializeBasicInfoControllers();
    _liveTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickLiveCountdowns(),
    );
    _loadLeaderboardFromMetadata();
    _listenToTeams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _aboutController.dispose();
    _locationController.dispose();
    _prizeController.dispose();
    _scheduleRoundController.dispose();
    _scheduleMatchNumberController.dispose();
    for (final controller in _liveCommentaryControllers.values) {
      controller.dispose();
    }
    for (final form in _centerBadgeForms.values) {
      form.dispose();
    }
    _liveTicker?.cancel();
    _teamsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _adminScaffoldColor,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 240.h,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final collapsedHeight = MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      12.h;
                  final isCollapsed =
                      constraints.biggest.height <= collapsedHeight;
                  return _buildHeroHeader(isCollapsed);
                },
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(60.h),
                child: _buildAdminTabBar(),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBasicInfoTab(),
              _buildRequestsTab(),
              _buildMatchesTab(),
              _buildLeaderboardTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool isCollapsed) {
    final coverImage =
        _bannerImageUrlOverride ?? _currentTournament.bannerImageUrl;
    final profileImage =
        _profileImageUrlOverride ?? _currentTournament.profileImageUrl;
    final statusLabel = _currentTournament.status.name.toUpperCase();
    final matchCount =
        _currentTournament.metadata?['matchesCount']?.toString() ?? '--';
    final teamsCount =
        _currentTournament.metadata?['teamsCount']?.toString() ?? '--';

    return Container(
      decoration: const BoxDecoration(
        gradient: PublicProfileTheme.backgroundGradient,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverImage != null)
            Opacity(
              opacity: 0.35,
              child: Image.network(
                coverImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: _adminCardGradient,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: isCollapsed ? 12.h : 32.h,
                bottom: 16.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: isCollapsed
                        ? _buildCollapsedHeroSummary()
                        : SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            physics: const BouncingScrollPhysics(),
                            child: _buildExpandedHeroSummary(
                              profileImage: profileImage,
                              statusLabel: statusLabel,
                              teamsCount: teamsCount,
                              matchCount: matchCount,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedHeroSummary() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tournament Admin',
          style: TextStyles.font13White400Weight,
        ),
        Gap(4.h),
        Text(
          _currentTournament.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.font18White600Weight,
        ),
      ],
    );
  }

  Widget _buildExpandedHeroSummary({
    required String? profileImage,
    required String statusLabel,
    required String teamsCount,
    required String matchCount,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Admin',
          style: TextStyles.font14Grey400Weight.copyWith(
            color: Colors.white70,
          ),
        ),
        Gap(6.h),
        Text(
          _currentTournament.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.font24WhiteBold,
        ),
        Gap(14.h),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: profileImage != null
                  ? Image.network(
                      profileImage,
                      width: 56.w,
                      height: 56.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildProfilePlaceholder(),
                    )
                  : _buildProfilePlaceholder(),
            ),
            Gap(14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroChip(
                    icon: Icons.sports,
                    label: _currentTournament.sportType.displayName,
                  ),
                  Gap(6.h),
                  _buildHeroChip(
                    icon: Icons.flag,
                    label: statusLabel,
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildHeroStatChip(
              icon: Icons.groups,
              label: 'Teams',
              value: teamsCount,
            ),
            _buildHeroStatChip(
              icon: Icons.event_available,
              label: 'Matches',
              value: matchCount,
            ),
            if (_currentTournament.location != null)
              _buildHeroStatChip(
                icon: Icons.place,
                label: 'Location',
                value: _currentTournament.location!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(
        Icons.emoji_events,
        color: Colors.white70,
        size: 24.sp,
      ),
    );
  }

  Widget _buildHeroChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white24),
      ),
    child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.white),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12White500Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18.sp, color: Colors.white70),
          Gap(8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyles.font16White600Weight,
              ),
              Text(
                label,
                style: TextStyles.font11Grey400Weight
                    .copyWith(color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTabBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: _accentColor,
            indicatorWeight: 3,
            isScrollable: true,
            labelStyle: TextStyles.font14DarkBlue600Weight.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Basic Info'),
              Tab(text: 'Requests'),
              Tab(text: 'Matches'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
      ),
    );
  }

  // ============ BASIC INFO TAB ============
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _basicInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            Gap(24.h),
            _buildEditableInfoCard(),
            Gap(24.h),
            _buildTournamentInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Images',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(16.h),

          // Profile Image
          _buildImageUploadItem(
            title: 'Profile Picture',
            imageUrl:
                _profileImageUrlOverride ?? _currentTournament.profileImageUrl,
            onUpload: () => _uploadImage(isProfile: true),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard() {
    final isCompact = MediaQuery.of(context).size.width < 640;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Details',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(16.h),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tournament Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          Gap(16.h),
          TextFormField(
            controller: _aboutController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'About / Description',
              border: OutlineInputBorder(),
            ),
          ),
          Gap(16.h),
          if (isCompact) ...[
            _buildSportDropdownField(),
            Gap(12.h),
            _buildStatusDropdownField(),
          ] else
          Row(
            children: [
                Expanded(child: _buildSportDropdownField()),
              Gap(12.w),
                Expanded(child: _buildStatusDropdownField()),
            ],
          ),
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  label: 'Start Date & Time',
                  value: _startDate,
                  onTap: () => _pickDateTime(isStart: true),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _buildDateSelector(
                  label: 'End Date & Time',
                  value: _endDate,
                  onTap: () => _pickDateTime(isStart: false),
                ),
              ),
            ],
          ),
          Gap(16.h),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'City / Location',
              border: OutlineInputBorder(),
            ),
          ),
          Gap(16.h),
          TextFormField(
            controller: _prizeController,
            decoration: const InputDecoration(
              labelText: 'Winning Prize (PKR)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          Gap(20.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSavingBasicInfo ? null : _saveBasicInfo,
              icon: _isSavingBasicInfo
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSavingBasicInfo ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.sp,
              ),
            ),
            Gap(6.h),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 16.sp),
                Gap(8.w),
                Expanded(
                  child: Text(
                    _formatDateTime(value),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportDropdownField() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<SportType>(
        value: _selectedSport,
        isExpanded: true,
        dropdownColor: _adminCardColor,
        decoration: const InputDecoration(
          labelText: 'Sport Category',
          border: OutlineInputBorder(),
        ),
        items: SportType.values
            .map(
              (sport) => DropdownMenuItem(
                value: sport,
                child: Text(sport.displayName),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedSport = value),
      ),
    );
  }

  Widget _buildStatusDropdownField() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<TournamentStatus>(
        value: _selectedStatus,
        isExpanded: true,
        dropdownColor: _adminCardColor,
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
        ),
        items: TournamentStatus.values
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(status.displayName),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedStatus = value),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select date';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initialDate = isStart
        ? _startDate ?? DateTime.now()
        : _endDate ?? _startDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (selectedDate == null) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null) return;

    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = combined;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(hours: 2));
        }
      } else {
        _endDate = combined;
      }
    });
  }

  Future<void> _saveBasicInfo() async {
    if (!_basicInfoFormKey.currentState!.validate()) return;
    setState(() => _isSavingBasicInfo = true);

    try {
      final prizeValue = double.tryParse(
        _prizeController.text.replaceAll(RegExp('[^0-9.]'), ''),
      );
      await _tournamentService.updateTournament(
        tournamentId: _currentTournament.id,
        name: _nameController.text.trim(),
        description: _aboutController.text.trim(),
        sportType: _selectedSport,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        winningPrize: prizeValue,
        metadata: {
          ...?_currentTournament.metadata,
          'winningPrizeLabel': _prizeController.text.trim(),
        },
      );

      setState(() {
        _currentTournament = _currentTournament.copyWith(
          name: _nameController.text.trim(),
          description: _aboutController.text.trim(),
          sportType: _selectedSport,
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
          winningPrize: prizeValue,
          metadata: {
            ...?_currentTournament.metadata,
            'winningPrizeLabel': _prizeController.text.trim(),
          },
        );
        _isSavingBasicInfo = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament info updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingBasicInfo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeBasicInfoControllers() {
    _nameController.text = _currentTournament.name;
    _aboutController.text = _currentTournament.description;
    _locationController.text = _currentTournament.location ?? '';
    _prizeController.text = _currentTournament.metadata?['winningPrizeLabel'] ??
        (_currentTournament.winningPrize?.toStringAsFixed(0) ?? '');
    _selectedSport = _currentTournament.sportType;
    _selectedStatus = _currentTournament.status;
    _startDate = _currentTournament.startDate;
    _endDate = _currentTournament.endDate;
    _profileImageUrlOverride = _currentTournament.profileImageUrl;
    _bannerImageUrlOverride = _currentTournament.bannerImageUrl;
  }

  void _tickLiveCountdowns() {
    if (_liveCountdowns.isEmpty) return;
    final updated = Map<String, int>.from(_liveCountdowns);
    updated.updateAll((key, value) => value > 0 ? value - 1 : 0);
    setState(() {
      _liveCountdowns
        ..clear()
        ..addAll(updated);
    });
  }

  Widget _buildImageUploadItem({
    required String title,
    String? imageUrl,
    required VoidCallback onUpload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.font14Grey400Weight.copyWith(
            color: Colors.grey[400],
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: Colors.grey[800],
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : Icon(
                      Icons.image,
                      color: Colors.grey[600],
                      size: 40.sp,
                    ),
            ),
            Gap(16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : onUpload,
                icon: _isUploading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadImage({required bool isProfile}) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final imageFile = File(pickedFile.path);
      final folder = isProfile ? 'tournaments/profiles' : 'tournaments/banners';
      final imageUrl =
          await _cloudinaryService.uploadImage(imageFile, folder: folder);

      await _tournamentService.updateTournament(
        tournamentId: _currentTournament.id,
        profileImageUrl: isProfile ? imageUrl : null,
        bannerImageUrl: !isProfile ? imageUrl : null,
      );

      if (mounted) {
        setState(() {
          if (isProfile) {
            _profileImageUrlOverride = imageUrl;
          } else {
            _bannerImageUrlOverride = imageUrl;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isProfile ? 'Profile' : 'Banner'} image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildTournamentInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Information',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(16.h),
          _buildInfoRow('Status', _currentTournament.status.displayName),
          _buildInfoRow('Format', _currentTournament.format.displayName),
          _buildInfoRow('Sport', _currentTournament.sportType.displayName),
          if (_startDate != null)
            _buildInfoRow(
              'Start Date',
              DateFormat('MMM dd, yyyy').format(_startDate!),
            ),
          if (_endDate != null)
            _buildInfoRow(
              'End Date',
              DateFormat('MMM dd, yyyy').format(_endDate!),
            ),
          if (_currentTournament.location != null)
            _buildInfoRow('Location', _currentTournament.location!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============ REQUESTS TAB ============
  Widget _buildRequestsTab() {
    return StreamBuilder<List<TournamentTeam>>(
      stream: _tournamentTeamService.getTeamsStream(_currentTournament.id),
      builder: (context, teamsSnapshot) {
        if (teamsSnapshot.hasData) {
          _updateCachedTeams(teamsSnapshot.data!);
        }

        return StreamBuilder<List<TournamentJoinRequest>>(
          stream: _matchService
              .getIndividualJoinRequestsStream(_currentTournament.id),
          builder: (context, individualsSnapshot) {
            if (individualsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (individualsSnapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load player requests',
                  style: TextStyle(color: Colors.red, fontSize: 16.sp),
                ),
              );
            }

            return StreamBuilder<List<TournamentJoinRequest>>(
              stream: _matchService
                  .getTeamJoinRequestsStream(_currentTournament.id),
              builder: (context, teamsRequestsSnapshot) {
                if (teamsRequestsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (teamsRequestsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load team requests',
                      style: TextStyle(color: Colors.red, fontSize: 16.sp),
                    ),
                  );
                }

                final individualRequests = individualsSnapshot.data ?? [];
                final teamRequests = teamsRequestsSnapshot.data ?? [];

                if (individualRequests.isEmpty && teamRequests.isEmpty) {
                  return _buildEmptyJoinRequestsState();
                }

                return ListView(
                  padding: EdgeInsets.all(16.w),
                  children: [
                    if (_selectedIndividuals.isNotEmpty)
                      _buildSelectionToolbar(_cachedTeams),
                    _buildJoinRequestSection(
                      title: 'Independent Players',
                      requests: individualRequests,
                      isTeamSection: false,
                    ),
                    Gap(24.h),
                    _buildJoinRequestSection(
                      title: 'Teams',
                      requests: teamRequests,
                      isTeamSection: true,
                    ),
                    Gap(24.h),
                    _buildTeamManagementCard(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyJoinRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add_outlined,
            size: 72.sp,
            color: Colors.grey,
          ),
          Gap(16.h),
          Text(
            'No join requests yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Text(
            'Share your tournament link to invite teams and independent players.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(24.h),
          _buildTeamManagementCard(),
        ],
      ),
    );
  }

  Widget _buildJoinRequestSection({
    required String title,
    required List<TournamentJoinRequest> requests,
    required bool isTeamSection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(12.h),
        if (requests.isEmpty)
          _buildJoinSectionEmptyState(
            isTeamSection
                ? 'No team requests yet.'
                : 'No independent player requests yet.',
          )
        else
          ...requests.map(
            (request) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: isTeamSection
                  ? _buildTeamJoinRequestCard(request)
                  : _buildIndividualJoinRequestCard(request),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionToolbar(List<TournamentTeam> teams) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedIndividuals.length} player(s) selected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              ElevatedButton.icon(
                onPressed: _promptCreateTeamFromSelection,
                icon: const Icon(Icons.group_add),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: teams.isEmpty
                    ? null
                    : () => _promptAddToExistingTeam(teams),
                icon: const Icon(Icons.group_work),
                label: const Text('Add to Team'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _promptCreateTeamFromSelection() async {
    if (_selectedIndividuals.isEmpty) return;
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team from Players'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _createTeamFromSelection(nameController.text.trim());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTeamFromSelection(String teamName) async {
    try {
      final playerIds = _selectedIndividuals.values
          .map((request) => request.requesterId)
          .where((id) => id.isNotEmpty)
          .toList();
      final playerNames =
          _selectedIndividuals.values.map((request) => request.requesterName).toList();

      if (playerIds.isEmpty) {
        throw Exception('Selected players are missing user IDs');
      }

      await _tournamentTeamService.createTeam(
        tournamentId: _currentTournament.id,
        name: teamName,
        playerIds: playerIds,
        playerNames: playerNames,
      );

      await Future.wait(
        _selectedIndividuals.values.map(
          (request) => _matchService.reviewJoinRequest(
            request: request,
            accept: true,
          ),
        ),
      );

      _clearSelection();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "$teamName" created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _promptAddToExistingTeam(List<TournamentTeam> teams) async {
    if (teams.isEmpty || _selectedIndividuals.isEmpty) return;
    TournamentTeam? selectedTeam;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Players to Team',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(12.h),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<TournamentTeam>(
              value: selectedTeam,
                dropdownColor: _adminCardColor,
                isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Team',
                border: OutlineInputBorder(),
              ),
              items: teams
                  .map(
                    (team) => DropdownMenuItem(
                      value: team,
                      child: Text(
                        team.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (team) => selectedTeam = team,
              ),
            ),
            Gap(16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedTeam == null) return;
                  Navigator.pop(context);
                  await _addSelectionToTeam(selectedTeam!);
                },
                child: const Text('Add Players'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSelectionToTeam(TournamentTeam team) async {
    try {
      final playerIds = _selectedIndividuals.values
          .map((request) => request.requesterId)
          .where((id) => id.isNotEmpty)
          .toList();
      final playerNames =
          _selectedIndividuals.values.map((request) => request.requesterName).toList();

      if (playerIds.isEmpty) {
        throw Exception('Selected players are missing user IDs');
      }

      await _tournamentTeamService.addPlayersToTeam(
        teamId: team.id,
        playerIds: playerIds,
        playerNames: playerNames,
      );

      await Future.wait(
        _selectedIndividuals.values.map(
          (request) => _matchService.reviewJoinRequest(
            request: request,
            accept: true,
          ),
        ),
      );

      for (final request in _selectedIndividuals.values) {
        await _notifyTeamOnAddition(team, request);
      }

      _clearSelection();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Players added to ${team.name}. The team has been notified.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add players: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _notifyTeamOnAddition(
    TournamentTeam team,
    TournamentJoinRequest request,
  ) async {
    final captainId = team.captainId ?? team.createdBy;
    if (captainId == null) return;

    try {
      await _notificationService.createNotification(
        userId: captainId,
        type: NotificationType.tournamentTeamUpdate,
        title: 'New Player Added',
        message: '${request.requesterName} has joined ${team.name}',
        data: {
          'tournamentId': _currentTournament.id,
          'teamId': team.id,
          'playerId': request.requesterId,
          'playerName': request.requesterName,
        },
      );
    } catch (_) {
      // Best effort notification
    }
  }

  void _toggleIndividualSelection(TournamentJoinRequest request) {
    setState(() {
      if (_selectedIndividuals.containsKey(request.id)) {
        _selectedIndividuals.remove(request.id);
      } else {
        _selectedIndividuals[request.id] = request;
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIndividuals.clear());
  }


  Widget _buildJoinSectionEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 20.sp),
          Gap(8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamManagementCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 56.sp,
            color: Colors.grey[300],
          ),
          Gap(12.h),
          Text(
            'Team Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Text(
            'Create balanced squads from accepted player requests or onboard existing teams.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(20.h),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTournamentTeamScreen(
                    tournamentId: _currentTournament.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualJoinRequestCard(TournamentJoinRequest request) {
    final formEntries = request.formResponses.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .where((entry) => entry.key.toLowerCase() != 'bio')
        .toList();

    final isSelected = _selectedIndividuals.containsKey(request.id);

    return GestureDetector(
      onLongPress: () => _toggleIndividualSelection(request),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withOpacity(0.18)
              : _adminCardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? _accentColor
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundImage: request.requesterProfileUrl != null
                    ? NetworkImage(request.requesterProfileUrl!)
                    : null,
                child: request.requesterProfileUrl == null
                    ? Text(
                        request.requesterName.isNotEmpty
                            ? request.requesterName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20.sp,
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
                      request.requesterName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (request.sport != null)
                      Text(
                        request.sport!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleIndividualSelection(request),
                activeColor: _accentColor,
              ),
            ],
          ),
          Gap(12.h),
          if (request.position != null)
            _buildRequestDetailRow('Preferred Position', request.position!),
          if (request.skillLevel != null)
            _buildRequestDetailRow(
              'Skill Level',
              '${request.skillLevel}/10',
            ),
          if (request.bio != null && request.bio!.trim().isNotEmpty) ...[
            Gap(8.h),
            Text(
              request.bio!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13.sp,
              ),
            ),
          ],
          if (formEntries.isNotEmpty) ...[
            Gap(12.h),
            ...formEntries.map(
              (entry) => _buildRequestDetailRow(
                entry.key,
                entry.value.toString(),
              ),
            ),
          ],
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewRequest(request, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewRequest(request, false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTeamJoinRequestCard(TournamentJoinRequest request) {
    final formEntries = request.formResponses.entries
        .where((entry) =>
            entry.value != null && entry.value.toString().trim().isNotEmpty)
        .toList();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundImage: request.teamLogoUrl != null
                    ? NetworkImage(request.teamLogoUrl!)
                    : null,
                child: request.teamLogoUrl == null
                    ? Text(
                        request.teamName != null && request.teamName!.isNotEmpty
                            ? request.teamName![0].toUpperCase()
                            : 'T',
                        style: TextStyle(
                          fontSize: 20.sp,
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
                      request.teamName ?? 'Unnamed Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Requested by ${request.requesterName}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          if (request.bio != null && request.bio!.trim().isNotEmpty)
            _buildRequestDetailRow('Team Bio', request.bio!),
          if (formEntries.isNotEmpty) ...[
            Gap(8.h),
            ...formEntries.map(
              (entry) => _buildRequestDetailRow(
                entry.key,
                entry.value.toString(),
              ),
            ),
          ],
          Gap(16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewRequest(request, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _reviewRequest(request, false),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewRequest(
      TournamentJoinRequest request, bool accept) async {
    try {
      await _matchService.reviewJoinRequest(
        request: request,
        accept: accept,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${request.isTeamRequest ? 'Team' : 'Player'} request ${accept ? 'accepted' : 'rejected'} successfully!'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to review request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ MATCHES TAB ============
  Widget _buildMatchesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: MatchesTabSegment.values.map((segment) {
              final isSelected = _matchesSegment == segment;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: ChoiceChip(
                    label: Text(
                      segment == MatchesTabSegment.schedule
                          ? 'Schedule'
                          : 'Live Matches',
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _matchesSegment = segment),
                    selectedColor: _accentColor,
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: _adminCardColor.withOpacity(0.6),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _matchesSegment == MatchesTabSegment.schedule
              ? _buildScheduleMatchesView()
              : _buildLiveMatchesView(),
        ),
      ],
    );
  }

  // ============ LEADERBOARD TAB ============
  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaderboardRows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64.sp, color: Colors.grey),
            Gap(12.h),
            Text(
              'No leaderboard data yet',
              style: TextStyle(color: Colors.grey, fontSize: 16.sp),
            ),
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: _showAddLeaderboardEntryDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Team'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _leaderboardRows.length,
            itemBuilder: (context, index) {
              final entry = _leaderboardRows[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _adminCardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: index == 0
                        ? Colors.amber
                        : Colors.grey[700]!,
                    width: index == 0 ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${index + 1}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Gap(8.w),
                        Expanded(
                          child: Text(
                            entry.teamName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditLeaderboardEntryDialog(entry, index);
                            } else if (value == 'remove') {
                              _removeLeaderboardEntry(index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Gap(8.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 8.h,
                      children: [
                        _buildLeaderboardChip('Pts', entry.points, Colors.green),
                        _buildLeaderboardChip('W', entry.wins, Colors.blue),
                        _buildLeaderboardChip('L', entry.losses, Colors.red),
                        _buildLeaderboardChip('D', entry.draws, Colors.orange),
                        _buildLeaderboardChip(
                          'GD',
                          entry.goalDifference,
                          entry.goalDifference >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    Gap(8.h),
                    Text(
                      'Captain: ${entry.captainName}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                    ),
                    if (entry.roster.isNotEmpty) ...[
                      Gap(4.h),
                      Text(
                        'Roster: ${entry.roster.take(6).join(', ')}'
                        '${entry.roster.length > 6 ? '...' : ''}',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddLeaderboardEntryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Team'),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveLeaderboardRows,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Leaderboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardChip(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showAddLeaderboardEntryDialog() async {
    if (_cachedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create tournament teams before adding leaderboard rows.'),
        ),
      );
      return;
    }

    TournamentTeam? selectedTeam;
    final winsController = TextEditingController(text: '0');
    final lossesController = TextEditingController(text: '0');
    final drawsController = TextEditingController(text: '0');
    final goalsForController = TextEditingController(text: '0');
    final goalsAgainstController = TextEditingController(text: '0');
    final captainController = TextEditingController();
    final rosterController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Leaderboard Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TournamentTeam>(
                decoration: const InputDecoration(
                  labelText: 'Team',
                  border: OutlineInputBorder(),
                ),
                items: _cachedTeams
                    .map(
                      (team) => DropdownMenuItem(
                        value: team,
                        child: Text(team.name),
                      ),
                    )
                    .toList(),
                onChanged: (team) => selectedTeam = team,
              ),
              Gap(12.h),
              _buildNumberRow(
                winsController: winsController,
                lossesController: lossesController,
                drawsController: drawsController,
              ),
              Gap(12.h),
              _buildGoalsRow(
                goalsForController: goalsForController,
                goalsAgainstController: goalsAgainstController,
              ),
              Gap(12.h),
              TextField(
                controller: captainController,
                decoration: const InputDecoration(
                  labelText: 'Captain Name',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: rosterController,
                decoration: const InputDecoration(
                  labelText: 'Roster (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedTeam == null) return;
              setState(() {
                _leaderboardRows.add(
                  LeaderboardRow(
                    teamId: selectedTeam!.id,
                    teamName: selectedTeam!.name,
                    wins: int.tryParse(winsController.text) ?? 0,
                    losses: int.tryParse(lossesController.text) ?? 0,
                    draws: int.tryParse(drawsController.text) ?? 0,
                    goalsFor: int.tryParse(goalsForController.text) ?? 0,
                    goalsAgainst: int.tryParse(goalsAgainstController.text) ?? 0,
                    captainName: captainController.text.trim().isEmpty
                        ? 'Captain'
                        : captainController.text.trim(),
                    roster: rosterController.text
                        .split(',')
                        .map((name) => name.trim())
                        .where((name) => name.isNotEmpty)
                        .toList(),
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow({
    required TextEditingController winsController,
    required TextEditingController lossesController,
    required TextEditingController drawsController,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: winsController,
            decoration: const InputDecoration(
              labelText: 'Wins',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: TextField(
            controller: lossesController,
            decoration: const InputDecoration(
              labelText: 'Losses',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: TextField(
            controller: drawsController,
            decoration: const InputDecoration(
              labelText: 'Draws',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsRow({
    required TextEditingController goalsForController,
    required TextEditingController goalsAgainstController,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: goalsForController,
            decoration: const InputDecoration(
              labelText: 'Goals For',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: TextField(
            controller: goalsAgainstController,
            decoration: const InputDecoration(
              labelText: 'Goals Against',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _showEditLeaderboardEntryDialog(LeaderboardRow row, int index) {
    final winsController = TextEditingController(text: row.wins.toString());
    final lossesController = TextEditingController(text: row.losses.toString());
    final drawsController = TextEditingController(text: row.draws.toString());
    final goalsForController =
        TextEditingController(text: row.goalsFor.toString());
    final goalsAgainstController =
        TextEditingController(text: row.goalsAgainst.toString());
    final captainController = TextEditingController(text: row.captainName);
    final rosterController =
        TextEditingController(text: row.roster.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${row.teamName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumberRow(
                winsController: winsController,
                lossesController: lossesController,
                drawsController: drawsController,
              ),
              Gap(12.h),
              _buildGoalsRow(
                goalsForController: goalsForController,
                goalsAgainstController: goalsAgainstController,
              ),
              Gap(12.h),
              TextField(
                controller: captainController,
                decoration: const InputDecoration(
                  labelText: 'Captain Name',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: rosterController,
                decoration: const InputDecoration(
                  labelText: 'Roster (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _leaderboardRows[index] = row.copyWith(
                  wins: int.tryParse(winsController.text) ?? row.wins,
                  losses: int.tryParse(lossesController.text) ?? row.losses,
                  draws: int.tryParse(drawsController.text) ?? row.draws,
                  goalsFor: int.tryParse(goalsForController.text) ?? row.goalsFor,
                  goalsAgainst: int.tryParse(goalsAgainstController.text) ??
                      row.goalsAgainst,
                  captainName: captainController.text.trim().isEmpty
                      ? row.captainName
                      : captainController.text.trim(),
                  roster: rosterController.text
                      .split(',')
                      .map((name) => name.trim())
                      .where((name) => name.isNotEmpty)
                      .toList(),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeLeaderboardEntry(int index) {
    setState(() => _leaderboardRows.removeAt(index));
  }

  Future<void> _saveLeaderboardRows() async {
    try {
      setState(() => _isLoadingLeaderboard = true);
      final leaderboardJson =
          _leaderboardRows.map((row) => row.toJson()).toList();
      final updatedMetadata = {
        ...?_currentTournament.metadata,
        'manualLeaderboard': leaderboardJson,
      };
      await _tournamentService.updateTournament(
        tournamentId: _currentTournament.id,
        metadata: updatedMetadata,
      );
      setState(() {
        _currentTournament =
            _currentTournament.copyWith(metadata: updatedMetadata);
        _isLoadingLeaderboard = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leaderboard saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLeaderboard = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save leaderboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadLeaderboardFromMetadata() {
    final raw = _currentTournament.metadata?['manualLeaderboard']
            as List<dynamic>? ??
        [];
    _leaderboardRows = raw
        .map((entry) => LeaderboardRow.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ))
        .toList();
  }

  Widget _buildMatchesErrorState(String title, Object? error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24.w),
        padding: EdgeInsets.all(20.w),
        decoration: _cardDecoration(radius: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 36.sp),
            Gap(12.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              Gap(8.h),
              Text(
                error.toString(),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleMatchesView() {
    if (_isLoadingTeams) {
      return _buildMatchesPlaceholder('Loading teams for this tournament...');
    }

    if (_teamsError != null) {
      return _buildMatchesErrorState(
        'Unable to load tournament teams',
        _teamsError,
      );
    }

    if (_cachedTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 72.sp,
                color: Colors.grey[400],
              ),
              Gap(16.h),
              Text(
                'No Teams Created Yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(8.h),
              Text(
                'Create teams before scheduling matches.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(24.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTournamentTeamScreen(
                        tournamentId: _currentTournament.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.group_add),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<TournamentMatch>>(
      stream: _matchService.getTournamentMatchesStream(_currentTournament.id),
      builder: (context, matchSnapshot) {
        if (matchSnapshot.hasError) {
          return _buildMatchesErrorState(
            'Unable to load matches',
            matchSnapshot.error,
          );
        }

        final matches = matchSnapshot.data;
        if (matches == null) {
          return _buildMatchesPlaceholder('Fetching latest schedule...');
        }

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildScheduleForm(matches),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_score_outlined,
                            size: 64.sp,
                            color: Colors.grey,
                          ),
                          Gap(16.h),
                          Text(
                            'No matches scheduled yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final match = matches[index];
                            return _buildMatchCard(
                              match,
                              isScheduleContext: true,
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveMatchesView() {
    return StreamBuilder<List<TournamentMatch>>(
      stream: _matchService.getTournamentMatchesStream(_currentTournament.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMatchesErrorState(
            'Unable to load live matches',
            snapshot.error,
          );
        }

        final matches = snapshot.data;
        if (matches == null) {
          return _buildMatchesPlaceholder('Fetching live match data...');
        }
        if (matches.isEmpty) {
          return _buildMatchesPlaceholder(
            'No matches have been scheduled yet.',
          );
        }

        final liveMatches = matches
            .where((m) => m.status == TournamentMatchStatus.live)
            .toList();
        final upcomingMatches = matches
            .where((m) => m.status == TournamentMatchStatus.scheduled)
            .toList();
        final completedMatches = matches
            .where((m) => m.status == TournamentMatchStatus.completed)
            .toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _liveCountdowns
                .removeWhere((key, _) => liveMatches.every((m) => m.id != key));
            for (final match in liveMatches) {
              _liveCountdowns.putIfAbsent(match.id, () => 30);
            }
          });
        });

        return ListView(
          padding: EdgeInsets.all(16.w),
              children: [
            _buildMatchesSection(
              title: 'Live matches',
              matches: liveMatches,
              emptyMessage: 'No live matches running right now.',
              showLiveTools: true,
                ),
            Gap(24.h),
            _buildMatchesSection(
              title: 'Upcoming matches',
              matches: upcomingMatches,
              emptyMessage: 'No upcoming fixtures scheduled.',
            ),
            Gap(24.h),
            _buildMatchesSection(
              title: 'Completed matches',
              matches: completedMatches,
              emptyMessage: 'No completed results yet.',
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleForm(List<TournamentMatch> existingMatches) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule a Match',
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _scheduleRoundController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Round/Stage',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'e.g., Group Stage, Quarter Final',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: TextFormField(
                  controller: _scheduleMatchNumberController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Match Number',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: '1',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gap(12.h),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
            value: _scheduleTeam1Id,
              isExpanded: true,
              dropdownColor: _adminCardColor,
            decoration: const InputDecoration(
              labelText: 'Team 1',
              border: OutlineInputBorder(),
            ),
            items: _cachedTeams
                .map(
                  (team) => DropdownMenuItem(
                    value: team.id,
                    child: Text(team.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _scheduleTeam1Id = value),
            ),
          ),
          Gap(12.h),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
            value: _scheduleTeam2Id,
              isExpanded: true,
              dropdownColor: _adminCardColor,
            decoration: const InputDecoration(
              labelText: 'Team 2',
              border: OutlineInputBorder(),
            ),
            items: _cachedTeams
                .where((team) => team.id != _scheduleTeam1Id)
                .map(
                  (team) => DropdownMenuItem(
                    value: team.id,
                    child: Text(team.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _scheduleTeam2Id = value),
            ),
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  label: 'Match Date',
                  value: _scheduleMatchDate,
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          _scheduleMatchDate ?? DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      setState(() => _scheduleMatchDate = selectedDate);
                    }
                  },
                ),
              ),
              Gap(12.w),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _scheduleMatchTime ?? const TimeOfDay(hour: 18, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _scheduleMatchTime = time);
                    }
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match Time',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                        Gap(6.h),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white),
                            Gap(8.w),
                            Text(
                              _scheduleMatchTime != null
                                  ? _scheduleMatchTime!.format(context)
                                  : 'Select time',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreatingMatch
                  ? null
                  : () => _handleScheduleMatch(existingMatches),
              icon: _isCreatingMatch
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_isCreatingMatch ? 'Scheduling...' : 'Schedule Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScheduleMatch(List<TournamentMatch> existingMatches) async {
    if (_scheduleTeam1Id == null ||
        _scheduleTeam2Id == null ||
        _scheduleMatchDate == null ||
        _scheduleMatchTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both teams, date, and time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_scheduleTeam1Id == _scheduleTeam2Id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose two different teams.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final date = _scheduleMatchDate!;
    final time = _scheduleMatchTime!;
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final overlap = existingMatches.any((match) =>
        (match.scheduledTime.difference(scheduledDateTime).abs() <
            const Duration(minutes: 30)));

    if (overlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Another match is already scheduled around this time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final team1 =
        _cachedTeams.firstWhere((team) => team.id == _scheduleTeam1Id);
    final team2 =
        _cachedTeams.firstWhere((team) => team.id == _scheduleTeam2Id);

    setState(() => _isCreatingMatch = true);

    try {
      final matchId = await _matchService.createMatch(
        tournamentId: _currentTournament.id,
        tournamentName: _currentTournament.name,
        sportType: _currentTournament.sportType,
        team1: TeamMatchScore(
          teamId: team1.id,
          teamName: team1.name,
          teamLogoUrl: team1.logoUrl,
        ),
        team2: TeamMatchScore(
          teamId: team2.id,
          teamName: team2.name,
          teamLogoUrl: team2.logoUrl,
        ),
        matchNumber: _scheduleMatchNumberController.text.trim().isNotEmpty
            ? _scheduleMatchNumberController.text.trim()
            : 'Match ${existingMatches.length + 1}',
        round: _scheduleRoundController.text.trim().isNotEmpty
            ? _scheduleRoundController.text.trim()
            : 'Group Stage',
        scheduledTime: scheduledDateTime,
        venueName: _currentTournament.venueName,
      );

      await Future.wait([
        _notifyTeamsOfScheduledMatch(
          team1,
          team2,
          scheduledDateTime,
          matchId,
        ),
        _notifyTeamsOfScheduledMatch(
          team2,
          team1,
          scheduledDateTime,
          matchId,
        ),
      ]);

      setState(() {
        _scheduleTeam1Id = null;
        _scheduleTeam2Id = null;
        _scheduleMatchDate = null;
        _scheduleMatchTime = null;
        _scheduleRoundController.clear();
        _scheduleMatchNumberController.clear();
        _isCreatingMatch = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match scheduled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingMatch = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule match: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _notifyTeamsOfScheduledMatch(
    TournamentTeam team,
    TournamentTeam opponent,
    DateTime scheduledDateTime,
    String matchId,
  ) async {
    final recipients = <String>{};
    final captainId = team.captainId ?? '';
    final createdBy = team.createdBy ?? '';

    if (captainId.isNotEmpty) recipients.add(captainId);
    if (createdBy.isNotEmpty) recipients.add(createdBy);
    recipients.addAll(
      team.playerIds.where((id) => id.trim().isNotEmpty),
    );

    if (recipients.isEmpty) return;

    final formattedDate =
        DateFormat('MMM dd, yyyy • h:mm a').format(scheduledDateTime);

    for (final userId in recipients) {
      try {
        await _notificationService.createNotification(
          userId: userId,
          type: NotificationType.matchScheduled,
          title: 'Match scheduled',
          message:
              '${team.name} vs ${opponent.name} is set for $formattedDate. Get ready!',
          data: {
            'tournamentId': _currentTournament.id,
            'matchId': matchId,
            'teamId': team.id,
            'opponentTeamId': opponent.id,
          },
        );
      } catch (_) {
        // Best-effort notification; ignore failures per recipient
      }
    }
  }

  Widget _buildLiveCountdown(TournamentMatch match) {
    final remaining = _liveCountdowns[match.id] ?? 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score refresh in ${remaining}s',
          style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
        ),
        Gap(4.h),
        LinearProgressIndicator(
          value: remaining / 30,
          color: Colors.red,
          backgroundColor: Colors.grey[800],
        ),
      ],
    );
  }

  Widget _buildLiveCommentaryComposer(TournamentMatch match) {
    final controller = _liveCommentaryControllers.putIfAbsent(
      match.id,
      () => TextEditingController(),
    );
    final cooldown = _getCommentaryCooldown(match.id);
    final canPost = cooldown.inSeconds <= 0;
    final recent = List<CommentaryEntry>.from(match.commentary)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latest = recent.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick commentary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!canPost)
              Text(
                'Wait ${_formatDuration(cooldown)}',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12.sp,
                ),
              ),
          ],
        ),
        Gap(8.h),
        if (latest.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: latest.map((entry) {
                final formattedTime =
                    DateFormat('MMM d • h:mm a').format(entry.timestamp);
                return Container(
                  margin: EdgeInsets.only(
                      bottom: identical(entry, latest.last) ? 0 : 10.h),
                  padding: EdgeInsets.only(bottom: identical(entry, latest.last) ? 0 : 10.h),
                  decoration: BoxDecoration(
                    border: identical(entry, latest.last)
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.mic_none_rounded,
                          size: 16.sp, color: Colors.white54),
                      Gap(8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.text,
                              style: TextStyles.font13White500Weight,
                            ),
                            Gap(4.h),
                            Text(
                              entry.minute?.isNotEmpty == true
                                  ? '${entry.minute} • $formattedTime'
                                  : formattedTime,
                              style: TextStyles.font11Grey400Weight.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        if (latest.isNotEmpty) Gap(12.h),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add quick commentary update',
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canPost ? () => _postLiveCommentary(match) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: Text(canPost ? 'Post update' : 'Please wait...'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterBadgeEditor(TournamentMatch match) {
    final form = _getCenterBadgeForm(match);
    final previewLabel = form.labelController.text.isNotEmpty
        ? form.labelController.text.trim()
        : match.round ?? match.matchNumber;
    final previewValue = form.valueController.text.isNotEmpty
        ? form.valueController.text.trim()
        : match.isLive
            ? '${match.team1.score}-${match.team2.score}'
            : DateFormat('h:mm a').format(match.scheduledTime);
    final previewCountdownSeconds =
        int.tryParse(form.countdownSecondsController.text.trim()) ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Center badge (score capsule)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(12.h),
          _buildCenterBadgePreview(
            previewLabel,
            previewValue,
            form.countdownEnabled,
            form.countdownDirection,
            previewCountdownSeconds,
          ),
          Gap(16.h),
          TextField(
            controller: form.labelController,
            decoration: const InputDecoration(
              labelText: 'Custom text',
              hintText: 'e.g. Championship Round',
              border: OutlineInputBorder(),
            ),
          ),
          Gap(12.h),
          TextField(
            controller: form.valueController,
            decoration: const InputDecoration(
              labelText: 'Value / number',
              hintText: 'e.g. 45′',
              border: OutlineInputBorder(),
            ),
          ),
          Gap(12.h),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show countdown beside value'),
            value: form.countdownEnabled,
            onChanged: (value) {
              setState(() {
                form.countdownEnabled = value;
              });
            },
          ),
          if (form.countdownEnabled) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: form.countdownDirection,
                    decoration: const InputDecoration(
                      labelText: 'Countdown direction',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'up',
                        child: Text('Increase over time'),
                      ),
                      DropdownMenuItem(
                        value: 'down',
                        child: Text('Decrease to zero'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => form.countdownDirection = value);
                    },
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: TextField(
                    controller: form.countdownSecondsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seconds',
                      hintText: 'e.g. 90',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          Gap(16.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _saveCenterBadge(match, form),
              icon: const Icon(Icons.save),
              label: const Text('Save center badge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterBadgePreview(
    String label,
    String value,
    bool countdownEnabled,
    String direction,
    int countdownSeconds,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary.withOpacity(0.9),
            ColorsManager.mainBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.isEmpty ? 'Preview label' : label,
            style: TextStyles.font12White500Weight.copyWith(
              color: Colors.white70,
            ),
          ),
          Gap(6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.isEmpty ? '--' : value,
                style: TextStyles.font18White600Weight,
              ),
              if (countdownEnabled) ...[
                Gap(8.w),
                Row(
                  children: [
                    Icon(
                      direction == 'down'
                          ? Icons.south
                          : Icons.north,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                    Gap(4.w),
                    Text(
                      _formatSecondsPreview(countdownSeconds),
                      style: TextStyles.font12White500Weight,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchAdminActions(TournamentMatch match) {
    final buttons = <Widget>[];

    if (match.isUpcoming) {
      buttons.add(
        _buildAdminPrimaryButton(
          label: 'Start Match',
          onPressed: () => _startMatch(match.id),
        ),
      );
    }

    if (match.isLive) {
      buttons.add(
        _buildAdminPrimaryButton(
          label: 'Update Score',
          onPressed: () => _showUpdateScoreDialog(
            match,
            onUpdated: () => _resetScoreCountdown(match.id),
          ),
        ),
      );
      buttons.add(
        _buildAdminPrimaryButton(
          label: 'End Match',
          backgroundColor: Colors.redAccent,
          onPressed: () => _showEndMatchDialog(match),
        ),
      );
    }

    buttons.add(_buildManagePlayerStatsButton(match));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520.w;

        if (isCompact) {
          final columnChildren = <Widget>[];
          for (var i = 0; i < buttons.length; i++) {
            columnChildren.add(buttons[i]);
            if (i != buttons.length - 1) {
              columnChildren.add(SizedBox(height: 8.h));
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          );
        }

        final rowChildren = <Widget>[];
        for (var i = 0; i < buttons.length; i++) {
          rowChildren.add(Expanded(child: buttons[i]));
          if (i != buttons.length - 1) {
            rowChildren.add(SizedBox(width: 8.w));
          }
        }

        return Row(children: rowChildren);
      },
    );
  }

  Widget _buildAdminPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return SizedBox(
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? _accentColor,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildManagePlayerStatsButton(TournamentMatch match) {
    return SizedBox(
      height: 48.h,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPlayerStatsScreen(match: match),
            ),
          );
        },
        icon: const Icon(Icons.person),
        label: const Text('Manage Player Stats'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentColor,
          side: BorderSide(color: _accentColor),
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  _CenterBadgeFormState _getCenterBadgeForm(TournamentMatch match) {
    final form = _centerBadgeForms.putIfAbsent(
      match.id,
      () => _CenterBadgeFormState(),
    );
    form.syncWithMetadata(match.metadata?['centerBadge']);
    return form;
  }

  Future<void> _saveCenterBadge(
    TournamentMatch match,
    _CenterBadgeFormState form,
  ) async {
    final label = form.labelController.text.trim();
    final value = form.valueController.text.trim();
    final countdownSeconds =
        int.tryParse(form.countdownSecondsController.text.trim()) ?? 0;

    final centerBadge = <String, dynamic>{
      if (label.isNotEmpty) 'label': label,
      if (value.isNotEmpty) 'value': value,
    };

    if (form.countdownEnabled) {
      centerBadge['countdown'] = {
        'enabled': true,
        'direction': form.countdownDirection,
        'initialSeconds': countdownSeconds,
        'savedAt': DateTime.now().toIso8601String(),
      };
    } else {
      centerBadge['countdown'] = {
        'enabled': false,
      };
    }

    try {
      await _matchService.updateMatchMetadata(
        matchId: match.id,
        metadata: {'centerBadge': centerBadge},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Center badge updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save badge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatSecondsPreview(int seconds) {
    if (seconds <= 0) return '00s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes <= 0) {
      return '${secs.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }

  Widget _buildCenterBadgeDisplayForMatch(TournamentMatch match) {
    final badge = match.metadata != null &&
            match.metadata!['centerBadge'] is Map<String, dynamic>
        ? match.metadata!['centerBadge'] as Map<String, dynamic>
        : null;
    final label =
        (badge?['label'] as String?)?.trim().isNotEmpty == true
            ? (badge?['label'] as String).trim()
            : (match.round ?? match.matchNumber);
    final defaultValue =
        match.isLive ? '${match.team1.score}-${match.team2.score}' : DateFormat('h:mm a').format(match.scheduledTime);
    final configuredValue =
        (badge?['value'] as String?)?.trim().isNotEmpty == true
            ? (badge?['value'] as String).trim()
            : null;
    final value = configuredValue ?? defaultValue;
    final countdown = badge != null ? _buildBadgeCountdownForMatch(badge) : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyles.font12White500Weight.copyWith(
                  color: Colors.white70,
                ),
              ),
              Gap(2.h),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyles.font13White500Weight,
                  ),
                  if (countdown != null) ...[
                    Gap(6.w),
                    countdown,
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildBadgeCountdownForMatch(Map<String, dynamic> badge) {
    final countdown = badge['countdown'];
    if (countdown is! Map<String, dynamic>) return null;
    if (countdown['enabled'] != true) return null;
    final direction = (countdown['direction'] as String?) ?? 'up';
    final initial = (countdown['initialSeconds'] as num?)?.toInt() ?? 0;
    final savedAt = _parseMetadataDate(countdown['savedAt']) ?? DateTime.now();
    final elapsed = DateTime.now().difference(savedAt).inSeconds;
    final currentSeconds =
        direction == 'down' ? math.max(0, initial - elapsed) : initial + elapsed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          direction == 'down' ? Icons.south : Icons.north,
          size: 14.sp,
          color: Colors.white,
        ),
        Gap(4.w),
        Text(
          _formatSecondsPreview(currentSeconds),
          style: TextStyles.font11Grey400Weight.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  DateTime? _parseMetadataDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Duration _getCommentaryCooldown(String matchId) {
    final last = _lastCommentaryUpdates[matchId];
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().difference(last);
    const interval = Duration(seconds: 15);
    if (elapsed >= interval) return Duration.zero;
    return interval - elapsed;
  }

  Future<void> _postLiveCommentary(TournamentMatch match) async {
    final controller = _liveCommentaryControllers[match.id];
    if (controller == null || controller.text.trim().isEmpty) return;

    final cooldown = _getCommentaryCooldown(match.id);
    if (cooldown > Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please wait ${_formatDuration(cooldown)} before posting again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _matchService.addCommentary(
        matchId: match.id,
        text: controller.text.trim(),
      );
      controller.clear();
      _lastCommentaryUpdates[match.id] = DateTime.now();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentary added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add commentary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  void _resetScoreCountdown(String matchId) {
    setState(() {
      _liveCountdowns[matchId] = 30;
    });
  }

  Widget _buildMatchesSection({
    required String title,
    required List<TournamentMatch> matches,
    String? emptyMessage,
    bool showLiveTools = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        if (matches.isEmpty)
          _buildMatchesPlaceholder(
            emptyMessage ?? 'No matches available.',
          )
        else
          ...matches.map(
            (match) => _buildMatchCard(
              match,
              showLiveTools: showLiveTools,
            ),
          ),
      ],
    );
  }

  Widget _buildMatchesPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(radius: 16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white70, size: 18.sp),
          Gap(8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    TournamentMatch match, {
    bool showLiveTools = false,
    bool isScheduleContext = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: PublicProfileTheme.panelGradient,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: match.isLive ? 1.5 : 1,
        ),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.matchNumber,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildMatchStatusBadge(match.status),
            ],
          ),
        if (showLiveTools) ...[
          Gap(12.h),
          _buildLiveCountdown(match),
        ],
          if (match.round != null) ...[
            Gap(4.h),
            Text(
              match.round!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.sp,
              ),
            ),
          ],
          Gap(12.h),

          // Teams and Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.team1.teamName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                match.team1.score.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.team2.teamName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                match.team2.score.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap(10.h),
          _buildCenterBadgeDisplayForMatch(match),

          Gap(12.h),
          Text(
            'Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(match.scheduledTime)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),

          if (match.venueName != null) ...[
            Gap(4.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 14.sp, color: Colors.grey[400]),
                Gap(4.w),
                Text(
                  match.venueName!,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ],

          Gap(16.h),
          if (isScheduleContext) ...[
            if (match.isUpcoming)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startMatch(match.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Match'),
                ),
              ),
          ] else ...[
            _buildMatchAdminActions(match),
            Gap(8.h),
            if (showLiveTools) ...[
              _buildLiveCommentaryComposer(match),
              Gap(12.h),
              _buildCenterBadgeEditor(match),
              Gap(8.h),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMatchStatusBadge(TournamentMatchStatus status) {
    Color color;
    switch (status) {
      case TournamentMatchStatus.scheduled:
        color = Colors.blueAccent;
        break;
      case TournamentMatchStatus.live:
        color = _accentColor;
        break;
      case TournamentMatchStatus.completed:
        color = ColorsManager.success;
        break;
      case TournamentMatchStatus.cancelled:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == TournamentMatchStatus.live)
            Container(
              width: 8.w,
              height: 8.w,
              margin: EdgeInsets.only(right: 6.w),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMatch(String matchId) async {
    try {
      await _matchService.startMatch(matchId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start match: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateScoreDialog(
    TournamentMatch match, {
    VoidCallback? onUpdated,
  }) {
    final team1Controller =
        TextEditingController(text: match.team1.score.toString());
    final team2Controller =
        TextEditingController(text: match.team2.score.toString());
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: team1Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${match.team1.teamName} score',
                  border: const OutlineInputBorder(),
                ),
              ),
              Gap(16.h),
              TextField(
                controller: team2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '${match.team2.teamName} score',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      final team1Score =
                          int.tryParse(team1Controller.text) ?? 0;
                      final team2Score =
                          int.tryParse(team2Controller.text) ?? 0;

                      try {
                        setState(() => isUpdating = true);

                        await _matchService.updateMatchScore(
                          matchId: match.id,
                          team1Score: team1Score,
                          team2Score: team2Score,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          onUpdated?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Score and background updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isUpdating = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndMatchDialog(TournamentMatch match) {
    String? selectedWinner;
    if (match.team1.score > match.team2.score) {
      selectedWinner = match.team1.teamId;
    } else if (match.team2.score > match.team1.score) {
      selectedWinner = match.team2.teamId;
    }
    bool declareDraw = selectedWinner == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('End Match'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the winner before ending the match.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                ),
              ),
              Gap(12.h),
              RadioListTile<String>(
                value: match.team1.teamId,
                groupValue: declareDraw ? null : selectedWinner,
                onChanged: (_) {
                  setState(() {
                    selectedWinner = match.team1.teamId;
                    declareDraw = false;
                  });
                },
                title: Text(
                  '${match.team1.teamName} (${match.team1.score})',
                ),
              ),
              RadioListTile<String>(
                value: match.team2.teamId,
                groupValue: declareDraw ? null : selectedWinner,
                onChanged: (_) {
                  setState(() {
                    selectedWinner = match.team2.teamId;
                    declareDraw = false;
                  });
                },
                title: Text(
                  '${match.team2.teamName} (${match.team2.score})',
                ),
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: declareDraw,
                onChanged: (_) {
                  setState(() {
                    declareDraw = true;
                    selectedWinner = null;
                  });
                },
                title: const Text('Declare draw'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  String result;
                  String? winnerId = declareDraw ? null : selectedWinner;

                  if (winnerId == match.team1.teamId) {
                    result =
                        '${match.team1.teamName} declared winners over ${match.team2.teamName}';
                  } else if (winnerId == match.team2.teamId) {
                    result =
                        '${match.team2.teamName} declared winners over ${match.team1.teamName}';
                  } else {
                    result = 'Match declared as a draw';
                  }

                  await _matchService.endMatch(
                    matchId: match.id,
                    result: result,
                    winnerTeamId: winnerId,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match ended successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to end match: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('End Match'),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreUnit(SportType sport) {
    switch (sport) {
      case SportType.football:
      case SportType.soccer:
      case SportType.hockey:
        return 'goals';
      case SportType.basketball:
        return 'points';
      case SportType.cricket:
        return 'runs';
      case SportType.tennis:
      case SportType.badminton:
      case SportType.volleyball:
        return 'points';
      default:
        return 'points';
    }
  }

  void _showAddCommentaryDialog(TournamentMatch match) {
    final textController = TextEditingController();
    final minuteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Commentary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minuteController,
              decoration: const InputDecoration(
                labelText: 'Minute/Time (optional)',
                hintText: "45', 1st Half",
                border: OutlineInputBorder(),
              ),
            ),
            Gap(16.h),
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Commentary',
                hintText: 'Goal! Amazing strike from...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.trim().isEmpty) return;

              try {
                await _matchService.addCommentary(
                  matchId: match.id,
                  text: textController.text.trim(),
                  minute: minuteController.text.trim().isNotEmpty
                      ? minuteController.text.trim()
                      : null,
                );

                if (mounted) {
                  _lastCommentaryUpdates[match.id] = DateTime.now();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commentary added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add commentary: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ============ TEAMS TAB ============
  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32.w),
      child: _buildTeamManagementCard(),
    );
  }

  // ============ SETTINGS TAB ============
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSection(
            'Tournament Status',
            [
              _buildSettingsTile(
                'Update Status',
                'Change tournament status (Upcoming/Running/Finished)',
                Icons.update,
                () => _showUpdateStatusDialog(),
              ),
            ],
          ),
          Gap(16.h),
          _buildSettingsSection(
            'Danger Zone',
            [
              _buildSettingsTile(
                'Delete Tournament',
                'Permanently delete this tournament',
                Icons.delete_forever,
                () => _showDeleteTournamentDialog(),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : ColorsManager.mainBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12.sp,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Tournament Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TournamentStatus.values.map((status) {
            return RadioListTile<TournamentStatus>(
              title: Text(status.displayName),
              value: status,
              groupValue: _currentTournament.status,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await _tournamentService.updateTournamentStatus(
                      _currentTournament.id,
                      value,
                    );

                    if (mounted) {
                      setState(() {
                        _currentTournament =
                            _currentTournament.copyWith(status: value);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTournamentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _tournamentService.deleteTournament(
                  _currentTournament.id,
                );

                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close admin screen
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tournament deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete tournament: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
