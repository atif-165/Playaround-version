import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/coach_analytics_service.dart';
import '../widgets/comparison_radar_chart.dart';
import '../../team/models/models.dart';
import '../../skill_tracking/models/models.dart';

/// Screen for comparing two players side by side
class PlayerComparisonScreen extends StatefulWidget {
  final List<Team> teams;

  const PlayerComparisonScreen({
    super.key,
    required this.teams,
  });

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen> {
  final CoachAnalyticsService _analyticsService = CoachAnalyticsService();

  List<TeamMember> _allPlayers = [];
  TeamMember? _selectedPlayer1;
  TeamMember? _selectedPlayer2;
  PlayerComparison? _comparison;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllPlayers();
  }

  void _loadAllPlayers() {
    final allPlayers = <TeamMember>[];
    final seenPlayerIds = <String>{};

    for (final team in widget.teams) {
      for (final member in team.members) {
        if (!seenPlayerIds.contains(member.userId)) {
          allPlayers.add(member);
          seenPlayerIds.add(member.userId);
        }
      }
    }

    setState(() {
      _allPlayers = allPlayers;
    });
  }

  Future<void> _comparePlayer() async {
    if (_selectedPlayer1 == null || _selectedPlayer2 == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final comparison = await _analyticsService.comparePlayer(
        _selectedPlayer1!.userId,
        _selectedPlayer2!.userId,
      );

      setState(() {
        _comparison = comparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Compare Players',
        style: TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
      ),
      backgroundColor: ColorsManager.mainBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_selectedPlayer1 != null && _selectedPlayer2 != null)
          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: _comparePlayer,
            tooltip: 'Compare',
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerSelectionSection(),
          if (_selectedPlayer1 != null && _selectedPlayer2 != null) ...[
            Gap(24.h),
            _buildCompareButton(),
          ],
          if (_isLoading) ...[
            Gap(24.h),
            const Center(
              child: CircularProgressIndicator(
                color: ColorsManager.mainBlue,
              ),
            ),
          ],
          if (_error != null) ...[
            Gap(24.h),
            _buildErrorState(),
          ],
          if (_comparison != null) ...[
            Gap(24.h),
            _buildComparisonResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Players to Compare',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildPlayerSelector(
                'Player 1',
                _selectedPlayer1,
                (player) => setState(() {
                  _selectedPlayer1 = player;
                  _comparison = null; // Clear previous comparison
                }),
              ),
            ),
            Gap(16.w),
            Expanded(
              child: _buildPlayerSelector(
                'Player 2',
                _selectedPlayer2,
                (player) => setState(() {
                  _selectedPlayer2 = player;
                  _comparison = null; // Clear previous comparison
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerSelector(
    String label,
    TeamMember? selectedPlayer,
    Function(TeamMember?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            border: Border.all(color: ColorsManager.gray76),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TeamMember>(
              isExpanded: true,
              value: selectedPlayer,
              hint: Text(
                'Select player',
                style: TextStyles.font14Grey400Weight,
              ),
              items: _allPlayers
                  .where((player) =>
                      player !=
                      (label == 'Player 1'
                          ? _selectedPlayer2
                          : _selectedPlayer1))
                  .map((player) => DropdownMenuItem<TeamMember>(
                        value: player,
                        child: Text(
                          player.userName,
                          style: TextStyles.font14DarkBlue600Weight,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _comparePlayer,
        icon: const Icon(Icons.compare_arrows),
        label: const Text('Compare Players'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.mainBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 24.sp,
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparison Failed',
                  style: TextStyles.font16DarkBlue600Weight.copyWith(
                    color: Colors.red[700],
                  ),
                ),
                Gap(4.h),
                Text(
                  _error ?? 'Unknown error occurred',
                  style: TextStyles.font14Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparison Results',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        _buildComparisonSummary(),
        Gap(24.h),
        _buildRadarComparison(),
        Gap(24.h),
        _buildSkillComparisonTable(),
        Gap(24.h),
        _buildRecommendations(),
      ],
    );
  }

  Widget _buildComparisonSummary() {
    final summary = _comparison!.summary;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPlayerSummaryCard(
                  _comparison!.player1,
                  summary.player1WinCount,
                  summary.overallWinner == 'player1',
                ),
              ),
              Gap(16.w),
              Column(
                children: [
                  Text(
                    'VS',
                    style: TextStyles.font16DarkBlue600Weight,
                  ),
                  Gap(8.h),
                  Text(
                    '${summary.player1WinCount} - ${summary.player2WinCount}',
                    style: TextStyles.font14Grey400Weight,
                  ),
                ],
              ),
              Gap(16.w),
              Expanded(
                child: _buildPlayerSummaryCard(
                  _comparison!.player2,
                  summary.player2WinCount,
                  summary.overallWinner == 'player2',
                ),
              ),
            ],
          ),
          Gap(16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: ColorsManager.mainBlue,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  'Most Improved: ${summary.mostImprovedPlayer}',
                  style: TextStyles.font14DarkBlue600Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSummaryCard(
    PlayerPerformanceData player,
    int winCount,
    bool isWinner,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isWinner ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(
              Icons.emoji_events,
              color: Colors.green[600],
              size: 20.sp,
            ),
          Gap(4.h),
          Text(
            player.playerName,
            style: TextStyles.font14DarkBlue600Weight,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(4.h),
          Text(
            'Score: ${player.overallScore.toStringAsFixed(1)}',
            style: TextStyles.font12DarkBlue400Weight,
          ),
          Gap(4.h),
          Text(
            '$winCount skills won',
            style: TextStyles.font12DarkBlue400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildRadarComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Comparison',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        Center(
          child: ComparisonRadarChart(
            player1Data: _comparison!.player1.currentSkillScores,
            player2Data: _comparison!.player2.currentSkillScores,
            player1Name: _comparison!.player1.playerName,
            player2Name: _comparison!.player2.playerName,
            size: 280,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillComparisonTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Comparison',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Skill',
                        style: TextStyles.font14DarkBlue600Weight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _comparison!.player1.playerName,
                        style: TextStyles.font14DarkBlue600Weight,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _comparison!.player2.playerName,
                        style: TextStyles.font14DarkBlue600Weight,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Winner',
                        style: TextStyles.font14DarkBlue600Weight,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Skill rows
              ...SkillType.allSkills.map((skillType) {
                final comparison = _comparison!.skillComparisons[skillType]!;
                return _buildSkillComparisonRow(skillType, comparison);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillComparisonRow(
      SkillType skillType, ComparisonResult comparison) {
    final winner = comparison.scoreWinner;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Color(
                        int.parse('0xFF${skillType.colorHex.substring(1)}')),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                Gap(8.w),
                Text(
                  skillType.displayName,
                  style: TextStyles.font14DarkBlue600Weight,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              comparison.player1Score.toString(),
              style: TextStyles.font14DarkBlue600Weight.copyWith(
                color: winner == PlayerComparisonWinner.player1
                    ? Colors.green[600]
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              comparison.player2Score.toString(),
              style: TextStyles.font14DarkBlue600Weight.copyWith(
                color: winner == PlayerComparisonWinner.player2
                    ? Colors.green[600]
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: winner == PlayerComparisonWinner.tie
                  ? Icon(
                      Icons.remove,
                      color: ColorsManager.gray,
                      size: 16.sp,
                    )
                  : Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16.sp,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _comparison!.summary.recommendations;

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coaching Recommendations',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(16.h),
        ...recommendations.map((recommendation) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[600],
                    size: 20.sp,
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyles.font14DarkBlue600Weight,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
