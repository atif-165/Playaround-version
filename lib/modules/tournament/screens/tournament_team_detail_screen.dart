import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/navigation/detail_navigator.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../../team/models/models.dart';
import '../../team/screens/team_profile_screen.dart';
import '../../team/services/team_service.dart';
import '../models/player_match_stats.dart';

class TournamentTeamDetailScreen extends StatefulWidget {
  final TournamentTeam team;

  const TournamentTeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TournamentTeamDetailScreen> createState() =>
      _TournamentTeamDetailScreenState();
}

class _TournamentTeamDetailScreenState
    extends State<TournamentTeamDetailScreen> {
  bool _isOpeningFullView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.team.name,
          style: TextStyles.font16White600Weight,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 36.h),
            children: [
              _buildStatsCard(context),
              Gap(20.h),
              _buildRosterSection(),
              Gap(24.h),
              _buildFullDetailButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullDetailButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isOpeningFullView ? null : _openFullTeamDetail,
      style: ElevatedButton.styleFrom(
        backgroundColor: PublicProfileTheme.panelAccentColor,
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 18.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      icon: _isOpeningFullView
          ? SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
            )
          : const Icon(Icons.open_in_new_rounded),
      label: Text(
        _isOpeningFullView ? 'Loading team...' : 'View Full Team Detail',
        style: TextStyles.font14DarkBlue600Weight.copyWith(
          color: Colors.black87,
        ),
      ),
    );
  }

  Future<void> _openFullTeamDetail() async {
    if (_isOpeningFullView) return;
    setState(() => _isOpeningFullView = true);
    try {
      final teamId = widget.team.id;
      if (teamId.isEmpty) {
        throw Exception('Team reference is missing.');
      }

      final success =
          await DetailNavigator.openTeam(context, teamId: teamId);
      if (success) return;

      final fallbackTeam = _buildTeamModel(widget.team);
      if (fallbackTeam != null) {
        final opened = await DetailNavigator.openTeam(
          context,
          team: fallbackTeam,
        );
        if (opened) return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team detail could not be opened.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open team detail: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningFullView = false);
      }
    }
  }

  TeamModel? _buildTeamModel(TournamentTeam team) {
    final name = team.name.trim();
    if (name.isEmpty) return null;

    String _clean(String? value, String fallback) =>
        (value?.trim().isNotEmpty ?? false) ? value!.trim() : fallback;

    String _slugify(String source) =>
        source.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    final now = DateTime.now();
    final teamId =
        team.id.isNotEmpty ? team.id : 'tournament_${team.tournamentId}_${_slugify(name)}';

    final members = _buildMembers(team, now, teamId);
    if (members.isEmpty) {
      members.add(
        TeamMember(
          userId: 'captain_$teamId',
          userName: '$name Captain',
          role: TeamRole.captain,
          joinedAt: now,
        ),
      );
    }

    final metadata = <String, dynamic>{
      'wins': team.wins,
      'losses': team.losses,
      'draws': team.draws,
      'points': team.points,
      'goalsFor': team.goalsFor,
      'goalsAgainst': team.goalsAgainst,
      'tournamentId': team.tournamentId,
      if (team.captainName != null) 'captainName': team.captainName,
      if (team.coachName != null) 'coachName': team.coachName,
    };

    final rosterSize = members.length < 12
        ? 12
        : (members.length > 22 ? 22 : members.length);

    return TeamModel(
      id: teamId,
      name: name,
      description:
          'Tournament roster for $name in bracket ${team.tournamentId}. Currently ${team.wins}-${team.draws}-${team.losses} with ${team.points} pts.',
      bio: 'Auto-synced from tournament data.',
      sportType: SportType.other,
      ownerId: team.coachId ??
          team.captainId ??
          'tournament_${team.tournamentId}',
      members: members,
      maxMembers: rosterSize,
      isPublic: true,
      teamImageUrl: team.logoUrl,
      backgroundImageUrl: null,
      location: 'Tournament Circuit',
      coachId: team.coachId,
      coachName: team.coachName,
      venuesPlayed: const [],
      tournamentsParticipated: [team.tournamentId],
      createdAt: team.createdAt ?? now,
      updatedAt: now,
      metadata: metadata,
    );
  }

  List<TeamMember> _buildMembers(
    TournamentTeam team,
    DateTime now,
    String teamId,
  ) {
    final members = <TeamMember>[];

    if (team.coachName?.isNotEmpty ?? false) {
      members.add(
        TeamMember(
          userId: team.coachId?.isNotEmpty == true
              ? team.coachId!
              : 'coach_$teamId',
          userName: team.coachName!,
          profileImageUrl: team.coachImageUrl,
          role: TeamRole.coach,
          joinedAt: now.subtract(const Duration(days: 180)),
          trophies: team.points,
        ),
      );
    }

    if (team.captainName?.isNotEmpty ?? false) {
      members.add(
        TeamMember(
          userId: team.captainId?.isNotEmpty == true
              ? team.captainId!
              : 'captain_$teamId',
          userName: team.captainName!,
          role: TeamRole.captain,
          joinedAt: now.subtract(const Duration(days: 140)),
          trophies: team.wins,
        ),
      );
    }

    final playerIds = team.playerIds;
    final playerNames = team.playerNames;
    final limit = playerNames.length;

    for (var index = 0; index < limit; index++) {
      final playerName = playerNames[index].trim();
      if (playerName.isEmpty) continue;
      final playerId = index < playerIds.length && playerIds[index].trim().isNotEmpty
          ? playerIds[index].trim()
          : 'player_${teamId}_$index';

      members.add(
        TeamMember(
          userId: playerId,
          userName: playerName,
          role: TeamRole.member,
          joinedAt: now.subtract(Duration(days: 14 * (index + 1))),
        ),
      );
    }

    return members;
  }

  Widget _buildStatsCard(BuildContext context) {
    final team = widget.team;
    final record =
        '${team.wins}W • ${team.draws}D • ${team.losses}L (${team.points} pts)';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.team.name,
            style: TextStyles.font18White600Weight,
          ),
          Gap(8.h),
          Text(
            record,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: Colors.white70,
            ),
          ),
          Gap(16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _buildStatChip('Goals For', team.goalsFor.toString()),
              _buildStatChip('Goals Against', team.goalsAgainst.toString()),
              _buildStatChip(
                'Goal Difference',
                (team.goalsFor - team.goalsAgainst).toString(),
              ),
            ],
          ),
          if (team.captainName != null) ...[
            Gap(16.h),
            Text(
              'Captain: ${team.captainName}',
              style: TextStyles.font12Grey400Weight.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.font10Grey400Weight.copyWith(
              color: Colors.white70,
            ),
          ),
          Gap(4.h),
          Text(
            value,
            style: TextStyles.font16White600Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildRosterSection() {
    final roster = widget.team.playerNames;
    if (roster.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Text(
          'Roster details coming soon.',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: Colors.white70,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Roster',
            style: TextStyles.font16White600Weight,
          ),
          Gap(12.h),
          ...roster.map(
            (player) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white54, size: 18),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      player,
                      style: TextStyles.font14White400Weight,
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
}

