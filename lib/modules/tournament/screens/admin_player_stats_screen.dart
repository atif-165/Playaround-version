import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/tournament_match_model.dart';
import '../models/player_match_stats.dart';
import '../services/tournament_match_service.dart';
import '../services/tournament_team_service.dart';
import '../../team/models/team_model.dart';

class AdminPlayerStatsScreen extends StatefulWidget {
  final TournamentMatch match;

  const AdminPlayerStatsScreen({
    super.key,
    required this.match,
  });

  @override
  State<AdminPlayerStatsScreen> createState() => _AdminPlayerStatsScreenState();
}

class _AdminPlayerStatsScreenState extends State<AdminPlayerStatsScreen> {
  final _matchService = TournamentMatchService();
  final TournamentTeamService _teamService = TournamentTeamService();
  final NotificationService _notificationService = NotificationService();
  List<PlayerMatchStats> _team1Stats = [];
  List<PlayerMatchStats> _team2Stats = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initialiseStats();
  }

  Future<void> _initialiseStats() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final team1Roster = await _buildRosterPlaceholders(widget.match.team1);
      final team2Roster = await _buildRosterPlaceholders(widget.match.team2);

      final mergedTeam1 =
          _mergeRosterWithExisting(team1Roster, widget.match.team1PlayerStats);
      final mergedTeam2 =
          _mergeRosterWithExisting(team2Roster, widget.match.team2PlayerStats);

      if (!mounted) return;
      setState(() {
        _team1Stats = mergedTeam1;
        _team2Stats = mergedTeam2;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
    _team1Stats = List.from(widget.match.team1PlayerStats);
    _team2Stats = List.from(widget.match.team2PlayerStats);
        _isLoading = false;
      });
    }
  }

  Future<List<PlayerMatchStats>> _buildRosterPlaceholders(
      TeamMatchScore team) async {
    final placeholders = <PlayerMatchStats>[];

    if (team.teamId.isNotEmpty) {
      final tournamentTeam = await _teamService.getTeamById(team.teamId);
      if (tournamentTeam != null && tournamentTeam.playerIds.isNotEmpty) {
        for (var i = 0; i < tournamentTeam.playerIds.length; i++) {
          final playerId = tournamentTeam.playerIds[i];
          final playerName = i < tournamentTeam.playerNames.length
              ? tournamentTeam.playerNames[i]
              : 'Player ${i + 1}';
          placeholders.add(
            PlayerMatchStats(
              playerId: playerId,
              playerName: playerName,
            ),
          );
        }
      }
    }

    if (placeholders.isEmpty && team.playerIds.isNotEmpty) {
      for (var i = 0; i < team.playerIds.length; i++) {
        final playerId = team.playerIds[i];
        placeholders.add(
          PlayerMatchStats(
            playerId: playerId,
            playerName: 'Player ${i + 1}',
          ),
        );
      }
    }

    if (placeholders.isEmpty) {
      // Provide at least a couple of placeholders so UI stays interactive
      for (var i = 0; i < 5; i++) {
        placeholders.add(
          PlayerMatchStats(
            playerId: '${team.teamId}_placeholder_$i',
            playerName: 'Player ${i + 1}',
          ),
        );
      }
    }

    return placeholders;
  }

  List<PlayerMatchStats> _mergeRosterWithExisting(
    List<PlayerMatchStats> roster,
    List<PlayerMatchStats> existing,
  ) {
    final existingById = {
      for (final stat in existing) stat.playerId: stat,
    };

    final merged = roster.map((player) {
      final existingStat = existingById[player.playerId];
      if (existingStat != null) {
        if (existingStat.playerName.isEmpty) {
          return existingStat.copyWith(playerName: player.playerName);
        }
        return existingStat;
      }
      return player;
    }).toList();

    for (final stat in existing) {
      if (!merged.any((s) => s.playerId == stat.playerId)) {
        merged.add(stat);
      }
    }

    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Player Stats'),
        backgroundColor: ColorsManager.darkBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _initialiseStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync players from roster',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveStats,
            tooltip: 'Save Stats',
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _initialiseStats,
                    child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
                      physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMatchInfo(),
            Gap(24.h),
            _buildTeamSection(
              teamName: widget.match.team1.teamName,
              coachName: widget.match.team1CoachName,
              stats: _team1Stats,
              isTeam1: true,
            ),
            Gap(24.h),
            _buildTeamSection(
              teamName: widget.match.team2.teamName,
              coachName: widget.match.team2CoachName,
              stats: _team2Stats,
              isTeam1: false,
            ),
          ],
        ),
      ),
          ),
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: PublicProfileTheme.panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.match.matchNumber,
            style: TextStyles.font16DarkBlue600Weight.copyWith(
              color: ColorsManager.mainBlue,
            ),
          ),
          Gap(4.h),
          Text(
            '${widget.match.team1.teamName} vs ${widget.match.team2.teamName}',
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
          Gap(4.h),
          Text(
            'Sport: ${widget.match.sportType.displayName}',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            Gap(12.h),
            Text(
              'Failed to load team rosters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.h),
            Text(
              _loadError ?? 'Unknown error',
              style: TextStyle(color: Colors.grey[400], fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: _initialiseStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    String? coachName,
    required List<PlayerMatchStats> stats,
    required bool isTeam1,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: PublicProfileTheme.panelColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: PublicProfileTheme.defaultShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              Widget buildButton() {
                return OutlinedButton.icon(
                  onPressed: () => _showAddPlayerDialog(isTeam1),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Player'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.mainBlue,
                    side: BorderSide(color: ColorsManager.mainBlue),
                  ),
                );
              }

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: TextStyles.font18DarkBlue600Weight.copyWith(
                  color: Colors.white,
                ),
              ),
                    Gap(10.h),
                    SizedBox(
                      width: double.infinity,
                      child: buildButton(),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      teamName,
                      style: TextStyles.font18DarkBlue600Weight.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
                  Gap(12.w),
                  buildButton(),
            ],
              );
            },
          ),
          if (coachName != null) ...[
            Gap(4.h),
            Row(
              children: [
                Icon(Icons.sports, size: 14.sp, color: Colors.amber),
                Gap(4.w),
                Text(
                  'Coach: $coachName',
                  style: TextStyle(color: Colors.amber, fontSize: 12.sp),
                ),
              ],
            ),
          ],
          Gap(16.h),
          if (stats.isEmpty)
            _buildEmptyState()
          else
            ...stats.map((stat) => _buildPlayerStatCard(stat, isTeam1)),
        ],
      ),
    );
  }

  Widget _buildPlayerStatCard(PlayerMatchStats stat, bool isTeam1) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: PublicProfileTheme.panelOverlayColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stat.playerName,
                  style: TextStyle(
                    color: ColorsManager.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                  IconButton(
                icon: const Icon(Icons.delete_outline),
                color: ColorsManager.error,
                    onPressed: () => _removePlayer(stat.playerId, isTeam1),
              ),
            ],
          ),
          Gap(12.h),
          _buildCustomStatsSection(stat, isTeam1),
        ],
      ),
    );
  }

  Widget _buildCustomStatsSection(
    PlayerMatchStats stat,
    bool isTeam1,
  ) {
    final entries = (stat.customStats ?? {}).entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        if (entries.isEmpty)
          Text(
            'No metrics added yet. Use “Add Metric” to define custom stats.',
            style: TextStyle(color: ColorsManager.textSecondary, fontSize: 12.sp),
          )
        else
          Wrap(
        spacing: 12.w,
            runSpacing: 10.h,
            children: entries
                .map(
                  (entry) => Chip(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    backgroundColor:
                        ColorsManager.mainBlue.withOpacity(0.18),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: Colors.white,
                    onDeleted: () =>
                        _removeCustomMetric(stat, isTeam1, entry.key),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
        children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
        style: TextStyle(
                            color: Colors.white70,
          fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        Gap(12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCustomMetricDialog(stat, isTeam1),
            icon: const Icon(Icons.add),
            label: const Text('Add Metric'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorsManager.mainBlue,
              side: BorderSide(color: ColorsManager.mainBlue),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Center(
        child: Text(
          'No players added yet',
          style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
        ),
      ),
    );
  }

  Future<void> _showAddPlayerDialog(bool isTeam1) async {
    final teamName =
        isTeam1 ? widget.match.team1.teamName : widget.match.team2.teamName;
    final searchController = TextEditingController();
    final focusNode = FocusNode();
    List<_UserSuggestion> suggestions = <_UserSuggestion>[];
    bool isSearching = true;
    String? searchMessage;
    bool initialized = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PublicProfileTheme.panelColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> performSearch(String query) async {
                setSheetState(() {
                  isSearching = true;
                  searchMessage = null;
                });
                try {
                  final results = await _fetchUserSuggestions(query);
                  setSheetState(() {
                    suggestions = results;
                    isSearching = false;
                    if (results.isEmpty) {
                      searchMessage = query.isEmpty
                          ? 'No verified players are available.'
                          : 'No players match "$query".';
                    }
                  });
                } catch (_) {
                  setSheetState(() {
                    isSearching = false;
                    searchMessage = 'Unable to load players. Try again.';
                    suggestions = <_UserSuggestion>[];
                  });
                }
              }

              if (!initialized) {
                initialized = true;
                performSearch('');
              }

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    12.h,
                    20.w,
                    MediaQuery.of(context).viewInsets.bottom + 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42.w,
                          height: 4.h,
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Text(
                        'Add players to $teamName',
                        style: TextStyles.font18DarkBlue600Weight.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Gap(12.h),
                      TextField(
                        controller: searchController,
                        focusNode: focusNode,
                        onChanged: (value) => performSearch(value),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Search users by name (case-insensitive)',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      Gap(12.h),
                      if (isSearching)
                        const LinearProgressIndicator()
                      else
                        const SizedBox(height: 4),
                      Gap(8.h),
                      Expanded(
                        child: suggestions.isEmpty
                            ? _buildSuggestionEmptyState(searchMessage)
                            : ListView.separated(
                                itemCount: suggestions.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                itemBuilder: (context, index) {
                                  final suggestion = suggestions[index];
                                  return ListTile(
                                    onTap: () => _handlePlayerSelection(
                                      modalContext,
                                      suggestion,
                                      isTeam1,
                                      teamName,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.1),
                                      backgroundImage: suggestion.avatarUrl !=
                                              null
                                          ? NetworkImage(suggestion.avatarUrl!)
                                          : null,
                                      child: suggestion.avatarUrl == null
                                          ? Text(
                                              suggestion.name.isNotEmpty
                                                  ? suggestion.name[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      suggestion.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Tap to add this player',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white54,
                                      size: 14,
                                    ),
                                  );
                                },
                              ),
                      ),
                      Gap(8.h),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalContext);
                          _showManualPlayerDialog(isTeam1);
                        },
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Add custom player name'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    searchController.dispose();
    focusNode.dispose();
  }

  Future<void> _showManualPlayerDialog(bool isTeam1) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add custom player to ${isTeam1 ? widget.match.team1.teamName : widget.match.team2.teamName}',
        ),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Player name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
                setState(() {
                final stat = PlayerMatchStats(
                  playerId:
                      'manual_${DateTime.now().microsecondsSinceEpoch.toString()}',
                  playerName: value,
                  );
                  if (isTeam1) {
                  _team1Stats.add(stat);
                  } else {
                  _team2Stats.add(stat);
                  }
                });
                Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$value added manually'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removePlayer(String playerId, bool isTeam1) {
    setState(() {
      if (isTeam1) {
        _team1Stats.removeWhere((s) => s.playerId == playerId);
      } else {
        _team2Stats.removeWhere((s) => s.playerId == playerId);
      }
    });
  }

  void _removeCustomMetric(
    PlayerMatchStats stat,
    bool isTeam1,
    String key,
  ) {
    final updatedStats = Map<String, dynamic>.from(stat.customStats ?? {});
    updatedStats.remove(key);
    _replacePlayerStat(
      isTeam1: isTeam1,
      playerId: stat.playerId,
      updated: stat.copyWith(customStats: updatedStats),
    );
  }

  void _showCustomMetricDialog(
    PlayerMatchStats stat,
    bool isTeam1, {
    String? existingKey,
  }) {
    final keyController = TextEditingController(text: existingKey ?? '');
    final valueController = TextEditingController(
      text: existingKey != null
          ? (stat.customStats?[existingKey]?.toString() ?? '')
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorsManager.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
            top: 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existingKey == null
                    ? 'Add metric for ${stat.playerName}'
                    : 'Edit metric ${existingKey}',
                style: TextStyle(
                  color: ColorsManager.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(16.h),
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: 'Key',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Value',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
          ),
              Gap(20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: ElevatedButton(
            onPressed: () {
                        final key = keyController.text.trim();
                        final value = valueController.text.trim();
                        if (key.isEmpty || value.isEmpty) return;

                        final updatedStats = Map<String, dynamic>.from(
                          stat.customStats ?? {},
                        );
                        updatedStats[key] = value;
                        _replacePlayerStat(
                          isTeam1: isTeam1,
                          playerId: stat.playerId,
                          updated: stat.copyWith(customStats: updatedStats),
                        );
              Navigator.pop(context);
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.mainBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text('Save Metric'),
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
      },
    );
  }

  Future<List<_UserSuggestion>> _fetchUserSuggestions(String query) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final lower = query.trim().toLowerCase();

    try {
      final orderedSnapshot =
          await usersRef.orderBy('fullName').limit(50).get();
      return _filterSuggestions(orderedSnapshot.docs, lower);
    } catch (_) {
      final fallbackSnapshot = await usersRef.limit(50).get();
      return _filterSuggestions(fallbackSnapshot.docs, lower);
    }
  }

  List<_UserSuggestion> _filterSuggestions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String lower,
  ) {
    return docs
        .map(_UserSuggestion.fromDoc)
        .where((user) => lower.isEmpty || user.searchName.contains(lower))
        .take(20)
        .toList();
  }

  Widget _buildSuggestionEmptyState(String? message) {
    return Center(
      child: Text(
        message ?? 'Start typing to search players.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ColorsManager.textSecondary,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Future<void> _handlePlayerSelection(
    BuildContext modalContext,
    _UserSuggestion suggestion,
    bool isTeam1,
    String teamName,
  ) async {
    Navigator.pop(modalContext);

    final list = isTeam1 ? _team1Stats : _team2Stats;
    final exists = list.any((player) => player.playerId == suggestion.id);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${suggestion.name} is already on this roster.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      final newStat = PlayerMatchStats(
        playerId: suggestion.id,
        playerName: suggestion.name,
        playerImageUrl: suggestion.avatarUrl,
      );
      if (isTeam1) {
        _team1Stats.add(newStat);
      } else {
        _team2Stats.add(newStat);
      }
    });

    try {
      await _notificationService.createNotification(
        userId: suggestion.id,
        type: NotificationType.teamInvite,
        title: 'You were added to $teamName',
        message:
            'You have been added to $teamName for ${widget.match.matchNumber}.',
        data: {
          'matchId': widget.match.id,
          'teamName': teamName,
          'tournamentId': widget.match.tournamentId,
        },
      );
    } catch (_) {
      // Ignore notification errors for now
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${suggestion.name} added to $teamName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _replacePlayerStat({
    required bool isTeam1,
    required String playerId,
    required PlayerMatchStats updated,
  }) {
    setState(() {
      final list = isTeam1 ? _team1Stats : _team2Stats;
      final index = list.indexWhere((s) => s.playerId == playerId);
      if (index != -1) {
        list[index] = updated;
      } else {
        list.add(updated);
      }
    });
  }

  Future<void> _saveStats() async {
    try {
      // Update match with player stats
      await _matchService.updatePlayerStats(
        matchId: widget.match.id,
        team1PlayerStats: _team1Stats,
        team2PlayerStats: _team2Stats,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player stats saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _UserSuggestion {
  const _UserSuggestion({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.searchName,
  });

  factory _UserSuggestion.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final rawName =
        (data['fullName'] ?? data['name'] ?? 'Unnamed Player').toString();
    final sanitizedName =
        rawName.trim().isEmpty ? 'Unnamed Player' : rawName.trim();
    final avatar = data['profilePictureUrl'] ??
        data['avatarUrl'] ??
        data['photoUrl'] ??
        data['imageUrl'];

    return _UserSuggestion(
      id: doc.id,
      name: sanitizedName,
      avatarUrl: avatar is String && avatar.trim().isNotEmpty ? avatar : null,
      searchName: sanitizedName.toLowerCase(),
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
  final String searchName;
}


