import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/tournament_service.dart';

class AdminLeaderboardScreen extends StatefulWidget {
  final TournamentModel tournament;

  const AdminLeaderboardScreen({
    super.key,
    required this.tournament,
  });

  @override
  State<AdminLeaderboardScreen> createState() => _AdminLeaderboardScreenState();
}

class _AdminLeaderboardScreenState extends State<AdminLeaderboardScreen> {
  final _tournamentService = TournamentService();
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    // Load existing leaderboard entries from tournament metadata
    // For now, we'll initialize with empty or existing data
    final metadata = widget.tournament.metadata;
    if (metadata != null && metadata.containsKey('manualLeaderboard')) {
      final List<dynamic> rawEntries = metadata['manualLeaderboard'];
      _entries = rawEntries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _entries = [];
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Manage Leaderboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLeaderboard,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : ReorderableListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _entries.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = _entries.removeAt(oldIndex);
                      _entries.insert(newIndex, item);
                      // Update positions
                      for (int i = 0; i < _entries.length; i++) {
                        _entries[i] = _entries[i].copyWith(position: i + 1);
                      }
                    });
                  },
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _buildLeaderboardCard(entry, index,
                        key: ValueKey(entry.teamId));
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeamDialog,
        backgroundColor: ColorsManager.mainBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64.sp,
            color: Colors.grey,
          ),
          Gap(16.h),
          Text(
            'No teams in leaderboard',
            style: TextStyle(color: Colors.grey, fontSize: 16.sp),
          ),
          Gap(24.h),
          ElevatedButton.icon(
            onPressed: _showAddTeamDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.mainBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index,
      {required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: index == 0
              ? Colors.amber
              : index == 1
                  ? Colors.grey[400]!
                  : index == 2
                      ? Colors.brown
                      : Colors.grey[700]!,
          width: index < 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _getPositionColor(index).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _getPositionColor(index)),
            ),
            child: Center(
              child: Text(
                '${entry.position}',
                style: TextStyle(
                  color: _getPositionColor(index),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Gap(12.w),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.teamName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(4.h),
                Row(
                  children: [
                    _buildStatBadge('Pts', entry.points, Colors.green),
                    Gap(8.w),
                    _buildStatBadge('W', entry.wins, Colors.blue),
                    Gap(8.w),
                    _buildStatBadge('L', entry.losses, Colors.red),
                    if (entry.draws > 0) ...[
                      Gap(8.w),
                      _buildStatBadge('D', entry.draws, Colors.orange),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 20.sp),
                color: ColorsManager.mainBlue,
                onPressed: () => _showEditEntryDialog(entry, index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Gap(12.w),
              IconButton(
                icon: Icon(Icons.delete, size: 20.sp),
                color: Colors.red,
                onPressed: () => _removeEntry(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Gap(8.w),
              Icon(Icons.drag_handle, color: Colors.grey[600]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPositionColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey[400]!;
    if (index == 2) return Colors.brown;
    return Colors.grey[600]!;
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    final pointsController = TextEditingController(text: '0');
    final winsController = TextEditingController(text: '0');
    final lossesController = TextEditingController(text: '0');
    final drawsController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team to Leaderboard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: winsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Wins',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: TextField(
                      controller: lossesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Losses',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              TextField(
                controller: drawsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Draws',
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
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _entries.add(
                    LeaderboardEntry(
                      teamId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                      teamName: nameController.text.trim(),
                      position: _entries.length + 1,
                      points: int.tryParse(pointsController.text) ?? 0,
                      wins: int.tryParse(winsController.text) ?? 0,
                      losses: int.tryParse(lossesController.text) ?? 0,
                      draws: int.tryParse(drawsController.text) ?? 0,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditEntryDialog(LeaderboardEntry entry, int index) {
    final nameController = TextEditingController(text: entry.teamName);
    final pointsController =
        TextEditingController(text: entry.points.toString());
    final winsController = TextEditingController(text: entry.wins.toString());
    final lossesController =
        TextEditingController(text: entry.losses.toString());
    final drawsController = TextEditingController(text: entry.draws.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Team Stats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points',
                  border: OutlineInputBorder(),
                ),
              ),
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: winsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Wins',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: TextField(
                      controller: lossesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Losses',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              TextField(
                controller: drawsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Draws',
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
                _entries[index] = entry.copyWith(
                  teamName: nameController.text.trim(),
                  points: int.tryParse(pointsController.text) ?? 0,
                  wins: int.tryParse(winsController.text) ?? 0,
                  losses: int.tryParse(lossesController.text) ?? 0,
                  draws: int.tryParse(drawsController.text) ?? 0,
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

  void _removeEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team'),
        content: Text('Remove ${_entries[index].teamName} from leaderboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _entries.removeAt(index);
                // Update positions
                for (int i = 0; i < _entries.length; i++) {
                  _entries[i] = _entries[i].copyWith(position: i + 1);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLeaderboard() async {
    try {
      // Save entries to tournament metadata
      final metadata = widget.tournament.metadata ?? {};
      metadata['manualLeaderboard'] = _entries.map((e) => e.toJson()).toList();

      await _tournamentService.updateTournament(
        tournamentId: widget.tournament.id,
        metadata: metadata,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leaderboard saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save leaderboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Leaderboard Entry Model
class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final int position;
  final int points;
  final int wins;
  final int losses;
  final int draws;
  final int goalsFor;
  final int goalsAgainst;

  LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.position,
    this.points = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get matchesPlayed => wins + losses + draws;

  LeaderboardEntry copyWith({
    String? teamId,
    String? teamName,
    int? position,
    int? points,
    int? wins,
    int? losses,
    int? draws,
    int? goalsFor,
    int? goalsAgainst,
  }) {
    return LeaderboardEntry(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      position: position ?? this.position,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'position': position,
      'points': points,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      position: json['position'] as int,
      points: json['points'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
    );
  }
}
