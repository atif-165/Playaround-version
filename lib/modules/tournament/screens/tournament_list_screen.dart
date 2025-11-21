import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../services/tournament_service.dart';
import '../widgets/tournament_card.dart';
import '../widgets/tournament_filters.dart';

/// Screen displaying list of tournaments
class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _tournamentService = TournamentService();
  final TextEditingController _searchController = TextEditingController();
  List<Tournament> _allTournaments = [];
  List<Tournament> _filteredTournaments = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<Tournament>>? _tournamentsSubscription;
  TournamentFilterData _activeFilters = const TournamentFilterData();

  @override
  void initState() {
    super.initState();
    _loadTournaments();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _tournamentsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    _tournamentsSubscription?.cancel();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _tournamentsSubscription =
        _tournamentService.getPublicTournaments().listen(
      (tournaments) {
        if (!mounted) return;
        final filtered = _filterTournaments(tournaments);
          setState(() {
          _allTournaments = tournaments;
          _filteredTournaments = filtered;
            _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error, stackTrace) {
        debugPrint('Tournament stream error: $error');
        if (stackTrace != null) {
          debugPrint(stackTrace.toString());
        }
        if (!mounted) return;
        final message =
            'Failed to load tournaments. ${_humanizeError(error.toString())}';
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121338),
            Color(0xFF070616),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            Gap(18.h),
            _buildSearchAndFilters(),
            _buildActiveFiltersRow(),
            Gap(12.h),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredTournaments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      displacement: 80.h,
      edgeOffset: 0,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
        itemCount: _filteredTournaments.length,
        separatorBuilder: (_, __) => Gap(18.h),
        itemBuilder: (context, index) {
          final tournament = _filteredTournaments[index];
          return TournamentCard(
            tournament: tournament,
            onTap: () => _navigateToTournamentDetails(tournament),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Competitive Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Gap(6.h),
                Text(
                  'Browse vibrant tournaments, filter by sport, entry fee, status and more.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 13.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
            Gap(12.w),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    cursorColor: ColorsManager.primary,
                    decoration: InputDecoration(
                      hintText: 'Search by name, sport or organizer',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: ColorsManager.primary.withOpacity(0.9),
                        size: 22.sp,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              splashRadius: 18.r,
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 18.sp,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Gap(12.w),
                ElevatedButton.icon(
                  onPressed: _showFilters,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    backgroundColor: ColorsManager.primary.withOpacity(0.18),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 18.sp,
                  ),
                  label: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    final chips = <Widget>[];

    if (_searchController.text.isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Query: "${_searchController.text}"',
        onRemove: () {
          _searchController.clear();
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.sportType != null) {
      chips.add(_ActiveFilterChip(
        label: _activeFilters.sportType!.displayName,
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: null,
              format: _activeFilters.format,
              status: _activeFilters.status,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: _activeFilters.location,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.format != null) {
      chips.add(_ActiveFilterChip(
        label: _activeFilters.format!.displayName,
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: null,
              status: _activeFilters.status,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: _activeFilters.location,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.status != null) {
      chips.add(_ActiveFilterChip(
        label: _activeFilters.status!.displayName,
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: _activeFilters.format,
              status: null,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: _activeFilters.location,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.maxEntryFee != null) {
      chips.add(_ActiveFilterChip(
        label: 'Entry ≤ ${_activeFilters.maxEntryFee!.toStringAsFixed(0)}',
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: _activeFilters.format,
              status: _activeFilters.status,
              maxEntryFee: null,
              location: _activeFilters.location,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.location != null &&
        _activeFilters.location!.trim().isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: 'Location: ${_activeFilters.location}',
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: _activeFilters.format,
              status: _activeFilters.status,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: null,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.showFreeOnly) {
      chips.add(_ActiveFilterChip(
        label: 'Free',
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: _activeFilters.format,
              status: _activeFilters.status,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: _activeFilters.location,
              showFreeOnly: false,
              showPaidOnly: _activeFilters.showPaidOnly,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (_activeFilters.showPaidOnly) {
      chips.add(_ActiveFilterChip(
        label: 'Paid',
        onRemove: () {
          setState(() {
            _activeFilters = TournamentFilterData(
              sportType: _activeFilters.sportType,
              format: _activeFilters.format,
              status: _activeFilters.status,
              maxEntryFee: _activeFilters.maxEntryFee,
              location: _activeFilters.location,
              showFreeOnly: _activeFilters.showFreeOnly,
              showPaidOnly: false,
            );
          });
          _applyFilters();
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(top: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.expand((chip) => [chip, Gap(10.w)]).toList()
            ..removeLast(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomProgressIndicator(),
          Gap(16.h),
          Text(
            'Fetching tournaments...',
            style: TextStyles.font14Grey400Weight.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 54.sp,
            color: Colors.redAccent.shade200,
          ),
          Gap(12.h),
          Text(
            'We couldn’t load tournaments',
            style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Gap(4.h),
          Text(
            _errorMessage ?? 'Please try again in a moment.',
            textAlign: TextAlign.center,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white70,
            ),
          ),
          Gap(20.h),
          ElevatedButton.icon(
            onPressed: _loadTournaments,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
            size: 62.sp,
            color: Colors.white30,
            ),
          Gap(14.h),
            Text(
            'No tournaments live right now',
            style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
            ),
          Gap(3.h),
            Text(
            'Be the first to host a tournament or check back soon for new competitions.',
            style: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white70,
              height: 1.4,
            ),
              textAlign: TextAlign.center,
            ),
              Gap(24.h),
              ElevatedButton.icon(
                onPressed: _handleCreateTournament,
                icon: const Icon(Icons.add),
                label: const Text('Create Tournament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.mainBlue,
                  foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                ),
              ),
          ],
        ),
      );
    }

  String _humanizeError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('permission-denied')) {
      return 'You do not have permission to view tournaments.';
    }
    if (lower.contains('failed_precondition') ||
        lower.contains('failed-precondition') ||
        lower.contains('index')) {
      return 'A Firestore composite index is missing. Deploy firestore.indexes.json.';
    }
    return 'Please try again.';
  }

  void _handleCreateTournament() {
      _navigateToCreateTournament();
  }

  void _navigateToCreateTournament() {
    Navigator.pushNamed(context, Routes.createTournamentScreen).then((_) {
      // Refresh tournaments list when returning
      _loadTournaments();
    });
  }

  void _navigateToTournamentDetails(Tournament tournament) {
    Navigator.pushNamed(
      context,
      Routes.tournamentDetailScreen,
      arguments: tournament,
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentFilters(
        selectedSportType: _activeFilters.sportType,
        selectedFormat: _activeFilters.format,
        selectedStatus: _activeFilters.status,
        maxEntryFee: _activeFilters.maxEntryFee,
        location: _activeFilters.location,
        showFreeOnly: _activeFilters.showFreeOnly,
        showPaidOnly: _activeFilters.showPaidOnly,
        onApply: (filters) {
          Navigator.of(context).pop();
          setState(() {
            _activeFilters = filters;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredTournaments = _filterTournaments(_allTournaments);
    });
  }

  List<Tournament> _filterTournaments(List<Tournament> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((tournament) {
      if (query.isNotEmpty) {
        final haystack = [
          tournament.name,
          tournament.description,
          tournament.organizerName,
          tournament.location ?? '',
          tournament.sportType.displayName,
          tournament.format.displayName,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      if (_activeFilters.sportType != null &&
          tournament.sportType != _activeFilters.sportType) {
        return false;
      }

      if (_activeFilters.format != null &&
          tournament.format != _activeFilters.format) {
        return false;
      }

      if (_activeFilters.status != null &&
          tournament.status != _activeFilters.status) {
        return false;
      }

      if (_activeFilters.maxEntryFee != null) {
        final entryFee = tournament.entryFee ?? 0;
        if (entryFee > _activeFilters.maxEntryFee!) return false;
      }

      if (_activeFilters.location != null &&
          _activeFilters.location!.trim().isNotEmpty) {
        final locQuery = _activeFilters.location!.trim().toLowerCase();
        final tournamentLocation = (tournament.location ?? '').toLowerCase();
        if (!tournamentLocation.contains(locQuery)) return false;
      }

      if (_activeFilters.showFreeOnly) {
        final entryFee = tournament.entryFee ?? 0;
        if (entryFee > 0) return false;
      }

      if (_activeFilters.showPaidOnly) {
        final entryFee = tournament.entryFee ?? 0;
        if (entryFee <= 0) return false;
      }

      return true;
    }).toList();
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),
          Gap(8.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.65),
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
