import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/app_text_form_field.dart';
import '../../../core/widgets/app_text_button.dart';
import '../../../models/coach_profile.dart';
import '../../../models/user_profile.dart';
import '../../../models/venue_model.dart';
import '../../../models/player_profile.dart';
import '../../../modules/team/models/team_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../services/coach_service.dart';
import '../services/coach_associations_service.dart';
import '../../../repositories/user_repository.dart';
import '../../../models/coach_associations.dart';
import '../widgets/venue_search_dialog.dart';
import '../widgets/team_search_dialog.dart';
import '../widgets/player_search_dialog.dart';

const _notificationHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

/// Comprehensive coach profile edit screen
class CoachProfileEditScreen extends StatefulWidget {
  final CoachProfile coach;

  const CoachProfileEditScreen({
    super.key,
    required this.coach,
  });

  @override
  State<CoachProfileEditScreen> createState() => _CoachProfileEditScreenState();
}

class _CoachProfileEditScreenState extends State<CoachProfileEditScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _certificationsController;
  
  // Search controllers for tabs
  final TextEditingController _venueSearchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  final TextEditingController _playerSearchController = TextEditingController();

  // Form state
  List<String> _selectedSports = [];
  TrainingType _selectedTrainingType = TrainingType.inPerson;
  List<TimeSlot> _availableTimeSlots = [];

  // Services
  final CoachService _coachService = CoachService();
  final CoachAssociationsService _associationsService =
      CoachAssociationsService();
  final UserRepository _userRepository = UserRepository();

  // Associations state
  CoachAssociations? _associations;

  // Search results for venues
  List<VenueModel> _venueSearchResults = [];
  bool _isSearchingVenues = false;
  Timer? _venueSearchDebounceTimer;

  // Search results for teams
  List<TeamModel> _teamSearchResults = [];
  bool _isSearchingTeams = false;
  Timer? _teamSearchDebounceTimer;

  // Search results for players
  List<PlayerProfile> _playerSearchResults = [];
  bool _isSearchingPlayers = false;
  Timer? _playerSearchDebounceTimer;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.coach.fullName);
    _bioController = TextEditingController(text: widget.coach.bio ?? '');
    _experienceController =
        TextEditingController(text: widget.coach.experienceYears.toString());
    _hourlyRateController =
        TextEditingController(text: widget.coach.hourlyRate.toString());
    _certificationsController = TextEditingController(
      text: widget.coach.certifications?.join(', ') ?? '',
    );
    // Search controllers are already initialized as final fields
  }

  void _loadInitialData() {
    setState(() {
      _selectedSports = List.from(widget.coach.specializationSports);
      _selectedTrainingType = widget.coach.coachingType;
      _availableTimeSlots = List.from(widget.coach.availableTimeSlots);
    });
    _loadAssociations();
  }

  Future<void> _loadAssociations() async {
    final associations =
        await _associationsService.getCoachAssociations(widget.coach.uid);
    if (mounted) {
      setState(() {
        _associations = associations;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _certificationsController.dispose();
    _venueSearchController.dispose();
    _teamSearchController.dispose();
    _playerSearchController.dispose();
    _venueSearchDebounceTimer?.cancel();
    _teamSearchDebounceTimer?.cancel();
    _playerSearchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildVenuesTab(),
                    _buildTeamsTab(),
                    _buildPlayersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Edit Coach Profile',
        style: TextStyles.font18White600Weight,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _notificationHeroGradient),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(gradient: _notificationHeroGradient),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Venues'),
          Tab(text: 'Teams'),
          Tab(text: 'Players'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Basic Information'),
          Gap(16.h),
          _buildNameField(),
          Gap(16.h),
          _buildBioField(),
          Gap(16.h),
          _buildExperienceField(),
          Gap(16.h),
          _buildHourlyRateField(),
          Gap(16.h),
          _buildTrainingTypeSelector(),
          Gap(24.h),
          _buildSectionTitle('Specializations'),
          Gap(16.h),
          _buildSportsSelector(),
          Gap(24.h),
          _buildSectionTitle('Certifications'),
          Gap(16.h),
          _buildCertificationsField(),
          Gap(24.h),
          _buildSectionTitle('Availability'),
          Gap(16.h),
          _buildAvailabilitySection(),
          Gap(100.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildVenuesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('My Venues'),
          Gap(16.h),
          _buildSearchBar(
            controller: _venueSearchController,
            hint: 'Search venues to add...',
            onChanged: _onVenueSearchChanged,
          ),
          Gap(16.h),
          // Show search results if searching
          if (_venueSearchController.text.trim().length >= 2) ...[
            _buildVenueSearchResults(),
            Gap(16.h),
          ],
          _buildVenuesList(),
        ],
      ),
    );
  }

  void _onVenueSearchChanged(String value) {
    _venueSearchDebounceTimer?.cancel();
    
    if (value.trim().length < 2) {
      setState(() {
        _venueSearchResults = [];
      });
      return;
    }

    _venueSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchVenuesForAdd(value);
    });
  }

  Future<void> _searchVenuesForAdd(String query) async {
    setState(() {
      _isSearchingVenues = true;
    });

    try {
      final venues = await _associationsService.searchVenues(query);
      if (mounted) {
        setState(() {
          _venueSearchResults = venues;
          _isSearchingVenues = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingVenues = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching venues: $e')),
        );
      }
    }
  }

  Widget _buildVenueSearchResults() {
    if (_isSearchingVenues) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_venueSearchResults.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withOpacity(0.5),
              size: 24.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                'No venues found. Try a different search term.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        ..._venueSearchResults.map((venue) => _buildVenueSearchResultCard(venue)),
      ],
    );
  }

  Widget _buildVenueSearchResultCard(VenueModel venue) {
    // Check if venue is already added
    final isAlreadyAdded = _associations?.venues.any(
          (v) => v.venueId == venue.id,
        ) ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: Colors.white.withOpacity(0.08),
      child: InkWell(
        onTap: isAlreadyAdded
            ? null
            : () => _requestVenueFromSearch(venue),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorsManager.primary.withAlpha(51),
                radius: 24.r,
                child: Icon(
                  Icons.location_on,
                  color: ColorsManager.primary,
                  size: 20.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      venue.location,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13.sp,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      'Owner: ${venue.ownerName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              if (isAlreadyAdded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Added',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _requestVenueFromSearch(venue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(90.w, 36.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: const Text('Add'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestVenueFromSearch(VenueModel venue) async {
    try {
      final success = await _associationsService.requestVenueAssociation(
        widget.coach.uid,
        widget.coach.fullName,
        venue,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request sent to ${venue.ownerName}'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear search and refresh associations
          _venueSearchController.clear();
          _loadAssociations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send request or venue already added'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('My Teams'),
          Gap(16.h),
          _buildSearchBar(
            controller: _teamSearchController,
            hint: 'Search teams to add...',
            onChanged: _onTeamSearchChanged,
          ),
          Gap(16.h),
          // Show search results if searching
          if (_teamSearchController.text.trim().length >= 2) ...[
            _buildTeamSearchResults(),
            Gap(16.h),
          ],
          _buildTeamsList(),
        ],
      ),
    );
  }

  void _onTeamSearchChanged(String value) {
    if (kDebugMode) {
      debugPrint('🔍 _onTeamSearchChanged called with: "$value" (length: ${value.length})');
    }

    _teamSearchDebounceTimer?.cancel();
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      if (kDebugMode) {
        debugPrint('⚠️ Search query too short, clearing results');
      }
      setState(() {
        _teamSearchResults = [];
      });
      return;
    }

    if (kDebugMode) {
      debugPrint('⏱️ Starting debounce timer for team search...');
    }

    _teamSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (kDebugMode) {
        debugPrint('✅ Debounce timer completed, calling _searchTeamsForAdd');
      }
      _searchTeamsForAdd(trimmedValue);
    });
  }

  Future<void> _searchTeamsForAdd(String query) async {
    if (kDebugMode) {
      debugPrint('🔍 _searchTeamsForAdd called with query: "$query"');
    }

    setState(() {
      _isSearchingTeams = true;
      _teamSearchResults = [];
    });

    try {
      final teams = await _associationsService.searchTeams(query.trim());
      if (mounted) {
        if (kDebugMode) {
          debugPrint('✅ Search completed, found ${teams.length} teams');
        }
        setState(() {
          _teamSearchResults = teams;
          _isSearchingTeams = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error in _searchTeamsForAdd: $e');
        debugPrint('   Stack: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isSearchingTeams = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching teams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTeamSearchResults() {
    if (_isSearchingTeams) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_teamSearchResults.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withOpacity(0.5),
              size: 24.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                'No teams found. Try a different search term.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        ..._teamSearchResults.map((team) => _buildTeamSearchResultCard(team)),
      ],
    );
  }

  Widget _buildTeamSearchResultCard(TeamModel team) {
    // Check if team is already added
    final isAlreadyAdded = _associations?.teams.any(
          (t) => t.teamId == team.id,
        ) ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: Colors.white.withOpacity(0.08),
      child: InkWell(
        onTap: isAlreadyAdded
            ? null
            : () => _requestTeamFromSearch(team),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorsManager.primary.withAlpha(51),
                radius: 24.r,
                backgroundImage: team.profileImageUrl != null
                    ? NetworkImage(team.profileImageUrl!)
                    : null,
                child: team.profileImageUrl == null
                    ? Icon(
                        Icons.group,
                        color: ColorsManager.primary,
                        size: 20.sp,
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(4.h),
                    if (team.city != null)
                      Text(
                        'Location: ${team.city}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13.sp,
                        ),
                      ),
                    Gap(2.h),
                    Text(
                      '${team.members.length}/${team.maxMembers} members',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      'Sport: ${team.sportType.displayName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              if (isAlreadyAdded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Added',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _requestTeamFromSearch(team),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(90.w, 36.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: const Text('Add'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestTeamFromSearch(TeamModel team) async {
    try {
      final success = await _associationsService.requestTeamAssociation(
        widget.coach.uid,
        widget.coach.fullName,
        team,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request sent to team captain'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear search and refresh associations
          _teamSearchController.clear();
          _loadAssociations();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildPlayersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('My Players'),
          Gap(16.h),
          _buildSearchBar(
            controller: _playerSearchController,
            hint: 'Search players to add...',
            onChanged: _onPlayerSearchChanged,
          ),
          Gap(16.h),
          // Show search results if searching
          if (_playerSearchController.text.trim().length >= 2) ...[
            _buildPlayerSearchResults(),
            Gap(16.h),
          ],
          _buildPlayersList(),
        ],
      ),
    );
  }

  void _onPlayerSearchChanged(String value) {
    if (kDebugMode) {
      debugPrint('🔍 _onPlayerSearchChanged called with: "$value" (length: ${value.length})');
    }

    _playerSearchDebounceTimer?.cancel();
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < 2) {
      if (kDebugMode) {
        debugPrint('⚠️ Search query too short, clearing results');
      }
      setState(() {
        _playerSearchResults = [];
      });
      return;
    }

    if (kDebugMode) {
      debugPrint('⏱️ Starting debounce timer for player search...');
    }

    _playerSearchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (kDebugMode) {
        debugPrint('✅ Debounce timer completed, calling _searchPlayersForAdd');
      }
      _searchPlayersForAdd(trimmedValue);
    });
  }

  Future<void> _searchPlayersForAdd(String query) async {
    if (kDebugMode) {
      debugPrint('🔍 _searchPlayersForAdd called with query: "$query"');
    }

    setState(() {
      _isSearchingPlayers = true;
      _playerSearchResults = [];
    });

    try {
      final players = await _associationsService.searchPlayers(query.trim());
      if (mounted) {
        if (kDebugMode) {
          debugPrint('✅ Search completed, found ${players.length} players');
        }
        setState(() {
          _playerSearchResults = players;
          _isSearchingPlayers = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error in _searchPlayersForAdd: $e');
        debugPrint('   Stack: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isSearchingPlayers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPlayerSearchResults() {
    if (_isSearchingPlayers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_playerSearchResults.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_off,
              color: Colors.white.withOpacity(0.5),
              size: 24.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                'No players found. Try a different search term.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(12.h),
        ..._playerSearchResults.map((player) => _buildPlayerSearchResultCard(player)),
      ],
    );
  }

  Widget _buildPlayerSearchResultCard(PlayerProfile player) {
    // Check if player is already added
    final isAlreadyAdded = _associations?.players.any(
          (p) => p.playerId == player.uid,
        ) ?? false;

    final avatarUrl = player.profilePictureUrl;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      color: Colors.white.withOpacity(0.08),
      child: InkWell(
        onTap: isAlreadyAdded
            ? null
            : () => _requestPlayerFromSearch(player),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: ColorsManager.primary.withAlpha(40),
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(Icons.person, color: ColorsManager.primary, size: 20.sp)
                    : null,
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(4.h),
                    if (player.nickname != null && player.nickname!.isNotEmpty)
                      Text(
                        '@${player.nickname}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13.sp,
                        ),
                      ),
                    Gap(2.h),
                    Text(
                      '${player.age} • ${player.location}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                    if (player.sportsOfInterest.isNotEmpty) ...[
                      Gap(4.h),
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: player.sportsOfInterest
                            .take(2)
                            .map(
                              (sport) => Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  sport,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Gap(8.w),
              if (isAlreadyAdded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Added',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () => _requestPlayerFromSearch(player),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(90.w, 36.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  ),
                  child: const Text('Add'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestPlayerFromSearch(PlayerProfile player) async {
    try {
      final success = await _associationsService.requestPlayerAssociation(
        widget.coach.uid,
        widget.coach.fullName,
        player,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request sent to ${player.fullName}'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear search and refresh associations
          _playerSearchController.clear();
          _loadAssociations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send request or player already added'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: (value) {
        // Trigger parent widget rebuild
        setState(() {});
        onChanged(value);
      },
      style: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14.sp,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withOpacity(0.7),
          size: 20.sp,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white.withOpacity(0.7),
                  size: 20.sp,
                ),
                onPressed: () {
                  controller.clear();
                  setState(() {}); // Rebuild to hide clear button and clear results
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.primary,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      style: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ColorsManager.primary,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
            width: 1.3.w,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        errorStyle: TextStyle(
          color: Colors.red[300],
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return _buildStyledTextField(
      controller: _nameController,
      hint: 'Full Name',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Full name is required';
        }
        return null;
      },
    );
  }

  Widget _buildBioField() {
    return _buildStyledTextField(
      controller: _bioController,
      hint: 'Tell us about yourself...',
      maxLines: 4,
      validator: CoachProfileValidator.validateBio,
    );
  }

  Widget _buildExperienceField() {
    return _buildStyledTextField(
      controller: _experienceController,
      hint: 'Years of Experience',
      keyboardType: TextInputType.number,
      validator: (value) {
        final years = int.tryParse(value ?? '');
        return CoachProfileValidator.validateExperienceYears(years);
      },
    );
  }

  Widget _buildHourlyRateField() {
    return _buildStyledTextField(
      controller: _hourlyRateController,
      hint: 'Hourly Rate (\$)',
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final rate = double.tryParse(value ?? '');
        return CoachProfileValidator.validateHourlyRate(rate);
      },
    );
  }

  Widget _buildTrainingTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training Type',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Gap(8.h),
        ...TrainingType.values.map((type) => RadioListTile<TrainingType>(
              title: Text(
                type.displayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              value: type,
              groupValue: _selectedTrainingType,
              activeColor: ColorsManager.primary,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTrainingType = value;
                  });
                }
              },
            )),
      ],
    );
  }

  Widget _buildSportsSelector() {
    final availableSports = [
      'Football',
      'Basketball',
      'Tennis',
      'Cricket',
      'Swimming',
      'Badminton',
      'Volleyball',
      'Table Tennis',
      'Hockey',
      'Golf'
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: availableSports.map((sport) {
        final isSelected = _selectedSports.contains(sport);
        return FilterChip(
          label: Text(
            sport,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSports.add(sport);
              } else {
                _selectedSports.remove(sport);
              }
            });
          },
          selectedColor: ColorsManager.primary,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.1),
          side: BorderSide(
            color: isSelected
                ? ColorsManager.primary
                : Colors.white.withOpacity(0.2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificationsField() {
    return _buildStyledTextField(
      controller: _certificationsController,
      hint: 'Certifications (comma separated)',
      maxLines: 2,
      validator: (value) => null, // Optional field
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Slots',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: _addTimeSlot,
              icon: const Icon(Icons.add, color: ColorsManager.primary),
              label: Text(
                'Add Slot',
                style: TextStyle(
                  color: ColorsManager.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        Gap(8.h),
        if (_availableTimeSlots.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              'No time slots added. Click "Add Slot" to add availability.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13.sp,
              ),
            ),
          )
        else
          ..._availableTimeSlots.map((slot) => _buildTimeSlotCard(slot)),
      ],
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: ColorsManager.primary,
            size: 20.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.day,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(4.h),
                Text(
                  '${slot.startTime} - ${slot.endTime}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeTimeSlot(slot),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildVenuesList() {
    if (_associations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final venues = _associations!.venues;
    final searchQuery = _venueSearchController.text.toLowerCase().trim();
    final filteredVenues = searchQuery.isEmpty
        ? venues
        : venues.where((venue) {
            return venue.venueName.toLowerCase().contains(searchQuery);
          }).toList();

    if (filteredVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.location_off,
              size: 48.sp,
              color: Colors.white.withOpacity(0.5),
            ),
            Gap(16.h),
            Text(
              searchQuery.isNotEmpty
                  ? 'No venues found matching "$searchQuery"'
                  : 'No venues added yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredVenues.length,
      itemBuilder: (context, index) {
        final venue = filteredVenues[index];
        return _buildVenueAssociationCard(venue);
      },
    );
  }

  Widget _buildTeamsList() {
    if (_associations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final teams = _associations!.teams;
    final searchQuery = _teamSearchController.text.toLowerCase().trim();
    final filteredTeams = searchQuery.isEmpty
        ? teams
        : teams.where((team) {
            return team.teamName.toLowerCase().contains(searchQuery);
          }).toList();

    if (filteredTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.group_off,
              size: 48.sp,
              color: Colors.white.withOpacity(0.5),
            ),
            Gap(16.h),
            Text(
              searchQuery.isNotEmpty
                  ? 'No teams found matching "$searchQuery"'
                  : 'No teams added yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTeams.length,
      itemBuilder: (context, index) {
        final team = filteredTeams[index];
        return _buildTeamAssociationCard(team);
      },
    );
  }

  Widget _buildPlayersList() {
    if (_associations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final players = _associations!.players;
    final searchQuery = _playerSearchController.text.toLowerCase().trim();
    final filteredPlayers = searchQuery.isEmpty
        ? players
        : players.where((player) {
            return player.playerName.toLowerCase().contains(searchQuery);
          }).toList();

    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.person_off,
              size: 48.sp,
              color: Colors.white.withOpacity(0.5),
            ),
            Gap(16.h),
            Text(
              searchQuery.isNotEmpty
                  ? 'No players found matching "$searchQuery"'
                  : 'No players added yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = filteredPlayers[index];
        return _buildPlayerAssociationCard(player);
      },
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _saveProfile,
      backgroundColor: ColorsManager.primary,
      foregroundColor: Colors.white,
      icon: _isLoading
          ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.save),
      label: Text(_isLoading ? 'Saving...' : 'Save'),
    );
  }

  void _addTimeSlot() {
    String? selectedDay;
    String? selectedStartTime;
    String? selectedEndTime;

    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const timeOptions = [
      '06:00',
      '07:00',
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1B1848),
          title: Text(
            'Add Time Slot',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day selection
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: InputDecoration(
                  labelText: 'Day',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
                dropdownColor: const Color(0xFF1B1848),
                style: TextStyle(color: Colors.white),
                items: daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedDay = value;
                  });
                },
              ),
              Gap(16.h),

              // Start time selection
              DropdownButtonFormField<String>(
                value: selectedStartTime,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
                dropdownColor: const Color(0xFF1B1848),
                style: TextStyle(color: Colors.white),
                items: timeOptions.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStartTime = value;
                    // Reset end time if it's before start time
                    if (selectedEndTime != null && value != null) {
                      final startIndex = timeOptions.indexOf(value);
                      final endIndex = timeOptions.indexOf(selectedEndTime!);
                      if (endIndex <= startIndex) {
                        selectedEndTime = null;
                      }
                    }
                  });
                },
              ),
              Gap(16.h),

              // End time selection
              DropdownButtonFormField<String>(
                value: selectedEndTime,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: ColorsManager.primary,
                    ),
                  ),
                ),
                dropdownColor: const Color(0xFF1B1848),
                style: TextStyle(color: Colors.white),
                items: selectedStartTime != null
                    ? timeOptions.where((time) {
                        final startIndex =
                            timeOptions.indexOf(selectedStartTime!);
                        final timeIndex = timeOptions.indexOf(time);
                        return timeIndex > startIndex;
                      }).map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList()
                    : [],
                onChanged: (value) {
                  setDialogState(() {
                    selectedEndTime = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14.sp,
                ),
              ),
            ),
            TextButton(
              onPressed: selectedDay != null &&
                      selectedStartTime != null &&
                      selectedEndTime != null
                  ? () {
                      // Check for conflicts
                      final newSlot = TimeSlot(
                        day: selectedDay!,
                        startTime: selectedStartTime!,
                        endTime: selectedEndTime!,
                      );

                      final hasConflict = _availableTimeSlots.any((existing) =>
                          existing.day == newSlot.day &&
                          _timesOverlap(
                            existing.startTime,
                            existing.endTime,
                            newSlot.startTime,
                            newSlot.endTime,
                          ));

                      if (hasConflict) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Time slot conflicts with existing slot',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _availableTimeSlots.add(newSlot);
                      });
                      Navigator.pop(context);
                    }
                  : null,
              child: Text(
                'Add',
                style: TextStyle(
                  color: selectedDay != null &&
                          selectedStartTime != null &&
                          selectedEndTime != null
                      ? ColorsManager.primary
                      : Colors.white.withOpacity(0.3),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    // Simple time comparison (assuming 24-hour format HH:mm)
    final start1Time = _parseTime(start1);
    final end1Time = _parseTime(end1);
    final start2Time = _parseTime(start2);
    final end2Time = _parseTime(end2);

    return (start2Time < end1Time && end2Time > start1Time);
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute; // Convert to minutes for easy comparison
  }

  void _removeTimeSlot(TimeSlot slot) {
    setState(() {
      _availableTimeSlots.remove(slot);
    });
  }

  void _addVenue() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => VenueSearchDialog(
        coachId: widget.coach.uid,
        coachName: widget.coach.fullName,
      ),
    );

    if (result == true) {
      _loadAssociations(); // Refresh associations
    }
  }

  void _addTeam() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TeamSearchDialog(
        coachId: widget.coach.uid,
        coachName: widget.coach.fullName,
      ),
    );

    if (result == true) {
      _loadAssociations(); // Refresh associations
    }
  }

  void _addPlayer() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PlayerSearchDialog(
        coachId: widget.coach.uid,
        coachName: widget.coach.fullName,
      ),
    );

    if (result == true) {
      _loadAssociations();
    }
  }

  Widget _buildVenueAssociationCard(CoachVenueAssociation venue) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: venue.status.color.withAlpha(51),
          child: Icon(
            Icons.location_on,
            color: venue.status.color,
          ),
        ),
        title: Text(
          venue.venueName,
          style: TextStyles.font16DarkBlue500Weight,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${venue.status.displayName}',
              style: TextStyle(
                color: venue.status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (venue.rejectionReason != null)
              Text(
                'Reason: ${venue.rejectionReason}',
                style: TextStyles.font12Grey400Weight,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeVenueAssociation(venue.venueId),
        ),
      ),
    );
  }

  Widget _buildTeamAssociationCard(CoachTeamAssociation team) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: team.status.color.withAlpha(51),
          child: Icon(
            Icons.group,
            color: team.status.color,
          ),
        ),
        title: Text(
          team.teamName,
          style: TextStyles.font16DarkBlue500Weight,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${team.status.displayName}',
              style: TextStyle(
                color: team.status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (team.rejectionReason != null)
              Text(
                'Reason: ${team.rejectionReason}',
                style: TextStyles.font12Grey400Weight,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeTeamAssociation(team.teamId),
        ),
      ),
    );
  }

  Widget _buildPlayerAssociationCard(CoachPlayerAssociation player) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: player.status.color.withAlpha(51),
          child: Icon(
            Icons.person,
            color: player.status.color,
          ),
        ),
        title: Text(
          player.playerName,
          style: TextStyles.font16DarkBlue500Weight,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${player.status.displayName}',
              style: TextStyle(
                color: player.status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (player.rejectionReason != null)
              Text(
                'Reason: ${player.rejectionReason}',
                style: TextStyles.font12Grey400Weight,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removePlayerAssociation(player.playerId),
        ),
      ),
    );
  }

  Future<void> _removeVenueAssociation(String venueId) async {
    final success = await _associationsService.removeVenueAssociation(
        widget.coach.uid, venueId);
    if (success) {
      _loadAssociations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue removed successfully')),
      );
    }
  }

  Future<void> _removeTeamAssociation(String teamId) async {
    final success = await _associationsService.removeTeamAssociation(
        widget.coach.uid, teamId);
    if (success) {
      _loadAssociations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team removed successfully')),
      );
    }
  }

  Future<void> _removePlayerAssociation(String playerId) async {
    final success = await _associationsService.removePlayerAssociation(
        widget.coach.uid, playerId);
    if (success) {
      _loadAssociations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player removed successfully')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final certifications = _certificationsController.text.trim().isEmpty
          ? null
          : _certificationsController.text
              .split(',')
              .map((e) => e.trim())
              .toList();

      final updatedProfile = widget.coach.copyWith(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        experienceYears: int.parse(_experienceController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        coachingType: _selectedTrainingType,
        specializationSports: _selectedSports,
        certifications: certifications,
        availableTimeSlots: _availableTimeSlots,
        updatedAt: DateTime.now(),
      );

      final success = await _coachService.updateCoachProfile(updatedProfile);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
}
