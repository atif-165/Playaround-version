import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../helpers/admin_override_helper.dart';
import '../../../logic/cubit/auth_cubit.dart';
import '../../../models/user_profile.dart';
import '../../../models/venue.dart';
import '../../../models/venue_review.dart' show VenueFilter;
import '../../../repositories/user_repository.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../core/navigation/detail_navigator.dart';

import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../team/models/team_model.dart';
import '../../team/services/team_service.dart';
import '../../../screens/venue/venue_profile_screen.dart';
import '../../../services/notification_service.dart';
import '../../../services/venue_service.dart';

import '../models/tournament_model.dart';
import '../models/tournament_match_model.dart';
import '../models/player_match_stats.dart';
import '../services/tournament_live_service.dart';
import '../services/tournament_match_service.dart';
import '../services/tournament_team_service.dart';
import '../services/tournament_service.dart';

import '../widgets/tournament_teams_list.dart';

import 'tournament_team_registration_screen.dart';
import 'match_scheduling_screen.dart';
import 'score_update_screen.dart';
import 'winner_declaration_screen.dart';
import 'tournament_management_dashboard.dart';
import 'tournament_admin_screen.dart';
import 'tournament_team_detail_screen.dart';

const Color _profileBackgroundColor = Color(0xFF050414);
const LinearGradient _profileBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);
const LinearGradient _panelGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF181536),
    Color(0xFF0E0D24),
  ],
);
const Color _panelColor = Color(0xFF14112D);
const Color _panelOverlayColor = Color(0xFF1C1A3C);
const Color _panelAccentColor = Color(0xFFFFC56F);

enum JoinRequestType { team, individual }

class _JoinRequestSubmission {
  const _JoinRequestSubmission({
    required this.type,
    required this.fields,
    required this.formResponses,
    this.selectedTeam,
    this.teamSkillRating,
  });

  final JoinRequestType type;
  final Map<String, String> fields;
  final Map<String, dynamic> formResponses;
  final Team? selectedTeam;
  final double? teamSkillRating;
}

/// Screen displaying detailed tournament information
class TournamentDetailScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentDetailScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? background;
  final Color? borderColor;

  const _HeaderChip({
    required this.icon,
    required this.label,
    this.background,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: Colors.white,
          ),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12WhiteMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: Colors.white,
          ),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12WhiteMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HighlightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              size: 22.sp,
              color: accent,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: accent.withOpacity(0.9),
                  ),
                ),
                Gap(4.h),
                Text(
                  value,
                  style: TextStyles.font16DarkBlueBold.copyWith(
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PriceTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.font12WhiteMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Gap(4.h),
                Text(
                  value,
                  style: TextStyles.font18White600Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AdminHeroActionButton extends StatelessWidget {
  const _AdminHeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: PublicProfileTheme.defaultShadow(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: PublicProfileTheme.panelAccentColor),
            Gap(6.w),
            Text(
              label,
              style: TextStyles.font12White600Weight.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TournamentTabBarHeaderDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: _panelColor.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(overlapsContent ? 0.35 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TournamentTabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  final TournamentLiveService _liveService = TournamentLiveService();
  final TournamentTeamService _teamService = TournamentTeamService();
  final ChatService _chatService = ChatService();
  final TournamentMatchService _matchService = TournamentMatchService();
  final TeamService _teamDirectoryService = TeamService();
  final NotificationService _notificationService = NotificationService();
  final UserRepository _userRepository = UserRepository();

  StreamSubscription<Tournament>? _tournamentSubscription;
  StreamSubscription<List<TournamentMatch>>? _matchesSubscription;
  StreamSubscription<Map<String, int>>? _leaderboardSubscription;
  StreamSubscription<List<TournamentTeam>>? _teamsSubscription;

  bool _isRegistering = false;
  bool _demoMatchesApplied = false;
  bool _demoStandingsApplied = false;
  bool _usingDemoMatches = false;
  bool _usingDemoStandings = false;

  // Tab controller for different sections
  late TabController _tabController;

  // User profile for checking permissions
  UserProfile? _currentUserProfile;

  // Tournament data
  Tournament? _liveTournament;
  List<TournamentMatch> _allMatches = [];
  List<TournamentMatch> _liveMatches = [];
  List<TournamentMatch> _pastMatches = [];
  List<TournamentMatch> _todayMatches = [];
  List<TournamentMatch> _futureMatches = [];
  Map<String, int> _teamStandings = {};
  List<TournamentTeam> _activeTeams = [];
  Map<String, TournamentTeam> _teamLookup = {};
  Venue? _selectedVenue;
  bool _isLoadingVenue = false;

  Tournament get _tournament => _liveTournament ?? widget.tournament;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
    _loadTournamentData();
    _subscribeToLiveData();
    _hydrateVenue();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tournamentSubscription?.cancel();
    _matchesSubscription?.cancel();
    _leaderboardSubscription?.cancel();
    _teamsSubscription?.cancel();
    super.dispose();
  }

  void _loadUserProfile() {
    unawaited(_ensureUserProfile());
  }

  Future<UserProfile?> _ensureUserProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserProfile != null) {
      return _currentUserProfile;
    }

    final authState = context.read<AuthCubit>().state;
    if (!forceRefresh && authState is AuthenticatedWithProfile) {
      setState(() {
        _currentUserProfile = authState.userProfile;
      });
      return _currentUserProfile;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      final profile = await _userRepository.getUserProfile(firebaseUser.uid);
      if (mounted && profile != null) {
        setState(() {
          _currentUserProfile = profile;
        });
      }
      return profile;
    } catch (_) {
      return _currentUserProfile;
    }
  }

  void _loadTournamentData() {
    _teamStandings = Map.from(_tournament.teamPoints);
    _applyDemoStandingsIfNeeded();
  }

  Future<void> _hydrateVenue() async {
    if (_isLoadingVenue) return;
    final venueId = _tournament.venueId;
    try {
      setState(() => _isLoadingVenue = true);

      if (venueId != null && venueId.trim().isNotEmpty) {
        final venue = await VenueService.getVenueById(venueId);
        if (!mounted) return;
        setState(() {
          _selectedVenue = venue;
          _isLoadingVenue = false;
        });
        return;
      }

      if (_isRegionalSportsLeague) {
        final venues = await VenueService.getVenues(
          filter: VenueFilter(
            isVerified: true,
            sports: [_tournament.sportType.displayName],
          ),
          limit: 1,
        );
        if (!mounted) return;
        setState(() {
          _selectedVenue = venues.isNotEmpty ? venues.first : null;
          _isLoadingVenue = false;
        });
        return;
      }

      if (mounted) {
        setState(() => _isLoadingVenue = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVenue = false);
      }
    }
  }

  void _subscribeToLiveData() {
    final tournamentId = _tournament.id;

    _tournamentSubscription =
        _liveService.getTournamentUpdates(tournamentId).listen((updated) {
      if (!mounted) return;
      setState(() {
        _liveTournament = updated;
        _teamStandings = Map<String, int>.from(updated.teamPoints);
        if (updated.teamPoints.isNotEmpty) {
          _demoStandingsApplied = false;
          _usingDemoStandings = false;
        }
        _applyDemoStandingsIfNeeded();
      });
    });

    _leaderboardSubscription =
        _liveService.getLeaderboardUpdates(tournamentId).listen((leaderboard) {
      if (!mounted) return;
      setState(() {
        _teamStandings = Map<String, int>.from(leaderboard);
        if (leaderboard.isNotEmpty) {
          _demoStandingsApplied = false;
          _usingDemoStandings = false;
        }
        _applyDemoStandingsIfNeeded();
      });
    });

    _matchesSubscription =
        _liveService.getMatchUpdates(tournamentId).listen((matches) {
      if (!mounted) return;
      setState(() {
        if (matches.isNotEmpty) {
          _demoMatchesApplied = false;
          _usingDemoMatches = false;
          _allMatches = matches;
          _categorizeMatches(matches);
          return;
        }

        if (_allMatches.isNotEmpty) {
          // Keep showing the last known dataset (demo or real) until we
          // actually receive new matches from the backend.
          return;
        }

        _allMatches = matches;
        _categorizeMatches(matches);
      });
    });

    _teamsSubscription =
        _teamService.getTeamsStream(tournamentId).listen((teams) {
      if (!mounted) return;
      setState(() {
        if (teams.isNotEmpty) {
          _demoStandingsApplied = false;
          _usingDemoStandings = false;
          _activeTeams = teams;
          _teamLookup = {
            for (final team in teams) team.id: team,
          };
        } else if (!_usingDemoStandings) {
          _activeTeams = teams;
          _teamLookup = {
            for (final team in teams) team.id: team,
          };
        }
        _applyDemoStandingsIfNeeded();
      });
    });
  }

  void _categorizeMatches(List<TournamentMatch> matches) {
    final now = DateTime.now();

    final live = <TournamentMatch>[];
    final today = <TournamentMatch>[];
    final upcoming = <TournamentMatch>[];
    final completed = <TournamentMatch>[];

    for (final match in matches) {
      switch (match.status) {
        case TournamentMatchStatus.live:
          live.add(match);
          break;
        case TournamentMatchStatus.completed:
          completed.add(match);
          break;
        case TournamentMatchStatus.cancelled:
          if (match.scheduledTime.isBefore(now)) {
            completed.add(match);
          } else {
            upcoming.add(match);
          }
          break;
        case TournamentMatchStatus.scheduled:
          if (_isSameDay(match.scheduledTime, now)) {
            today.add(match);
          } else if (match.scheduledTime.isAfter(now)) {
            upcoming.add(match);
          } else {
            completed.add(match);
          }
          break;
      }
    }

    int compareByTime(TournamentMatch a, TournamentMatch b) =>
        a.scheduledTime.compareTo(b.scheduledTime);

    live.sort(compareByTime);
    today.sort(compareByTime);
    upcoming.sort(compareByTime);
    completed.sort(compareByTime);

    _liveMatches = live;
    _todayMatches = today;
    _futureMatches = upcoming;
    _pastMatches = completed.reversed.toList();
    _applyDemoMatchesIfNeeded();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _teamName(String teamId) {
    final team = _teamLookup[teamId];
    if (team != null && team.name.isNotEmpty) {
      return team.name;
    }
    return teamId;
  }

  TournamentTeam? _teamDetails(String teamId) => _teamLookup[teamId];

  bool get _isRoyalSportsLeague =>
      _tournament.name.toLowerCase().contains('royal sports league');

  bool get _isRegionalSportsLeague =>
      _tournament.name.toLowerCase().contains('regional sports league');

  bool get _isOwner => _currentUserProfile?.uid == _tournament.organizerId;
  bool get _hasAdminOverride =>
      AdminOverrideHelper.allowTournamentOverride(_tournament);
  bool get _canManageTournament => _isOwner || _hasAdminOverride;

  @override
  Widget build(BuildContext context) {
    final heroDetailsCard = _buildHeroDetailsCard();
    final venueSummaryCard = _buildVenueSummaryCard();

    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      labelStyle: TextStyles.font14DarkBlue600Weight.copyWith(
        color: _panelAccentColor,
      ),
      unselectedLabelStyle: TextStyles.font14Grey400Weight.copyWith(
        color: Colors.white.withOpacity(0.6),
      ),
      labelColor: _panelAccentColor,
      unselectedLabelColor: Colors.white.withOpacity(0.6),
      indicatorColor: _panelAccentColor,
      indicatorWeight: 3,
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Matches'),
        Tab(text: 'Teams'),
      ],
    );

    return Scaffold(
      backgroundColor: _profileBackgroundColor,
      floatingActionButton: _buildJoinButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: _profileBackgroundGradient,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildHeroAppBar(),
              SliverToBoxAdapter(
                child: SizedBox(height: 16.h),
              ),
              SliverToBoxAdapter(child: heroDetailsCard),
              if (venueSummaryCard != null) ...[
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                SliverToBoxAdapter(child: venueSummaryCard),
              ],
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TournamentTabBarHeaderDelegate(tabBar: tabBar),
              ),
            ],
            body: Container(
              color: Colors.transparent,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildMatchesTab(),
                  _buildTeamsTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 360.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leadingWidth: 72.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: _HeroCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsetsDirectional.only(
          start: 80.w,
          bottom: 16.h,
        ),
        title: Text(
          _tournament.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        background: _buildHeroBackground(context),
      ),
    );
  }

  List<Widget> _heroInfoChips() {
    return [
      _MiniChip(
        icon: Icons.calendar_today_rounded,
        label: DateFormat('EEE, MMM d • h:mm a').format(_tournament.startDate),
      ),
      if (_tournament.location != null && _tournament.location!.isNotEmpty)
        _MiniChip(
          icon: Icons.location_on_rounded,
          label: _tournament.location!,
        ),
      _MiniChip(
        icon: Icons.groups_rounded,
        label: '${_tournament.currentTeamsCount}/${_tournament.maxTeams} teams',
      ),
      if (_tournament.availableSpots > 0)
        _MiniChip(
          icon: Icons.event_available_rounded,
          label: '${_tournament.availableSpots} spots left',
        ),
    ];
  }

  Widget _buildHeroBackground(BuildContext context) {
    final heroImage = _tournament.imageUrl;
    final mediaPadding = MediaQuery.of(context).padding;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (heroImage != null && heroImage.isNotEmpty)
          CachedNetworkImage(
            imageUrl: heroImage,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: _panelOverlayColor,
              alignment: Alignment.center,
              child: Icon(
                _sportIcon(),
                color: Colors.white24,
                size: 56.sp,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: _panelOverlayColor,
              alignment: Alignment.center,
              child: Icon(
                _sportIcon(),
                color: Colors.white24,
                size: 56.sp,
              ),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: _panelGradient,
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.25),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
        ),
        Positioned(
          top: mediaPadding.top + 12.h,
          right: 16.w,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 360),
            tween: Tween<double>(begin: -18, end: 0),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: _AdminHeroActionButton(
              icon: Icons.dashboard_customize_outlined,
              label: 'Admin',
              onTap: _openTournamentAdminPanel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroDetailsCard() {
    final accent = _statusAccentColor();
    final description = _tournament.description.trim();
    final infoChips = _heroInfoChips();
    final entryFee = _tournament.entryFee;
    final winningPrize = _tournament.winningPrize;
    final currency =
        _tournament.metadata?['currency']?.toString().toUpperCase();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: _panelGradient,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _HeaderChip(
                  icon: _sportIcon(),
                  label: _tournament.sportType.displayName,
                ),
                _HeaderChip(
                  icon: Icons.emoji_events_rounded,
                  label: _tournament.format.displayName,
                ),
                _HeaderChip(
                  icon: Icons.flag_circle_rounded,
                  label: _tournament.status.displayName,
                  background: accent.withOpacity(0.25),
                  borderColor: accent.withOpacity(0.6),
                ),
              ],
            ),
            Gap(16.h),
            Text(
              _tournament.name,
              style: TextStyles.font24WhiteBold.copyWith(
                fontSize: 28.sp,
                height: 1.2,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              Gap(10.h),
              Text(
                description,
                style: TextStyles.font13White400Weight.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
            ],
            if (infoChips.isNotEmpty) ...[
              Gap(18.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: infoChips,
              ),
            ],
            if (entryFee != null || winningPrize != null) ...[
              Gap(18.h),
              Row(
                children: [
                  if (entryFee != null)
                    Expanded(
                      child: _PriceTile(
                        icon: Icons.monetization_on_outlined,
                        label: 'Joining Price',
                        value: _formatMoney(entryFee, currency),
                      ),
                    ),
                  if (entryFee != null && winningPrize != null) Gap(12.w),
                  if (winningPrize != null)
                    Expanded(
                      child: _PriceTile(
                        icon: Icons.emoji_events_outlined,
                        label: 'Winning Prize',
                        value: _formatMoney(winningPrize, currency),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildVenueSummaryCard() {
    final venueName =
        _selectedVenue?.name ?? _tournament.venueName?.trim() ?? '';
    final location = _selectedVenue != null
        ? '${_selectedVenue!.address.isNotEmpty ? '${_selectedVenue!.address}, ' : ''}${_selectedVenue!.city}'
        : _tournament.location?.trim() ?? '';
    final hasVenueName = venueName.isNotEmpty;
    final hasLocation = location.isNotEmpty;

    if (!hasVenueName && !hasLocation && !_isLoadingVenue) return null;

    final directionsUrl = _selectedVenue?.googleMapsLink ?? _venueDirectionsUrl();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: _panelGradient,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hosted Venue',
              style: TextStyles.font16White600Weight.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Gap(12.h),
            if (_isLoadingVenue) ...[
              const LinearProgressIndicator(),
              Gap(12.h),
            ],
            if (hasVenueName)
              InkWell(
                onTap: _openVenueDetails,
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        venueName,
                        style: TextStyles.font16White600Weight.copyWith(
                          fontSize: 18.sp,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                      Gap(6.w),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16.sp,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                ),
              ),
            if (hasLocation) ...[
              Gap(6.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  Gap(6.w),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: directionsUrl == null
                  ? null
                  : () => _openVenueDirections(directionsUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: _panelAccentColor,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              icon: const Icon(Icons.directions_rounded),
              label: Text(
                directionsUrl == null
                    ? 'Directions unavailable'
                    : 'Open Directions',
                style: TextStyles.font14DarkBlue600Weight.copyWith(
                  color: Colors.black87,
                ),
              ),
            ),
            if (directionsUrl == null) ...[
              Gap(8.h),
              Text(
                'Add a Google Maps link to share venue directions automatically.',
                style: TextStyles.font12Grey400Weight.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _venueDirectionsUrl() {
    final metadata = _tournament.metadata ?? {};
    const possibleKeys = [
      'googleMapsUrl',
      'googleMapUrl',
      'mapsUrl',
      'mapUrl',
      'mapLink',
      'directionsUrl',
      'directionsLink',
      'gmapLink',
    ];

    for (final key in possibleKeys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final location = _tournament.location;
    if (location != null && location.trim().isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location.trim())}';
    }
    return null;
  }

  Future<void> _openVenueDirections([String? url]) async {
    final target = (url ?? _venueDirectionsUrl())?.trim();
    if (target == null || target.isEmpty) {
      _showSnack('Directions link will be available soon.');
      return;
    }

    Uri? uri;
    try {
      uri = Uri.parse(target);
    } catch (_) {
      uri = null;
    }

    uri ??= Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(target)}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      _showSnack('Could not open Google Maps.');
    }
  }

  Future<void> _openVenueDetails() async {
    final venueId = _tournament.venueId;
    final venueName = _tournament.venueName ?? 'Venue';

    if (venueId == null || venueId.trim().isEmpty) {
      _showSnack('Venue details are not available yet.');
      return;
    }

    try {
      final venue = await VenueService.getVenueById(venueId);
      if (!mounted) return;

      if (venue == null) {
        _showSnack('Venue details are not available yet.');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenueProfileScreen(venue: venue),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Unable to open $venueName right now.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _statusAccentColor() {
    switch (_tournament.status) {
      case TournamentStatus.registrationOpen:
        return ColorsManager.success;
      case TournamentStatus.registrationClosed:
        return Colors.orangeAccent;
      case TournamentStatus.ongoing:
      case TournamentStatus.running:
      case TournamentStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case TournamentStatus.completed:
        return Colors.blueGrey;
      case TournamentStatus.cancelled:
        return Colors.redAccent;
      default:
        return ColorsManager.mainBlue;
    }
  }

  Widget _buildJoinRequestCard() {
    final isRegistrationOpen =
        _tournament.status == TournamentStatus.registrationOpen;
    final description = isRegistrationOpen
        ? 'Independent players and team captains can send a join request. Your form is shared directly with the organizer in chat.'
        : 'Registrations are closed, but you can still reach out with a join request. The organizer will receive your details in chat.';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: _panelGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: _panelAccentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.how_to_reg_rounded,
                  color: _panelAccentColor,
                  size: 22.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join This Tournament',
                      style: TextStyles.font16White600Weight.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      isRegistrationOpen
                          ? 'Registrations are open.'
                          : 'Registrations closed',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: isRegistrationOpen
                            ? _panelAccentColor
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            description,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          Gap(18.h),
          ElevatedButton.icon(
            onPressed: _showJoinRequestBottomSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: _panelAccentColor,
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: const Icon(Icons.send_rounded),
            label: Text(
              'Send Join Request',
              style: TextStyles.font14DarkBlue600Weight.copyWith(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildVenueInfo() {
    final venue = _selectedVenue;
    final fallbackLocation = _tournament.location;
    final hasVenue =
        venue != null || _tournament.venueId != null || fallbackLocation != null;
    if (!hasVenue) return null;

    final galleryImages = venue?.images ?? const [];
    final amenities = venue?.amenities ?? const [];

    Widget buildAmenities() {
      if (amenities.isEmpty) return const SizedBox.shrink();
      return Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: amenities
            .map(
              (amenity) => Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  amenity.name,
                  style: TextStyles.font10Grey400Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            )
            .toList(),
      );
    }

    Widget buildGallery() {
      if (galleryImages.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 110.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: galleryImages.length,
          separatorBuilder: (_, __) => Gap(12.w),
          itemBuilder: (context, index) {
            final imageUrl = galleryImages[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 140.w,
                height: 110.h,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.white.withOpacity(0.05),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.white.withOpacity(0.05),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: Colors.white54),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: _panelGradient,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _panelAccentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.pin_drop_rounded,
                  color: _panelAccentColor,
                  size: 22.sp,
                ),
              ),
              Gap(12.w),
              Text(
                'Venue & Location',
                style: TextStyles.font16White600Weight.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap(16.h),
          if (venue != null) ...[
            _buildInfoRow(
              icon: Icons.location_city_rounded,
              label: 'Venue',
              value: venue.name,
            ),
            Gap(10.h),
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value:
                  '${venue.address}${venue.city.isNotEmpty ? ', ${venue.city}' : ''}',
            ),
            if (venue.phoneNumber != null &&
                venue.phoneNumber!.trim().isNotEmpty) ...[
              Gap(10.h),
              _buildInfoRow(
                icon: Icons.call_rounded,
                label: 'Contact',
                value: venue.phoneNumber!,
              ),
            ],
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: _openVenueDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              icon: const Icon(Icons.map_rounded),
              label: const Text('View Venue Detail'),
            ),
            Gap(16.h),
            buildGallery(),
            if (galleryImages.isNotEmpty) Gap(16.h),
            buildAmenities(),
          ] else ...[
            if (_tournament.venueName != null)
              _buildInfoRow(
                icon: Icons.location_city_rounded,
                label: 'Venue',
                value: _tournament.venueName!,
              ),
            if (fallbackLocation != null) ...[
              Gap(10.h),
              _buildInfoRow(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: fallbackLocation,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _showJoinRequestBottomSheet() async {
    final userProfile = await _ensureUserProfile();
    final authUser = FirebaseAuth.instance.currentUser;

    if (userProfile == null || authUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your profile is still loading. Please try again in a moment.',
          ),
        ),
      );
      return;
    }

    if (_isOwner) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are the organizer of this tournament.'),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: userProfile.fullName);
    final emailController = TextEditingController(text: authUser.email ?? '');
    final cityController = TextEditingController(text: userProfile.location);
    final contactController = TextEditingController();
    final positionController = TextEditingController();
    final experienceController = TextEditingController();
    final notesController = TextEditingController();

    final teamSearchController = TextEditingController();
    final teamNotesController = TextEditingController();

    final individualFormKey = GlobalKey<FormState>();
    final teamFormKey = GlobalKey<FormState>();

    final skillLevels = ['Beginner', 'Intermediate', 'Advanced', 'Professional'];
    double selfRating = 6;
    String selectedSkillLevel = skillLevels[1];

    double teamSkillRating = 7;
    Team? selectedTeam;

    JoinRequestType? selectedType;
    final submission = await showModalBottomSheet<_JoinRequestSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        Widget buildJoinTypeOption({
          required IconData icon,
          required String title,
          required String subtitle,
          required JoinRequestType type,
          required StateSetter setModalState,
        }) {
          return InkWell(
            onTap: () {
              setModalState(() {
                selectedType = type;
                individualFormKey.currentState?.reset();
                teamFormKey.currentState?.reset();
              });
            },
            borderRadius: BorderRadius.circular(18.r),
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: _panelAccentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: _panelAccentColor, size: 22.sp),
                  ),
                  Gap(14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyles.font14White600Weight,
                        ),
                        Gap(4.h),
                        Text(
                          subtitle,
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16.sp,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          );
        }

        InputDecoration _fieldDecoration(String label) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white70,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: _panelAccentColor),
            ),
          );
        }

        Widget buildIndividualForm(StateSetter setModalState) {
          return Form(
            key: individualFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Join as Individual',
                  style: TextStyles.font16White600Weight,
                ),
                Gap(16.h),
                TextFormField(
                  controller: nameController,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration: _fieldDecoration('Full name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                Gap(12.h),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration: _fieldDecoration('Email'),
                ),
                Gap(12.h),
                TextFormField(
                  controller: cityController,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration: _fieldDecoration('City'),
                ),
                Gap(12.h),
                TextFormField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration: _fieldDecoration('Contact number'),
                ),
                Gap(12.h),
                TextFormField(
                  controller: positionController,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration:
                      _fieldDecoration('Preferred playing position or role'),
                ),
                Gap(12.h),
                DropdownButtonFormField<String>(
                  value: selectedSkillLevel,
                  items: skillLevels
                      .map(
                        (level) => DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        ),
                      )
                      .toList(),
                  dropdownColor: _panelColor,
                  decoration: _fieldDecoration('Skill level'),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedSkillLevel = value);
                  },
                ),
                Gap(12.h),
                TextFormField(
                  controller: experienceController,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration:
                      _fieldDecoration('Playing experience (years, leagues)'),
                ),
                Gap(16.h),
                Text(
                  'Self rating: ${selfRating.toStringAsFixed(1)}/10',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Slider(
                  value: selfRating,
                  min: 1,
                  max: 10,
                  divisions: 18,
                  activeColor: _panelAccentColor,
                  onChanged: (value) =>
                      setModalState(() => selfRating = value),
                ),
                Gap(12.h),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration: _fieldDecoration('Anything else (optional)'),
                ),
                Gap(16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() => selectedType = null);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!(individualFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          final fields = <String, String>{
                            'Player': nameController.text.trim(),
                            'City': cityController.text.trim(),
                            'Preferred Role': positionController.text.trim(),
                            'Skill Level': selectedSkillLevel,
                            'Self Rating':
                                '${selfRating.toStringAsFixed(1)}/10',
                          };
                          if (experienceController.text.trim().isNotEmpty) {
                            fields['Experience'] =
                                experienceController.text.trim();
                          }
                          if (notesController.text.trim().isNotEmpty) {
                            fields['Notes'] = notesController.text.trim();
                          }
                          Navigator.of(context).pop(
                            _JoinRequestSubmission(
                              type: JoinRequestType.individual,
                              fields: fields,
                              formResponses: {
                                'Email': emailController.text.trim(),
                                'Contact':
                                    contactController.text.trim(),
                                'City': cityController.text.trim(),
                                'Experience':
                                    experienceController.text.trim(),
                                'Skill Level': selectedSkillLevel,
                                'Self Rating':
                                    '${selfRating.toStringAsFixed(1)}/10',
                                if (notesController.text.isNotEmpty)
                                  'Additional Notes': notesController.text.trim(),
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _panelAccentColor,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: const Text('Send request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        Widget buildTeamForm(StateSetter setModalState) {
          return Form(
            key: teamFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Join as Team',
                  style: TextStyles.font16White600Weight,
                ),
                Gap(12.h),
                TextFormField(
                  controller: teamSearchController,
                  decoration: _fieldDecoration('Search your team'),
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  onChanged: (_) => setModalState(() {}),
                ),
                Gap(12.h),
                SizedBox(
                  height: 220.h,
                  child: StreamBuilder<List<Team>>(
                    stream: _teamDirectoryService.searchTeamsStream(
                      teamSearchController.text,
                      sportType: _tournament.sportType,
                      limit: 10,
                    ),
                    builder: (context, snapshot) {
                      final results = snapshot.data ?? [];
                      if (results.isEmpty) {
                        return Center(
                          child: Text(
                            'No teams found. Try a different name.',
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final team = results[index];
                          final isSelected = selectedTeam?.id == team.id;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                            leading: CircleAvatar(
                              backgroundImage: team.teamImageUrl != null
                                  ? NetworkImage(team.teamImageUrl!)
                                  : null,
                              child: team.teamImageUrl == null
                                  ? Text(team.name[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(
                              team.name,
                              style: TextStyles.font14White600Weight,
                            ),
                            subtitle: Text(
                              team.location ?? 'No location',
                              style: TextStyles.font10Grey400Weight,
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: _panelAccentColor)
                                : null,
                            onTap: () {
                              setModalState(() => selectedTeam = team);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Gap(12.h),
                Text(
                  'Team skill rating: ${teamSkillRating.toStringAsFixed(1)}/10',
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Slider(
                  value: teamSkillRating,
                  min: 1,
                  max: 10,
                  divisions: 18,
                  activeColor: _panelAccentColor,
                  onChanged: (value) =>
                      setModalState(() => teamSkillRating = value),
                ),
                Gap(12.h),
                TextFormField(
                  controller: teamNotesController,
                  maxLines: 3,
                  style:
                      TextStyles.font14White400Weight.copyWith(color: Colors.white),
                  decoration:
                      _fieldDecoration('Message for organizer (optional)'),
                ),
                Gap(16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() => selectedType = null);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedTeam == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a team first.'),
                              ),
                            );
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          final fields = <String, String>{
                            'Team': selectedTeam!.name,
                            'Captain / Contact': userProfile.fullName,
                            'Team Rating':
                                '${teamSkillRating.toStringAsFixed(1)}/10',
                          };
                          if (teamNotesController.text.trim().isNotEmpty) {
                            fields['Notes'] = teamNotesController.text.trim();
                          }
                          Navigator.of(context).pop(
                            _JoinRequestSubmission(
                              type: JoinRequestType.team,
                              fields: fields,
                              formResponses: {
                                'Captain': userProfile.fullName,
                                'Team Location':
                                    selectedTeam!.location ?? 'Not provided',
                                'Team Rating':
                                    '${teamSkillRating.toStringAsFixed(1)}/10',
                                if (teamNotesController.text.isNotEmpty)
                                  'Notes': teamNotesController.text.trim(),
                              },
                              selectedTeam: selectedTeam,
                              teamSkillRating: teamSkillRating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _panelAccentColor,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: const Text('Send request'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    Gap(16.h),
                    if (selectedType == null) ...[
                      Text(
                        'Request to Join',
                        style: TextStyles.font16White600Weight.copyWith(
                          fontSize: 18.sp,
                        ),
                      ),
                      Gap(12.h),
                      buildJoinTypeOption(
                        icon: Icons.groups_rounded,
                        title: 'Join as Team',
                        subtitle:
                            'Submit your club or squad to participate together.',
                        type: JoinRequestType.team,
                        setModalState: setModalState,
                      ),
                      Gap(12.h),
                      buildJoinTypeOption(
                        icon: Icons.person_outline_rounded,
                        title: 'Join as Individual',
                        subtitle:
                            'Share your profile to be drafted by a tournament team.',
                        type: JoinRequestType.individual,
                        setModalState: setModalState,
                      ),
                    ] else if (selectedType == JoinRequestType.team) ...[
                      buildTeamForm(setModalState),
                    ] else ...[
                      buildIndividualForm(setModalState),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    cityController.dispose();
    contactController.dispose();
    positionController.dispose();
    experienceController.dispose();
    notesController.dispose();
    teamSearchController.dispose();
    teamNotesController.dispose();

    if (submission == null) return;
    await _submitJoinRequest(submission);
  }

  Future<void> _submitJoinRequest(_JoinRequestSubmission submission) async {
    final userProfile = await _ensureUserProfile();
    if (userProfile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not load your profile. Please try again.'),
        ),
      );
      return;
    }

    if (_isOwner) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Organizers cannot send join requests to their own tournaments.'),
        ),
      );
      return;
    }

    try {
      String? newRequestId;
      if (submission.type == JoinRequestType.team) {
        final team = submission.selectedTeam;
        if (team == null) {
          throw Exception('Please select a team before submitting.');
        }
        newRequestId = await _matchService.createJoinRequest(
          tournamentId: _tournament.id,
          isTeamRequest: true,
          teamId: team.id,
          teamName: team.name,
          teamLogoUrl: team.teamImageUrl,
          sport: _tournament.sportType.name,
          formResponses: submission.formResponses,
          bio: (submission.formResponses['Notes'] as String?) ?? '',
        );

        // Notify team owner that a request was sent
        if (team.ownerId.isNotEmpty) {
          await _notificationService.createGeneralNotification(
            userId: team.ownerId,
            title: 'Tournament request sent',
            message:
                '${userProfile.fullName} submitted ${team.name} for ${_tournament.name}',
            data: {
              'tournamentId': _tournament.id,
              'teamId': team.id,
              'requestId': newRequestId,
            },
          );
        }
      } else {
        newRequestId = await _matchService.createJoinRequest(
          tournamentId: _tournament.id,
          isTeamRequest: false,
          sport: _tournament.sportType.name,
          position: submission.fields['Preferred Role'],
          skillLevel: submission.formResponses['Skill Level'] != null
              ? _parseSkillLevel(submission.formResponses['Skill Level'])
              : null,
          formResponses: submission.formResponses,
          bio: (submission.formResponses['Additional Notes'] as String?) ?? '',
        );
      }

      final chatRoom =
          await _chatService.getOrCreateDirectChat(_tournament.organizerId);
      if (chatRoom == null) {
        throw Exception('Unable to open chat with the organizer.');
      }

      final message = _composeJoinRequestMessage(
        submission,
        requesterName: userProfile.fullName,
      );
      final sent = await _chatService.sendTextMessage(
        chatId: chatRoom.id,
        text: message,
      );

      if (!sent) {
        throw Exception('Chat message could not be delivered.');
      }

      await _notificationService.createGeneralNotification(
        userId: _tournament.organizerId,
        title: 'New join request',
        message:
            '${userProfile.fullName} sent a ${submission.type == JoinRequestType.team ? 'team' : 'player'} request for ${_tournament.name}',
        data: {
          'tournamentId': _tournament.id,
          if (newRequestId != null) 'requestId': newRequestId,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request shared with the organizer.'),
        ),
      );

      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoom: chatRoom,
              backgroundImageUrl: _tournament.imageUrl,
              triggerCelebration: true,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send join request: $error'),
        ),
      );
    }
  }

  String _composeJoinRequestMessage(
    _JoinRequestSubmission submission, {
    String? requesterName,
  }) {
    final requester = requesterName ?? _currentUserProfile?.fullName ?? 'Unknown player';
    final buffer = StringBuffer()
      ..writeln(
        submission.type == JoinRequestType.team
            ? '📝 Team join request received'
            : '📝 Individual join request received',
      )
      ..writeln('Tournament: ${_tournament.name}')
      ..writeln('Requester: $requester')
      ..writeln('');

    submission.fields.forEach((label, value) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        buffer.writeln('• $label: $trimmed');
      }
    });

    submission.formResponses.forEach((label, dynamic value) {
      final display = value?.toString().trim();
      if (display == null || display.isEmpty) return;
      buffer.writeln('• $label: $display');
    });

    buffer
      ..writeln('')
      ..writeln(
        'Sent on ${DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now())}',
      );

    return buffer.toString();
  }

  int? _parseSkillLevel(dynamic label) {
    if (label == null) return null;
    final value = label.toString().toLowerCase();
    if (value.contains('beginner')) return 3;
    if (value.contains('intermediate')) return 5;
    if (value.contains('advanced')) return 7;
    if (value.contains('pro')) return 9;
    final numeric = double.tryParse(label.toString());
    return numeric?.round();
  }

  Widget? _buildRulesSection() {
    if (_tournament.rules.isEmpty) return null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: _panelGradient,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _panelAccentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.rule_rounded,
                  color: _panelAccentColor,
                  size: 22.sp,
                ),
              ),
              Gap(12.w),
              Text(
                'Rules & Regulations',
                style: TextStyles.font16White600Weight.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap(16.h),
          ..._tournament.rules.asMap().entries.map(
                (entry) => Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: _panelAccentColor.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyles.font12BlueRegular.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Gap(12.w),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyles.font14White400Weight.copyWith(
                            color: Colors.white.withOpacity(0.85),
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

  String _formatMoney(double amount, String? currencyCode) {
    final effectiveCurrency = currencyCode?.toUpperCase();
    final symbol = switch (effectiveCurrency) {
      'PKR' => '₨',
      'USD' => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'INR' => '₹',
      _ => effectiveCurrency ?? '\$',
    };

    final formatter = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: symbol,
      name: effectiveCurrency,
    );
    return formatter.format(amount);
  }

  IconData _sportIcon() {
    final sport = _tournament.sportType.displayName.toLowerCase();
    if (sport.contains('cricket')) return Icons.sports_cricket_rounded;
    if (sport.contains('football') || sport.contains('soccer')) {
      return Icons.sports_soccer_rounded;
    }
    if (sport.contains('basketball')) return Icons.sports_basketball_rounded;
    if (sport.contains('tennis') || sport.contains('badminton')) {
      return Icons.sports_tennis_rounded;
    }
    if (sport.contains('volleyball')) return Icons.sports_volleyball_rounded;
    if (sport.contains('swimming')) return Icons.pool_rounded;
    if (sport.contains('running')) return Icons.directions_run_rounded;
    if (sport.contains('cycling')) return Icons.directions_bike_rounded;
    if (sport.contains('hockey')) return Icons.sports_hockey_rounded;
    return Icons.emoji_events_rounded;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: _panelAccentColor,
        ),
        Gap(8.w),
        Text(
          '$label: ',
          style: TextStyles.font12White600Weight.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyles.font12White500Weight.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }

  bool get _allowDemoContent {
    final metaFlag =
        _tournament.metadata?['enableDemoContent'] as bool? ?? false;
    if (metaFlag) return true;
    return _isRoyalSportsLeague || _isRegionalSportsLeague;
  }

  void _applyDemoMatchesIfNeeded() {
    if (_demoMatchesApplied || !_allowDemoContent) return;

    final hasMatches = _allMatches.isNotEmpty ||
        _liveMatches.isNotEmpty ||
        _todayMatches.isNotEmpty ||
        _futureMatches.isNotEmpty ||
        _pastMatches.isNotEmpty;
    if (hasMatches) return;

    List<TournamentMatch>? demoMatches;
    if (_isRoyalSportsLeague) {
      demoMatches = _buildRoyalSportsLeagueDemoMatches();
    } else if (_isRegionalSportsLeague) {
      demoMatches = _buildRegionalSportsLeagueDemoMatches();
    } else {
      demoMatches = _buildSportSpecificDemoMatches();
    }

    if (demoMatches == null || demoMatches.isEmpty) return;

    _demoMatchesApplied = true;
    _usingDemoMatches = true;
    _allMatches = demoMatches;
    _categorizeMatches(demoMatches);
  }

  void _applyDemoStandingsIfNeeded() {
    if (_demoStandingsApplied || _teamStandings.isNotEmpty || !_allowDemoContent) {
      return;
    }

    _demoStandingsApplied = true;
    _usingDemoStandings = true;

    final demoTeams = _isRegionalSportsLeague
        ? _buildRegionalSportsLeagueDemoTeams()
        : _buildGenericDemoTeams();
    if (demoTeams.isEmpty) return;
    _teamStandings = {
      for (final team in demoTeams) team.id: team.points,
    };
    _activeTeams = demoTeams;
    _teamLookup = {
      for (final team in demoTeams) team.id: team,
    };
  }

  List<TournamentMatch> _buildRoyalSportsLeagueDemoMatches() {
    final now = DateTime.now();
    final venueName = _tournament.venueName;
    final venueLocation = _tournament.location;

    TournamentMatch createMatch({
      required String id,
      required String matchNumber,
      required String team1Id,
      required String team1Name,
      required int team1Score,
      required String team2Id,
      required String team2Name,
      required int team2Score,
      required DateTime scheduledTime,
      DateTime? actualStartTime,
      DateTime? actualEndTime,
      TournamentMatchStatus status = TournamentMatchStatus.scheduled,
      String? round,
      String? result,
    }) {
      return TournamentMatch(
        id: id,
        tournamentId: _tournament.id,
        tournamentName: _tournament.name,
        sportType: _tournament.sportType,
        matchNumber: matchNumber,
        round: round,
        team1: TeamMatchScore(
          teamId: team1Id,
          teamName: team1Name,
          score: team1Score,
          playerIds: const [],
        ),
        team2: TeamMatchScore(
          teamId: team2Id,
          teamName: team2Name,
          score: team2Score,
          playerIds: const [],
        ),
        scheduledTime: scheduledTime,
        actualStartTime: actualStartTime,
        actualEndTime: actualEndTime,
        status: status,
        venueName: venueName,
        venueLocation: venueLocation,
        result: result,
      );
    }

    return [
      createMatch(
        id: 'demo-rsl-live-1',
        matchNumber: 'Match 12',
        team1Id: 'rsl-mavericks',
        team1Name: 'Multan Mavericks',
        team1Score: 2,
        team2Id: 'rsl-lightning',
        team2Name: 'Lahore Lightning',
        team2Score: 1,
        scheduledTime: now.subtract(const Duration(minutes: 70)),
        actualStartTime: now.subtract(const Duration(minutes: 70)),
        status: TournamentMatchStatus.live,
        round: 'League Stage',
        result: '78\' • Second Half',
      ),
      createMatch(
        id: 'demo-rsl-upcoming-1',
        matchNumber: 'Match 13',
        team1Id: 'rsl-royals',
        team1Name: 'Karachi Royals',
        team1Score: 0,
        team2Id: 'rsl-warriors',
        team2Name: 'Islamabad Warriors',
        team2Score: 0,
        scheduledTime: now.add(const Duration(hours: 5)),
        status: TournamentMatchStatus.scheduled,
        round: 'League Stage',
        result: 'Kick-off at ${DateFormat('h:mm a').format(now.add(const Duration(hours: 5)))}',
      ),
      createMatch(
        id: 'demo-rsl-completed-1',
        matchNumber: 'Match 11',
        team1Id: 'rsl-guardians',
        team1Name: 'Golden Guardians',
        team1Score: 3,
        team2Id: 'rsl-stallions',
        team2Name: 'Sapphire Stallions',
        team2Score: 2,
        scheduledTime: now.subtract(const Duration(days: 1)),
        actualStartTime: now.subtract(const Duration(days: 1)),
        actualEndTime:
            now.subtract(const Duration(days: 1)).add(const Duration(minutes: 95)),
        status: TournamentMatchStatus.completed,
        round: 'League Stage',
        result: 'Golden Guardians won 3-2',
      ),
    ];
  }

  List<TournamentMatch> _buildRegionalSportsLeagueDemoMatches() {
    final now = DateTime.now();

    TournamentMatch buildMatch({
      required String id,
      required String matchNumber,
      required String team1Id,
      required String team1Name,
      required int team1Score,
      required String team2Id,
      required String team2Name,
      required int team2Score,
      required DateTime scheduledTime,
      TournamentMatchStatus status = TournamentMatchStatus.scheduled,
      String? round,
      DateTime? actualStart,
      DateTime? actualEnd,
      String? result,
      List<CommentaryEntry> commentary = const [],
      List<PlayerMatchStats> team1Stats = const [],
      List<PlayerMatchStats> team2Stats = const [],
    }) {
      return TournamentMatch(
        id: id,
        tournamentId: _tournament.id,
        tournamentName: _tournament.name,
        sportType: _tournament.sportType,
        matchNumber: matchNumber,
        round: round ?? 'League Stage',
        scheduledTime: scheduledTime,
        actualStartTime: actualStart,
        actualEndTime: actualEnd,
        status: status,
        result: result,
        commentary: commentary,
        team1: TeamMatchScore(
          teamId: team1Id,
          teamName: team1Name,
          score: team1Score,
        ),
        team2: TeamMatchScore(
          teamId: team2Id,
          teamName: team2Name,
          score: team2Score,
        ),
        team1PlayerStats: team1Stats,
        team2PlayerStats: team2Stats,
        venueName: _tournament.venueName ?? 'National Stadium',
        venueLocation: _tournament.location ?? 'Pakistan',
      );
    }

    final liveCommentary = [
      CommentaryEntry(
        id: 'regional-live-1',
        text: 'Haris Iqbal curls one into the top corner!',
        minute: '72\'',
        timestamp: now.subtract(const Duration(minutes: 8)),
        eventType: 'goal',
        playerName: 'Haris Iqbal',
      ),
      CommentaryEntry(
        id: 'regional-live-2',
        text: 'Sheryar Malik denies a sure goal with a sliding tackle.',
        minute: '75\'',
        timestamp: now.subtract(const Duration(minutes: 5)),
        eventType: 'defense',
        playerName: 'Sheryar Malik',
      ),
    ];

    final completedCommentary = [
      CommentaryEntry(
        id: 'regional-completed-1',
        text: 'Final whistle! Royals close it out in dramatic fashion.',
        minute: '90+3\'',
        timestamp: now.subtract(const Duration(hours: 16)),
        eventType: 'summary',
      ),
      CommentaryEntry(
        id: 'regional-completed-2',
        text: 'Adeel Sarfraz scores a stoppage-time header!',
        minute: '90+1\'',
        timestamp: now.subtract(const Duration(hours: 16, minutes: 2)),
        eventType: 'goal',
        playerName: 'Adeel Sarfraz',
      ),
    ];

    return [
      buildMatch(
        id: 'demo-regional-live',
        matchNumber: 'Match 28',
        team1Id: 'rsl-mavericks',
        team1Name: 'Multan Mavericks',
        team1Score: 2,
        team2Id: 'rsl-lightning',
        team2Name: 'Lahore Lightning',
        team2Score: 2,
        status: TournamentMatchStatus.live,
        scheduledTime: now.subtract(const Duration(minutes: 90)),
        actualStart: now.subtract(const Duration(minutes: 90)),
        result: '78\' • Second Half',
        commentary: liveCommentary,
        team1Stats: const [
          PlayerMatchStats(playerId: 'haris', playerName: 'Haris Iqbal', goals: 1, assists: 1),
          PlayerMatchStats(playerId: 'zeeshan', playerName: 'Zeeshan Tariq', goals: 1),
        ],
        team2Stats: const [
          PlayerMatchStats(playerId: 'fahad', playerName: 'Fahad Mehmood', goals: 1, assists: 1),
          PlayerMatchStats(playerId: 'adil', playerName: 'Adil Bashir', goals: 1),
        ],
      ),
      buildMatch(
        id: 'demo-regional-upcoming',
        matchNumber: 'Match 29',
        team1Id: 'rsl-royals',
        team1Name: 'Karachi Royals',
        team1Score: 0,
        team2Id: 'rsl-warriors',
        team2Name: 'Islamabad Warriors',
        team2Score: 0,
        status: TournamentMatchStatus.scheduled,
        scheduledTime: now.add(const Duration(hours: 6)),
        result: 'Kick-off at ${DateFormat('h:mm a').format(now.add(const Duration(hours: 6)))}',
        team1Stats: const [
          PlayerMatchStats(playerId: 'royals-cpt', playerName: 'Saad Rauf'),
        ],
        team2Stats: const [
          PlayerMatchStats(playerId: 'warriors-cpt', playerName: 'Adeel Sarfraz'),
        ],
      ),
      buildMatch(
        id: 'demo-regional-completed',
        matchNumber: 'Match 27',
        team1Id: 'rsl-guardians',
        team1Name: 'Golden Guardians',
        team1Score: 3,
        team2Id: 'rsl-stallions',
        team2Name: 'Sapphire Stallions',
        team2Score: 1,
        status: TournamentMatchStatus.completed,
        scheduledTime: now.subtract(const Duration(hours: 20)),
        actualStart: now.subtract(const Duration(hours: 20)),
        actualEnd: now.subtract(const Duration(hours: 18, minutes: 45)),
        result: 'Golden Guardians won 3-1',
        commentary: completedCommentary,
        team1Stats: const [
          PlayerMatchStats(playerId: 'guardian-7', playerName: 'Imran Aziz', goals: 2, assists: 1),
          PlayerMatchStats(playerId: 'guardian-4', playerName: 'Usman Tariq', goals: 1),
        ],
        team2Stats: const [
          PlayerMatchStats(playerId: 'stallion-9', playerName: 'Bilal Hashmi', goals: 1),
        ],
      ),
    ];
  }

  List<TournamentMatch> _buildSportSpecificDemoMatches() {
    final teamNames = _demoTeamNamesForSport();
    if (teamNames.length < 4) return [];

    final now = DateTime.now();
    final venueName = _tournament.venueName ?? '${_tournament.location ?? 'Central'} Arena';

    TournamentMatch createMatch({
      required String id,
      required String team1Name,
      required int team1Score,
      required String team2Name,
      required int team2Score,
      required TournamentMatchStatus status,
      required DateTime scheduledTime,
      String? result,
    }) {
      return TournamentMatch(
        id: id,
        tournamentId: _tournament.id,
        tournamentName: _tournament.name,
        sportType: _tournament.sportType,
        matchNumber: 'Match ${id.hashCode.abs() % 50 + 1}',
        round: 'Main Stage',
        scheduledTime: scheduledTime,
        actualStartTime:
            status == TournamentMatchStatus.scheduled ? null : scheduledTime,
        status: status,
        result: result,
        team1: TeamMatchScore(
          teamId: _normalizeTeamId(team1Name),
          teamName: team1Name,
          score: team1Score,
        ),
        team2: TeamMatchScore(
          teamId: _normalizeTeamId(team2Name),
          teamName: team2Name,
          score: team2Score,
        ),
        venueName: venueName,
        venueLocation: _tournament.location ?? 'Global Venue',
      );
    }

    final upcomingTime = now.add(const Duration(hours: 5));
    final completedTime = now.subtract(const Duration(hours: 18));

    return [
      createMatch(
        id: 'demo-${_tournament.id}-live',
        team1Name: teamNames[0],
        team1Score: 2,
        team2Name: teamNames[1],
        team2Score: 1,
        status: TournamentMatchStatus.live,
        scheduledTime: now.subtract(const Duration(minutes: 70)),
        result: _liveStatusDescription(),
      ),
      createMatch(
        id: 'demo-${_tournament.id}-upcoming',
        team1Name: teamNames[2],
        team1Score: 0,
        team2Name: teamNames[3],
        team2Score: 0,
        status: TournamentMatchStatus.scheduled,
        scheduledTime: upcomingTime,
        result: _upcomingStatusDescription(upcomingTime),
      ),
      createMatch(
        id: 'demo-${_tournament.id}-completed',
        team1Name: teamNames[4 % teamNames.length],
        team1Score: 3,
        team2Name: teamNames[5 % teamNames.length],
        team2Score: 2,
        status: TournamentMatchStatus.completed,
        scheduledTime: completedTime,
        result: _completedResultDescription(
          teamNames[4 % teamNames.length],
          3,
          teamNames[5 % teamNames.length],
          2,
        ),
      ),
    ];
  }

  List<TournamentTeam> _buildGenericDemoTeams() {
    final teamNames = _demoTeamNamesForSport();
    if (teamNames.isEmpty) return [];

    final configurations = [
      const (wins: 4, draws: 1, losses: 0, points: 13, goalsFor: 18, goalsAgainst: 7),
      const (wins: 3, draws: 1, losses: 1, points: 10, goalsFor: 15, goalsAgainst: 9),
      const (wins: 2, draws: 1, losses: 2, points: 7, goalsFor: 11, goalsAgainst: 10),
      const (wins: 1, draws: 2, losses: 2, points: 5, goalsFor: 9, goalsAgainst: 12),
    ];

    return List.generate(configurations.length, (index) {
      final name = teamNames[index % teamNames.length];
      final config = configurations[index];
      return TournamentTeam(
        id: _normalizeTeamId(name),
        tournamentId: _tournament.id,
        name: name,
        playerNames: _generatePlayerNames(name),
        wins: config.wins,
        draws: config.draws,
        losses: config.losses,
        points: config.points,
        goalsFor: config.goalsFor,
        goalsAgainst: config.goalsAgainst,
      );
    });
  }

  List<String> _demoTeamNamesForSport() {
    switch (_tournament.sportType) {
      case SportType.cricket:
        return [
          'Boundary Breakers',
          'Spin Wizards',
          'Pace Titans',
          'Century Kings',
          'Power Hitters',
          'Yorker Squad',
        ];
      case SportType.football:
      case SportType.soccer:
        return [
          'Metro United',
          'Harbor City FC',
          'Capital Strikers',
          'Coastal Rangers',
          'Northern Royals',
          'Southern Titans',
        ];
      case SportType.basketball:
        return [
          'Skyline Hoopsters',
          'Downtown Flyers',
          'Baseline Kings',
          'Summit Dunkers',
          'Neon Nets',
          'Prime Shooters',
        ];
      case SportType.tennis:
        return [
          'Baseline Masters',
          'Spin Artists',
          'Grand Slam Club',
          'Court Aces',
          'Topspin Legends',
          'Rally Titans',
        ];
      case SportType.badminton:
        return [
          'Feather Flyers',
          'Drop Shot Pros',
          'Smash Factory',
          'Net Dominators',
          'Rally Ninjas',
          'Drive Force',
        ];
      case SportType.volleyball:
        return [
          'Spike Society',
          'Block Brigade',
          'Serve Savants',
          'Coastal Diggers',
          'Set Masters',
          'Rally Rebels',
        ];
      case SportType.hockey:
        return [
          'Glacier Blades',
          'Arctic Wolves',
          'Metro Stickmen',
          'Capital Ice',
          'Steel Panthers',
          'Frost Giants',
        ];
      case SportType.rugby:
        return [
          'Scrum Force',
          'Maul Masters',
          'Try City',
          'Ruck Raiders',
          'Lineout Legends',
          'Tackle Titans',
        ];
      case SportType.baseball:
        return [
          'Diamond Aces',
          'Grand Slammers',
          'Pitch Perfect',
          'Home Run Heroes',
          'Batting Brigade',
          'Fastball Flyers',
        ];
      case SportType.cycling:
        return [
          'Peloton Prime',
          'Sprint Syndicate',
          'Hill Climbers',
          'Aero Alliance',
          'Velocity Vanguards',
          'Cadence Crew',
        ];
      case SportType.running:
        return [
          'Marathon Mavericks',
          'Sprint Collective',
          'Ultra Finishers',
          'Track Titans',
          'Pace Setters',
          'Stride Society',
        ];
      case SportType.swimming:
        return [
          'Wave Runners',
          'Aqua Surge',
          'Lane Legends',
          'Stroke Masters',
          'Tide Breakers',
          'Splash Squad',
        ];
      case SportType.other:
        return [
          'Alpha Titans',
          'Velocity Crew',
          'Nova Legends',
          'Blue Comets',
          'Onyx Guardians',
          'Solar Sparks',
        ];
    }
  }

  String _normalizeTeamId(String name) =>
      name.toLowerCase().replaceAll(' ', '-');

  List<String> _generatePlayerNames(String teamName) {
    final prefix = teamName.split(' ').first;
    return List.generate(3, (index) => '$prefix Player ${index + 1}');
  }

  String _liveStatusDescription() {
    switch (_tournament.sportType) {
      case SportType.cricket:
        return 'Over 15 • Second Innings';
      case SportType.basketball:
        return 'Q3 • 04:12';
      case SportType.tennis:
        return 'Set 3 • Game 5';
      case SportType.badminton:
        return 'Game 2 • Rally 18';
      case SportType.volleyball:
        return 'Set 4 • 18-16';
      case SportType.hockey:
        return 'Period 3 • 05:30';
      case SportType.rugby:
        return 'Second Half • 62\'';
      case SportType.baseball:
        return 'Inning 7 • Top';
      case SportType.cycling:
        return 'Stage 4 • KM 120';
      case SportType.running:
        return 'Lap 6 • 24 km';
      case SportType.swimming:
        return 'Final Heat • 150m';
      case SportType.football:
      case SportType.soccer:
      case SportType.other:
        return '78\' • Second Half';
    }
  }

  String _completedResultDescription(
    String winner,
    int winnerScore,
    String runnerUp,
    int runnerUpScore,
  ) {
    switch (_tournament.sportType) {
      case SportType.cricket:
        return '$winner won by ${winnerScore - runnerUpScore} runs';
      case SportType.tennis:
      case SportType.badminton:
        return '$winner won ${winnerScore}-${runnerUpScore} sets';
      case SportType.cycling:
        return '$winner topped the stage, ${runnerUp} finished close';
      case SportType.running:
        return '$winner posted a blazing finish';
      default:
        return '$winner won $winnerScore-$runnerUpScore';
    }
  }

  String _upcomingStatusDescription(DateTime time) {
    final formatted = DateFormat('h:mm a').format(time);
    switch (_tournament.sportType) {
      case SportType.cycling:
        return 'Stage rollout at $formatted';
      case SportType.running:
        return 'Race start at $formatted';
      case SportType.cricket:
        return 'First ball at $formatted';
      default:
        return 'Kick-off at $formatted';
    }
  }

  List<TournamentTeam> _buildRegionalSportsLeagueDemoTeams() {
    return [
      TournamentTeam(
        id: 'rsl-multan',
        tournamentId: _tournament.id,
        name: 'Multan Mavericks',
        playerNames: const ['Haris Iqbal', 'Zeeshan Tariq', 'Usman Jalal'],
        wins: 4,
        draws: 1,
        losses: 0,
        points: 13,
        goalsFor: 18,
        goalsAgainst: 7,
      ),
      TournamentTeam(
        id: 'rsl-karachi',
        tournamentId: _tournament.id,
        name: 'Karachi Kingslayers',
        playerNames: const ['Saad Rauf', 'Rizwan Shah', 'Sheryar Malik'],
        wins: 3,
        draws: 1,
        losses: 1,
        points: 10,
        goalsFor: 16,
        goalsAgainst: 9,
      ),
      TournamentTeam(
        id: 'rsl-lahore',
        tournamentId: _tournament.id,
        name: 'Lahore Lightning',
        playerNames: const ['Fahad Mehmood', 'Imran Raza', 'Adil Bashir'],
        wins: 2,
        draws: 2,
        losses: 1,
        points: 8,
        goalsFor: 14,
        goalsAgainst: 12,
      ),
      TournamentTeam(
        id: 'rsl-islamabad',
        tournamentId: _tournament.id,
        name: 'Islamabad Icebreakers',
        playerNames: const ['Adeel Sarfraz', 'Raheel Abbas', 'Moin Qureshi'],
        wins: 1,
        draws: 1,
        losses: 3,
        points: 4,
        goalsFor: 9,
        goalsAgainst: 15,
      ),
    ];
  }

  Widget _buildJoinButton() {
    if (_tournament.status != TournamentStatus.registrationOpen) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ElevatedButton(
        onPressed: _isRegistering ? null : _navigateToTeamRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: _panelAccentColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 4,
        ),
        child: _isRegistering
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add,
                    size: 20.sp,
                  ),
                  Gap(8.w),
                  Text(
                    'Register Team',
                    style: TextStyles.font16White600Weight,
                  ),
                ],
              ),
      ),
    );
  }

  void _navigateToTeamRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentTeamRegistrationScreen(
          tournament: _tournament,
        ),
      ),
    );
  }

  // ============ TAB BUILDERS ============

  Widget _buildOverviewTab() {
    final sections = <Widget>[];

    sections.add(_buildJoinRequestCard());

    final venue = _buildVenueInfo();
    if (venue != null) {
      sections.add(Gap(16.h));
      sections.add(venue);
    }

    final rules = _buildRulesSection();
    if (rules != null) {
      sections.add(Gap(16.h));
      sections.add(rules);
    }

    if (sections.isEmpty) {
      sections.add(
        _buildEmptyState(
          'Tournament details will appear here soon.',
          Icons.info_outline_rounded,
        ),
      );
    }

    sections.add(SizedBox(height: 120.h));

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  Widget _buildMatchesTab() {
    final sections = <Widget>[];

    void addSection(String title, List<TournamentMatch> matches,
        {Color? accent, bool highlightLive = false}) {
      if (matches.isEmpty) return;
      if (sections.isNotEmpty) {
        sections.add(Gap(24.h));
      }
      sections.add(
        _buildMatchSection(
          title,
          matches,
          accent,
          highlightLive: highlightLive,
        ),
      );
    }

    final upcomingMatches = [..._todayMatches, ..._futureMatches];

    addSection(
      'Running Matches',
      _liveMatches,
      accent: Colors.redAccent,
      highlightLive: true,
    );

    addSection(
      'Upcoming Matches',
      upcomingMatches,
      accent: ColorsManager.primary,
    );

    addSection(
      'Completed Matches',
      _pastMatches,
      accent: Colors.greenAccent,
    );

    Widget content;
    if (sections.isEmpty) {
      content =
          _buildEmptyState('No matches scheduled yet', Icons.sports_cricket);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: _panelGradient,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: content,
          ),
          Gap(120.h),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    final standingsContent = _teamStandings.isNotEmpty
        ? _buildStandingsTable(withBackground: false)
        : _buildEmptyState('No standings available yet', Icons.leaderboard);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: _panelGradient,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Standings',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Gap(16.h),
                standingsContent,
              ],
            ),
          ),
          SizedBox(height: 120.h),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    final teams = _activeTeams;
    if (teams.isEmpty && !_usingDemoStandings) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: TournamentTeamsList(tournamentId: _tournament.id),
      );
    }

    final displayTeams = teams.isNotEmpty ? teams : _activeTeams;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      itemCount: displayTeams.length,
      itemBuilder: (context, index) {
        final team = displayTeams[index];
        return _buildTeamCard(team);
      },
    );
  }

  // ============ HELPER METHODS ============

  Widget _buildDemoTeamTile(TournamentTeam team) {
    final record = '${team.wins}W • ${team.draws}D • ${team.losses}L';
    final players = team.playerNames.isNotEmpty
        ? team.playerNames.join(', ')
        : 'Roster to be announced';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: _panelAccentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
              style: TextStyles.font16White600Weight,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.name,
                        style: TextStyles.font14White600Weight.copyWith(
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    Text(
                      '${team.points} pts',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: _panelAccentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Gap(6.h),
                Text(
                  record,
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Gap(6.h),
                Text(
                  players,
                  style: TextStyles.font12Grey400Weight.copyWith(
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(TournamentTeam team) {
    final record = 'Wins: ${team.wins}    Draws: ${team.draws}    Losses: ${team.losses}';
    final captain = team.captainName ?? 'Not assigned';
    final avatarInitial =
        team.name.isNotEmpty ? team.name.characters.first.toUpperCase() : 'T';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        onTap: () => _openTeamDetails(team),
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _panelAccentColor,
                      _panelAccentColor.withOpacity(0.6),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarInitial,
                  style: TextStyles.font20DarkBlueBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyles.font16White600Weight,
                    ),
                    Gap(6.h),
                    Text(
                      record,
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      'Captain: $captain',
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchSection(
    String title,
    List<TournamentMatch> matches,
    Color? accent, {
    bool highlightLive = false,
  }) {
    final Color lineColor = accent ?? Colors.white.withOpacity(0.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Gap(8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Gap(12.h),
        ...matches
            .map(
              (match) => _buildMatchCard(
                match,
                accentOverride: accent,
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildMatchCard(
    TournamentMatch match, {
    Color? accentOverride,
  }) {
    final accent = accentOverride ?? _matchStatusColor(match.status);
    final statusLabel = _matchStatusLabel(match);
    final isLive = match.status == TournamentMatchStatus.live;
    final hasScores = match.status == TournamentMatchStatus.live ||
        match.status == TournamentMatchStatus.completed;
    final centerPrimary = hasScores
        ? '${match.team1Score} - ${match.team2Score}'
        : DateFormat('h:mm a').format(match.scheduledTime);
    final centerSecondary = hasScores
        ? (isLive
            ? 'Live'
            : (match.result?.isNotEmpty == true ? match.result! : 'Full Time'))
        : (match.venueName ??
            match.venueLocation ??
            (_tournament.venueName ?? 'Venue TBA'));
    final scheduleLabel =
        DateFormat('EEE, MMM d • h:mm a').format(match.scheduledTime);
    final team1Leading = match.team1Score > match.team2Score;
    final team2Leading = match.team2Score > match.team1Score;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () => _openMatchDetails(match),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: PublicProfileTheme.panelGradient,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: PublicProfileTheme.defaultShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.matchNumber,
                          style: TextStyles.font14DarkBlueMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (match.round != null && match.round!.isNotEmpty) ...[
                          Gap(2.h),
                          Text(
                            match.round!,
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ] else ...[
                          Gap(2.h),
                          Text(
                            '${match.sportType.displayName} • ${match.status.displayName}',
                            style: TextStyles.font12Grey400Weight.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(statusLabel, accent, isLive),
                ],
              ),
              Gap(18.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTeamColumn(
                      team: match.team1,
                      score: match.team1Score,
                      accent: accent,
                      hasScores: hasScores,
                      isLeading: team1Leading,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerPrimary,
                          style: TextStyles.font20DarkBlueBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Gap(4.h),
                        Text(
                          centerSecondary,
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color:
                                isLive ? accent : Colors.white.withOpacity(0.9),
                            fontWeight:
                                isLive ? FontWeight.w700 : FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildTeamColumn(
                      team: match.team2,
                      score: match.team2Score,
                      accent: accent,
                      hasScores: hasScores,
                      isLeading: team2Leading,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              Gap(18.h),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      scheduleLabel,
                      style: TextStyles.font12Grey400Weight.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
              if (match.venueName != null || match.venueLocation != null) ...[
                Gap(8.h),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16.sp,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    Gap(8.w),
                    Expanded(
                      child: Text(
                        match.venueName ??
                            match.venueLocation ??
                            'Venue to be announced',
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color accent, bool isLive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accent.withOpacity(isLive ? 0.45 : 0.32),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accent.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Gap(6.w),
          ],
          Text(
            label,
            style: TextStyles.font12WhiteMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn({
    required TeamMatchScore team,
    required int score,
    required Color accent,
    required bool hasScores,
    bool isLeading = false,
    bool alignEnd = false,
  }) {
    final alignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxis = alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start;
    final TournamentTeam? teamDetails = _teamDetails(team.teamId);
    final rosterCount =
        teamDetails?.playerNames.length ?? team.playerIds.length;
    final rosterLabel =
        rosterCount > 0 ? '$rosterCount players' : 'Line-up TBD';

    Widget _buildNameRow() {
      return Row(
          mainAxisAlignment: mainAxis,
          children: [
            if (!alignEnd)
              _buildTeamAvatar(team.teamName, accent)
            else
              const SizedBox.shrink(),
            if (!alignEnd) Gap(10.w),
            Expanded(
              child: Text(
                team.teamName,
                style: TextStyles.font16White600Weight.copyWith(
                  color: Colors.white,
                  fontWeight: isLeading ? FontWeight.w800 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              ),
            ),
            if (alignEnd) Gap(10.w),
            if (alignEnd) _buildTeamAvatar(team.teamName, accent),
          ],
      );
    }

    Widget _buildCompactNameColumn() {
      return Column(
        crossAxisAlignment: alignment,
        children: [
          if (!alignEnd) ...[
            _buildTeamAvatar(team.teamName, accent),
            Gap(6.h),
          ],
          Text(
            team.teamName,
            style: TextStyles.font16White600Weight.copyWith(
              color: Colors.white,
              fontWeight: isLeading ? FontWeight.w800 : FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          ),
          if (alignEnd) ...[
            Gap(6.h),
            _buildTeamAvatar(team.teamName, accent),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 90.w;
        final heading = isCompact ? _buildCompactNameColumn() : _buildNameRow();

        return Column(
          crossAxisAlignment: alignment,
          children: [
            heading,
        Gap(8.h),
        if (hasScores)
          Text(
            score.toString(),
            style: TextStyles.font24WhiteBold.copyWith(
                  color:
                      isLeading ? Colors.white : Colors.white.withOpacity(0.85),
              fontWeight: isLeading ? FontWeight.w800 : FontWeight.w600,
            ),
          )
        else
          Text(
            rosterLabel,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          ),
      ],
        );
      },
    );
  }

  Widget _buildTeamAvatar(String teamName, Color accent) {
    final sanitizedName = teamName.trim();
    final initial =
        sanitizedName.isNotEmpty ? sanitizedName[0].toUpperCase() : '?';
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.95),
            accent.withOpacity(0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyles.font16White600Weight.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _matchStatusColor(TournamentMatchStatus status) {
    switch (status) {
      case TournamentMatchStatus.live:
        return Colors.redAccent;
      case TournamentMatchStatus.completed:
        return ColorsManager.success;
      case TournamentMatchStatus.cancelled:
        return Colors.grey;
      case TournamentMatchStatus.scheduled:
      default:
        return ColorsManager.primary;
    }
  }

  String _matchStatusLabel(TournamentMatch match) {
    if (match.status == TournamentMatchStatus.live) {
      final minutes = match.currentMatchTime?.inMinutes;
      if (minutes != null && minutes > 0) {
        return 'Live ${minutes}\'';
      }
      return 'Live';
    }

    if (match.status == TournamentMatchStatus.scheduled) {
      final now = DateTime.now();
      final diff = match.scheduledTime.difference(now);
      if (!diff.isNegative) {
        if (diff.inHours >= 1) {
          return 'Starts in ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          return 'Starts in ${diff.inMinutes}m';
        }
      }
      return 'Scheduled';
    }

    if (match.status == TournamentMatchStatus.cancelled) {
      return 'Cancelled';
    }

    return match.status.displayName;
  }

  Widget _buildStandingsTable({bool withBackground = true}) {
    final sortedTeams = _teamStandings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final table = ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            color: Colors.white.withOpacity(0.08),
            child: Row(
              children: [
                SizedBox(
                  width: 42.w,
                  child: Text(
                    'Pos',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Team',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48.w,
                  child: Text(
                    'GP',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 48.w,
                  child: Text(
                    'W',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 48.w,
                  child: Text(
                    'D',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 54.w,
                  child: Text(
                    'Pts',
                    style: TextStyles.font12Grey400Weight.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ...sortedTeams.asMap().entries.map((entry) {
            final index = entry.key;
            final teamEntry = entry.value;
            final teamId = teamEntry.key;
            final teamPoints = teamEntry.value;
            final team = _teamDetails(teamId);
            final teamName = _teamName(teamId);
            final gamesPlayed =
                team != null ? team.wins + team.losses + team.draws : null;
            final isChampion = _tournament.winnerTeamId == teamId;
            final rowAccent = index == 0
                ? ColorsManager.primary
                : index == 1
                    ? ColorsManager.secondary
                    : index == 2
                        ? ColorsManager.success
                        : Colors.white.withOpacity(0.28);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: rowAccent.withOpacity(index < 3 ? 0.2 : 0.12),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(
                        index < sortedTeams.length - 1 ? 0.06 : 0.0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 42.w,
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyles.font14White600Weight.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (isChampion) ...[
                          Gap(4.w),
                          Icon(
                            Icons.emoji_events,
                            color: ColorsManager.warning,
                            size: 16.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildTeamAvatar(teamName, rowAccent),
                        Gap(10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teamName,
                                style: TextStyles.font14White600Weight.copyWith(
                                  color: Colors.white,
                                  fontWeight: isChampion
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (team != null) ...[
                                Gap(2.h),
                                Text(
                                  '${team.wins}W • ${team.draws}D • ${team.losses}L',
                                  style:
                                      TextStyles.font12Grey400Weight.copyWith(
                                    color: Colors.white.withOpacity(0.78),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      gamesPlayed?.toString() ?? '—',
                      style: TextStyles.font14White600Weight.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      team?.wins.toString() ?? '—',
                      style: TextStyles.font14White600Weight.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 48.w,
                    child: Text(
                      team?.draws.toString() ?? '—',
                      style: TextStyles.font14White600Weight.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 54.w,
                    child: Text(
                      teamPoints.toString(),
                      style: TextStyles.font14White600Weight.copyWith(
                        color: Colors.white,
                        fontWeight:
                            index == 0 ? FontWeight.w700 : FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    if (!withBackground) {
      return table;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF182035),
            Color(0xFF0E1424),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: table,
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: Colors.white.withOpacity(0.35),
            ),
            Gap(16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openMatchDetails(TournamentMatch match) {
    DetailNavigator.openMatch(
      context,
      match: match,
    );
  }

  void _openTeamDetails(TournamentTeam team) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TournamentTeamDetailScreen(team: team),
      ),
    );
  }

  void _navigateToScheduleMatches() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchSchedulingScreen(
          tournament: _tournament,
        ),
      ),
    );
  }

  void _navigateToScoreUpdate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScoreUpdateScreen(
          tournament: _tournament,
        ),
      ),
    );
  }

  void _navigateToDeclareWinner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WinnerDeclarationScreen(
          tournament: _tournament,
        ),
      ),
    );
  }

  void _navigateToManagementDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentManagementDashboard(
          tournament: _tournament,
        ),
      ),
    );
  }

  Future<void> _openTournamentAdminPanel() async {
    // Navigate directly to the full TournamentAdminScreen
    // which shows live matches, scheduled matches, and all admin controls
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TournamentAdminScreen(
          tournament: _tournament,
        ),
      ),
    );
  }
}

class _TournamentAdminSheet extends StatelessWidget {
  const _TournamentAdminSheet({
    required this.tournament,
    required this.canEdit,
    required this.onClose,
    required this.onOpenSchedule,
    required this.onOpenScoreEditor,
    required this.onOpenWinnerDeclaration,
    required this.onOpenDashboard,
  });

  final Tournament tournament;
  final bool canEdit;
  final VoidCallback onClose;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenScoreEditor;
  final VoidCallback onOpenWinnerDeclaration;
  final VoidCallback onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    final liveStream =
        TournamentLiveService().getTournamentUpdates(tournament.id);
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.95,
      initialChildSize: 0.88,
      minChildSize: 0.7,
      builder: (context, controller) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
          child: StreamBuilder<Tournament>(
            stream: liveStream,
            initialData: tournament,
            builder: (context, snapshot) {
              final liveTournament = snapshot.data ?? tournament;
              final availableSpots = liveTournament.availableSpots;
              final registrationWindow =
                  '${DateFormat('MMM d').format(liveTournament.registrationStartDate)} → ${DateFormat('MMM d').format(liveTournament.registrationEndDate)}';

              return Container(
                decoration: BoxDecoration(
                  gradient: PublicProfileTheme.panelGradient,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 28,
                      offset: const Offset(0, -14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
                      child: Container(
                        width: 56.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tournament admin',
                                  style: TextStyles.font18DarkBlueBold,
                                ),
                                Gap(4.h),
                                Text(
                                  liveTournament.name,
                                  style: TextStyles.font12Grey400Weight,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        children: [
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 12.h,
                            children: [
                              _AdminMetricChip(
                                label: 'Status',
                                value: liveTournament.status.displayName,
                                icon: Icons.flag_rounded,
                              ),
                              _AdminMetricChip(
                                label: 'Teams',
                                value:
                                    '${liveTournament.currentTeamsCount}/${liveTournament.maxTeams}',
                                icon: Icons.groups_2_rounded,
                              ),
                              _AdminMetricChip(
                                label: 'Spots',
                                value: availableSpots > 0
                                    ? '$availableSpots left'
                                    : 'Full',
                                icon: Icons.event_available_rounded,
                              ),
                              _AdminMetricChip(
                                label: 'Reg. window',
                                value: registrationWindow,
                                icon: Icons.calendar_month_rounded,
                              ),
                            ],
                          ),
                          Gap(20.h),
                          Text(
                            'Quick actions',
                            style: TextStyles.font14DarkBlue600Weight.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Gap(12.h),
                          _AdminActionTile(
                            icon: Icons.calendar_today_rounded,
                            title: 'Schedule matches',
                            subtitle: 'Create or edit fixtures',
                            enabled: canEdit,
                            onTap: canEdit ? onOpenSchedule : null,
                          ),
                          _AdminActionTile(
                            icon: Icons.sports_score_rounded,
                            title: 'Update live scores',
                            subtitle: 'Push new results & commentary',
                            enabled: canEdit,
                            onTap: canEdit ? onOpenScoreEditor : null,
                          ),
                          _AdminActionTile(
                            icon: Icons.emoji_events_rounded,
                            title: 'Declare winners',
                            subtitle: 'Publish podium & awards',
                            enabled: canEdit,
                            onTap: canEdit ? onOpenWinnerDeclaration : null,
                          ),
                          _AdminActionTile(
                            icon: Icons.dashboard_customize_rounded,
                            title: 'Management dashboard',
                            subtitle: 'Open full-screen controls',
                            enabled: canEdit,
                            onTap: canEdit ? onOpenDashboard : null,
                          ),
                          if (!canEdit) ...[
                            Gap(16.h),
                            const _AdminInfoCard(
                              title: 'View only',
                              message:
                                  'You can browse tournament controls here. Only the organizer can make changes.',
                            ),
                          ],
                          Gap(12.h),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminMetricChip extends StatelessWidget {
  const _AdminMetricChip({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18.sp, color: PublicProfileTheme.panelAccentColor),
            Gap(8.h),
          ],
          Text(
            value,
            style: TextStyles.font16White600Weight,
          ),
          Gap(4.h),
          Text(
            label,
            style: TextStyles.font11Grey400Weight,
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      leading: Container(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: PublicProfileTheme.panelAccentColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(
          icon,
          color: PublicProfileTheme.panelAccentColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyles.font14White600Weight,
      ),
      subtitle: Text(
        enabled ? subtitle : 'Organizer only',
        style: TextStyles.font12Grey400Weight,
      ),
      trailing: Icon(
        enabled ? Icons.chevron_right : Icons.lock_outline_rounded,
        color: enabled ? Colors.white70 : Colors.white38,
      ),
      onTap: null,
    );

    final tileContent = Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: tile,
    );

    if (enabled) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: tileContent,
        ),
      );
    }
    return Opacity(
      opacity: 0.65,
      child: tileContent,
    );
  }
}

class _AdminInfoCard extends StatelessWidget {
  const _AdminInfoCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: const Icon(Icons.visibility_rounded, color: Colors.white70),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font13White500Weight,
                ),
                Gap(4.h),
                Text(
                  message,
                  style: TextStyles.font11Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
