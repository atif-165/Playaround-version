import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../models/team_match_model.dart';
import '../models/team_profile_models.dart';
import '../services/team_service.dart';
import '../../tournament/models/tournament_model.dart';
import '../../tournament/services/tournament_service.dart';
import '../../coach/services/coach_service.dart';
import '../../../models/coach_profile.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';

class TeamAdminDataTab extends StatefulWidget {
  const TeamAdminDataTab({
    super.key,
    required this.team,
    this.isReadOnly = false,
  });

  final Team team;
  final bool isReadOnly;

  @override
  State<TeamAdminDataTab> createState() => _TeamAdminDataTabState();
}

class _TeamAdminDataTabState extends State<TeamAdminDataTab> {
  final TeamService _teamService = TeamService();
  final TournamentService _tournamentService = TournamentService();
  final CoachService _coachService = CoachService();
  final NotificationService _notificationService = NotificationService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final Uuid _uuid = const Uuid();

  bool get _isReadOnly => !AppConfig.enablePublicTeamAdmin && widget.isReadOnly;

  // Search state for tournaments and coaches
  final TextEditingController _tournamentSearchController =
      TextEditingController();
  final TextEditingController _coachSearchController = TextEditingController();
  List<Tournament> _tournamentSearchResults = const [];
  List<CoachProfile> _coachSearchResults = const [];
  bool _isSearchingTournaments = false;
  bool _isSearchingCoaches = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isReadOnly)
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: ColorsManager.surfaceVariant,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: ColorsManager.gray,
                    size: 18.sp,
                  ),
                  Gap(8.w),
                  Expanded(
                    child: Text(
                      'Public view mode. Sign in as a team admin to edit these sections.',
                      style: TextStyles.font12Grey400Weight,
                    ),
                  ),
                ],
              ),
            ),
          _buildSectionHeader(
            title: 'Achievements',
            actionLabel: 'Add',
            onAction: _isReadOnly ? null : _showAchievementForm,
          ),
          _buildAchievementsList(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Team Custom Stats',
            actionLabel: 'Add',
            onAction: _isReadOnly ? null : _showCustomStatForm,
          ),
          _buildCustomStatsList(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Player Highlights',
            actionLabel: 'Add',
            onAction: _isReadOnly ? null : _showPlayerStatForm,
          ),
          _buildPlayerHighlightsList(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Manual Matches',
            actionLabel: 'Create',
            onAction: _isReadOnly ? null : _showMatchForm,
          ),
          _buildMatchesPreview(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Venue History',
            actionLabel: 'Add',
            onAction: _isReadOnly ? null : _showHistoryForm,
          ),
          _buildHistoryPreview(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Tournament Entries',
            actionLabel: 'Add',
            onAction: _isReadOnly ? null : _showTournamentForm,
          ),
          _buildTournamentPreview(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Link Public Tournaments',
            actionLabel: 'Search',
            onAction: _isReadOnly ? null : _openTournamentSearchSheet,
          ),
          _buildTournamentSearchPreview(),
          Gap(24.h),
          _buildSectionHeader(
            title: 'Coaching Staff',
            actionLabel: 'Search',
            onAction: _isReadOnly ? null : _openCoachSearchSheet,
          ),
          _buildCoachSearchPreview(),
          Gap(16.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String actionLabel = 'Add',
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyles.font16DarkBlue600Weight
                .copyWith(color: ColorsManager.textPrimary),
          ),
        ),
        if (onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          )
        else
          _buildViewOnlyChip(),
      ],
    );
  }

  Widget _buildViewOnlyChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.gray.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'View Only',
        style: TextStyles.font12Grey400Weight,
      ),
    );
  }

  Widget _buildAchievementsList() {
    return StreamBuilder<List<TeamAchievement>>(
      stream: _teamService.watchTeamAchievements(widget.team.id),
      builder: (context, snapshot) {
        final achievements = snapshot.data ?? [];
        if (achievements.isEmpty) {
          return _buildEmptyCard('No achievements recorded yet.');
        }
        return Column(
          children: achievements.map((achievement) {
            final dateLabel = _dateFormat.format(achievement.achievedAt);
            return _glassCard(
              child: ListTile(
                title: Text(
                  achievement.title,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '$dateLabel • ${achievement.type}',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCustomStatsList() {
    return StreamBuilder<List<TeamCustomStat>>(
      stream: _teamService.watchTeamCustomStats(widget.team.id),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? [];
        if (stats.isEmpty) {
          return _buildEmptyCard('No custom team stats yet.');
        }
        return Column(
          children: stats.map((stat) {
            return _glassCard(
              child: ListTile(
                title: Text(
                  stat.label,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  stat.description ?? 'Custom stat',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
                trailing: Text(
                  stat.units != null && stat.units!.isNotEmpty
                      ? '${stat.value} ${stat.units}'
                      : stat.value,
                  style: TextStyles.font14White600Weight
                      .copyWith(color: PublicProfileTheme.panelAccentColor),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlayerHighlightsList() {
    return StreamBuilder<List<PlayerPerformance>>(
      stream: _teamService.getTeamPlayerPerformances(widget.team.id),
      builder: (context, snapshot) {
        final performances = snapshot.data ?? [];
        if (performances.isEmpty) {
          return _buildEmptyCard('No player highlight stats yet.');
        }
        return Column(
          children: performances.map((performance) {
            return _glassCard(
              child: ListTile(
                title: Text(
                  performance.playerName,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  'Matches ${performance.matchesPlayed} • Goals ${performance.goalsScored} • Assists ${performance.assists}',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMatchesPreview() {
    return StreamBuilder<List<TeamMatch>>(
      stream: _teamService.watchTeamScheduleMatches(widget.team.id),
      builder: (context, snapshot) {
        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return _buildEmptyCard('No manual matches created yet.');
        }
        return Column(
          children: matches.take(5).map((match) {
            final dateLabel =
                DateFormat('MMM d, h:mm a').format(match.scheduledTime);
            return _glassCard(
              child: ListTile(
                title: Text(
                  '${match.homeTeam.teamName} vs ${match.awayTeam.teamName}',
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '${match.matchType.displayName} • $dateLabel',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHistoryPreview() {
    return StreamBuilder<List<TeamHistoryEntry>>(
      stream: _teamService.watchTeamHistory(widget.team.id, limit: 5),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return _buildEmptyCard('No venue history entries yet.');
        }
        return Column(
          children: entries.map((entry) {
            final dateLabel = _dateFormat.format(entry.date);
            return _glassCard(
              child: ListTile(
                title: Text(
                  entry.venue,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '$dateLabel • vs ${entry.opponent}',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTournamentPreview() {
    return StreamBuilder<List<TeamTournamentEntry>>(
      stream: _teamService.watchTeamTournaments(widget.team.id),
      builder: (context, snapshot) {
        final tournaments = snapshot.data ?? [];
        if (tournaments.isEmpty) {
          return _buildEmptyCard('No tournament entries added yet.');
        }
        return Column(
          children: tournaments.take(5).map((entry) {
            final dateLabel = _dateFormat.format(entry.startDate);
            return _glassCard(
              child: ListTile(
                title: Text(
                  entry.tournamentName,
                  style: TextStyles.font14White600Weight,
                ),
                subtitle: Text(
                  '$dateLabel • ${entry.stage}',
                  style: TextStyles.font12White500Weight
                      .copyWith(color: Colors.white70),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- New: Tournament search + quick link preview ---

  Widget _buildTournamentSearchPreview() {
    if (_tournamentSearchResults.isEmpty) {
      return _buildEmptyCard(
        _isReadOnly
            ? 'Tournament linking is view-only in this mode.'
            : 'Search tournaments to link your team with official events.',
      );
    }

    return Column(
      children: _tournamentSearchResults.map((tournament) {
        return _glassCard(
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(
              tournament.name,
              style: TextStyles.font14White600Weight,
            ),
            subtitle: Text(
              tournament.location ?? 'Online / TBA',
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
            ),
            trailing: _isReadOnly
                ? null
                : TextButton(
                    onPressed: () => _linkTeamToTournament(tournament),
                    child: const Text('Add'),
                  ),
          ),
        );
      }).toList(),
    );
  }

  // --- New: Coach search + quick link preview ---

  Widget _buildCoachSearchPreview() {
    if (_coachSearchResults.isEmpty) {
      return _buildEmptyCard(
        _isReadOnly
            ? 'Coach linking is view-only in this mode.'
            : 'Search coaches to invite them to your team staff.',
      );
    }

    return Column(
      children: _coachSearchResults.map((coach) {
        final sports = coach.specializationSports.join(', ');
        return _glassCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: coach.profilePictureUrl != null
                  ? NetworkImage(coach.profilePictureUrl!)
                  : null,
              child: coach.profilePictureUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(
              coach.fullName,
              style: TextStyles.font14White600Weight,
            ),
            subtitle: Text(
              sports.isEmpty ? 'Coach' : sports,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
            ),
            trailing: _isReadOnly
                ? null
                : TextButton(
                    onPressed: () => _inviteCoachToTeam(coach),
                    child: const Text('Add'),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openCoachSearchSheet() async {
    if (_isReadOnly) return;

    _coachSearchController.clear();
    setState(() {
      _coachSearchResults = const [];
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Coaches',
                style: TextStyles.font16White600Weight,
              ),
              Gap(12.h),
              TextField(
                controller: _coachSearchController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(
                  hintText: 'Type coach name...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => _performCoachSearch(value.trim()),
              ),
              Gap(12.h),
              if (_isSearchingCoaches)
                const LinearProgressIndicator(minHeight: 2),
              Flexible(
                child: _coachSearchResults.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          'No coaches found yet.\nTry a different name.',
                          style: TextStyles.font12White500Weight
                              .copyWith(color: Colors.white60),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _coachSearchResults.length,
                        itemBuilder: (context, index) {
                          final coach = _coachSearchResults[index];
                          final sports =
                              coach.specializationSports.join(', ');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: coach.profilePictureUrl != null
                                  ? NetworkImage(coach.profilePictureUrl!)
                                  : null,
                              child: coach.profilePictureUrl == null
                                  ? const Icon(Icons.person_outline)
                                  : null,
                            ),
                            title: Text(
                              coach.fullName,
                              style: TextStyles.font14White600Weight,
                            ),
                            subtitle: Text(
                              sports.isEmpty ? 'Coach' : sports,
                              style: TextStyles.font12White500Weight
                                  .copyWith(color: Colors.white70),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await _inviteCoachToTeam(coach);
                              },
                              child: const Text('Add'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performCoachSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _coachSearchResults = const []);
      return;
    }

    setState(() => _isSearchingCoaches = true);
    try {
      final results =
          await _coachService.searchCoachesByName(query, limit: 20);
      if (!mounted) return;
      setState(() {
        _coachSearchResults = results;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to search coaches right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingCoaches = false);
      }
    }
  }

  Future<void> _inviteCoachToTeam(CoachProfile coach) async {
    try {
      await _notificationService.createNotification(
        userId: coach.uid,
        type: NotificationType.coachTeamRequest,
        title: 'Team added you as coach',
        message:
            '"${widget.team.name}" wants to add you to their coaching staff. Approve or deny this request.',
        data: {
          'coachId': coach.uid,
          'coachName': coach.fullName,
          'teamId': widget.team.id,
          'teamName': widget.team.name,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Invitation sent to ${coach.fullName} to join as coach.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to invite coach: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openTournamentSearchSheet() async {
    if (_isReadOnly) return;

    _tournamentSearchController.clear();
    setState(() {
      _tournamentSearchResults = const [];
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 16.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search Tournaments',
                style: TextStyles.font16White600Weight,
              ),
              Gap(12.h),
              TextField(
                controller: _tournamentSearchController,
                style: TextStyles.font14White500Weight,
                decoration: const InputDecoration(
                  hintText: 'Type tournament name...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => _performTournamentSearch(value.trim()),
              ),
              Gap(12.h),
              if (_isSearchingTournaments)
                const LinearProgressIndicator(minHeight: 2),
              Flexible(
                child: _tournamentSearchResults.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Text(
                          'No tournaments found yet.\nTry a different name.',
                          style: TextStyles.font12White500Weight
                              .copyWith(color: Colors.white60),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _tournamentSearchResults.length,
                        itemBuilder: (context, index) {
                          final tournament = _tournamentSearchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.emoji_events_outlined,
                              color: Colors.amber,
                            ),
                            title: Text(
                              tournament.name,
                              style: TextStyles.font14White600Weight,
                            ),
                            subtitle: Text(
                              tournament.location ?? 'Online / TBA',
                              style: TextStyles.font12White500Weight
                                  .copyWith(color: Colors.white70),
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await _linkTeamToTournament(tournament);
                              },
                              child: const Text('Add'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performTournamentSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _tournamentSearchResults = const []);
      return;
    }

    setState(() => _isSearchingTournaments = true);
    try {
      final results = await _tournamentService.searchTournaments(query);
      if (!mounted) return;
      setState(() {
        _tournamentSearchResults = results;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to search tournaments right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSearchingTournaments = false);
      }
    }
  }

  Future<void> _linkTeamToTournament(Tournament tournament) async {
    try {
      await _tournamentService.addTeamToTournament(
        tournamentId: tournament.id,
        teamId: widget.team.id,
      );

      if (tournament.organizerId.isNotEmpty) {
        await _notificationService.createNotification(
          userId: tournament.organizerId,
          type: NotificationType.tournamentRegistration,
          title: 'Team added to your tournament',
          message:
              '"${widget.team.name}" has requested to join "${tournament.name}".',
          data: {
            'tournamentId': tournament.id,
            'teamId': widget.team.id,
            'teamName': widget.team.name,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Requested to add ${widget.team.name} to ${tournament.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to link tournament: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double borderRadius = 18,
  }) {
    final radius = borderRadius.r;
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 12.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: PublicProfileTheme.defaultBlurSigma,
            sigmaY: PublicProfileTheme.defaultBlurSigma,
          ),
          child: Container(
            padding: padding ?? EdgeInsets.all(16.w),
            decoration: PublicProfileTheme.glassPanelDecoration(
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return _glassCard(
      padding: EdgeInsets.all(16.w),
      child: Text(
        message,
        style: TextStyles.font13White500Weight
            .copyWith(color: Colors.white70),
      ),
    );
  }

  Future<void> _showAchievementForm() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime achievedAt = DateTime.now();
    String type = 'milestone';

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Achievement',
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(16.h),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'milestone',
                      child: Text('Milestone'),
                    ),
                    DropdownMenuItem(
                      value: 'tournament_win',
                      child: Text('Tournament Win'),
                    ),
                    DropdownMenuItem(
                      value: 'record',
                      child: Text('Record'),
                    ),
                  ],
                  onChanged: (value) => type = value ?? type,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                Gap(12.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text('Achieved On: ${_dateFormat.format(achievedAt)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await _pickDate(context, achievedAt);
                    if (picked != null) {
                      setModalState(() {
                        achievedAt = picked;
                      });
                    }
                  },
                ),
                Gap(20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final achievement = TeamAchievement(
                        id: _uuid.v4(),
                        teamId: widget.team.id,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        type: type,
                        achievedAt: achievedAt,
                      );
                      await _teamService.upsertTeamAchievement(
                        widget.team.id,
                        achievement,
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save achievement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomStatForm() async {
    final labelController = TextEditingController();
    final valueController = TextEditingController();
    final unitsController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Custom Stat',
                style: TextStyles.font16DarkBlue600Weight,
              ),
              Gap(16.h),
              TextFormField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Value'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: unitsController,
                decoration: const InputDecoration(labelText: 'Units (optional)'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              Gap(20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final stat = TeamCustomStat(
                      id: _uuid.v4(),
                      label: labelController.text.trim(),
                      value: valueController.text.trim(),
                      units: unitsController.text.trim().isEmpty
                          ? null
                          : unitsController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                    await _teamService.upsertCustomStat(
                      widget.team.id,
                      stat,
                    );
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save stat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPlayerStatForm() async {
    final playerNameController = TextEditingController();
    final playerIdController = TextEditingController();
    final matchesController = TextEditingController();
    final goalsController = TextEditingController();
    final assistsController = TextEditingController();
    final savesController = TextEditingController();
    final ratingController = TextEditingController();
    final winRatioController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Player Highlight',
                style: TextStyles.font16DarkBlue600Weight,
              ),
              Gap(16.h),
              TextFormField(
                controller: playerNameController,
                decoration: const InputDecoration(labelText: 'Player name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: playerIdController,
                decoration: const InputDecoration(
                  labelText: 'Player ID (optional)',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: matchesController,
                      decoration:
                          const InputDecoration(labelText: 'Matches played'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: TextFormField(
                      controller: goalsController,
                      decoration: const InputDecoration(labelText: 'Goals'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: assistsController,
                      decoration: const InputDecoration(labelText: 'Assists'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: TextFormField(
                      controller: savesController,
                      decoration: const InputDecoration(labelText: 'Saves'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ratingController,
                      decoration:
                          const InputDecoration(labelText: 'Rating (0-10)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: TextFormField(
                      controller: winRatioController,
                      decoration: const InputDecoration(
                          labelText: 'Win ratio (0-100%)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              Gap(20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final playerId = playerIdController.text.trim().isEmpty
                        ? _uuid.v4()
                        : playerIdController.text.trim();
                    final matches =
                        int.tryParse(matchesController.text.trim()) ?? 0;
                    final goals =
                        int.tryParse(goalsController.text.trim()) ?? 0;
                    final assists =
                        int.tryParse(assistsController.text.trim()) ?? 0;
                    final saves =
                        int.tryParse(savesController.text.trim()) ?? 0;
                    final rating =
                        double.tryParse(ratingController.text.trim()) ?? 0;
                    final winRatioPercent =
                        double.tryParse(winRatioController.text.trim()) ?? 0;

                    final performance = PlayerPerformance(
                      playerId: playerId,
                      playerName: playerNameController.text.trim(),
                      teamId: widget.team.id,
                      matchesPlayed: matches,
                      goalsScored: goals,
                      assists: assists,
                      saves: saves,
                      winRatio: winRatioPercent / 100,
                      averageRating: rating,
                      customStats: const {},
                      lastUpdated: DateTime.now(),
                    );

                    await _teamService.updatePlayerPerformance(performance);
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Player stats updated.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save player stats'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMatchForm() async {
    final opponentController = TextEditingController();
    final venueController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    DateTime scheduledTime = DateTime.now();
    TeamMatchStatus status = TeamMatchStatus.scheduled;
    TeamMatchType matchType = TeamMatchType.friendly;
    bool isHomeMatch = true;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setLocalState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Upcoming Match',
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(16.h),
                SwitchListTile.adaptive(
                  value: isHomeMatch,
                  onChanged: (value) =>
                      setLocalState(() => isHomeMatch = value),
                  title: const Text('Match hosted by our team'),
                ),
                TextFormField(
                  controller: opponentController,
                  decoration: const InputDecoration(labelText: 'Opponent name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue name'),
                ),
                TextFormField(
                  controller: locationController,
                  decoration:
                      const InputDecoration(labelText: 'Location / city'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Scheduled: ${DateFormat('MMM d, h:mm a').format(scheduledTime)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await _pickDateTime(context, scheduledTime);
                    if (picked != null) {
                      setLocalState(() => scheduledTime = picked);
                    }
                  },
                ),
                DropdownButtonFormField<TeamMatchStatus>(
                  value: status,
                  items: TeamMatchStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setLocalState(() {
                    status = value ?? status;
                  }),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                DropdownButtonFormField<TeamMatchType>(
                  value: matchType,
                  items: TeamMatchType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setLocalState(() {
                    matchType = value ?? matchType;
                  }),
                  decoration: const InputDecoration(labelText: 'Match type'),
                ),
                TextFormField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                Gap(20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final matchId = _uuid.v4();
                      final opponentName = opponentController.text.trim();
                      final homeTeam = TeamScore(
                        teamId: widget.team.id,
                        teamName: widget.team.name,
                        score: 0,
                      );
                      final awayTeam = TeamScore(
                        teamId: 'opponent_$matchId',
                        teamName: opponentName,
                        score: 0,
                      );
                      final match = TeamMatch(
                        id: matchId,
                        homeTeamId:
                            isHomeMatch ? widget.team.id : 'opponent_$matchId',
                        awayTeamId:
                            isHomeMatch ? 'opponent_$matchId' : widget.team.id,
                        homeTeam: isHomeMatch ? homeTeam : awayTeam,
                        awayTeam: isHomeMatch ? awayTeam : homeTeam,
                        sportType: widget.team.sportType,
                        matchType: matchType,
                        status: status,
                        scheduledTime: scheduledTime,
                        venueName:
                            venueController.text.trim().isEmpty ? null : venueController.text.trim(),
                        venueLocation:
                            locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await _teamService.upsertTeamMatch(
                        widget.team.id,
                        match,
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save match'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showHistoryForm() async {
    final venueController = TextEditingController();
    final venueIdController = TextEditingController();
    final opponentController = TextEditingController();
    final matchTypeController = TextEditingController();
    final resultController = TextEditingController();
    final summaryController = TextEditingController();
    final locationController = TextEditingController();
    final matchIdController = TextEditingController();
    DateTime date = DateTime.now();

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Venue History',
                  style: TextStyles.font16DarkBlue600Weight,
                ),
                Gap(16.h),
                TextFormField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: venueIdController,
                  decoration: const InputDecoration(
                    labelText: 'Linked venue ID (optional)',
                  ),
                ),
                TextFormField(
                  controller: opponentController,
                  decoration: const InputDecoration(labelText: 'Opponent'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: matchTypeController,
                  decoration: const InputDecoration(labelText: 'Match type'),
                ),
                TextFormField(
                  controller: resultController,
                  decoration: const InputDecoration(labelText: 'Result'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Match Date: ${_dateFormat.format(date)}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await _pickDate(context, date);
                    if (picked != null) {
                      setModalState(() => date = picked);
                    }
                  },
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextFormField(
                  controller: summaryController,
                  decoration:
                      const InputDecoration(labelText: 'Summary / notes'),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: matchIdController,
                  decoration: const InputDecoration(
                    labelText: 'Match ID (optional link)',
                  ),
                ),
                Gap(20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final entry = TeamHistoryEntry(
                        id: _uuid.v4(),
                        venue: venueController.text.trim(),
                        venueId: venueIdController.text.trim().isEmpty
                            ? null
                            : venueIdController.text.trim(),
                        opponent: opponentController.text.trim(),
                        date: date,
                        matchType: matchTypeController.text.trim().isEmpty
                            ? 'Friendly'
                            : matchTypeController.text.trim(),
                        result: resultController.text.trim().isEmpty
                            ? 'Pending'
                            : resultController.text.trim(),
                        summary: summaryController.text.trim(),
                        location: locationController.text.trim(),
                        matchId: matchIdController.text.trim().isEmpty
                            ? null
                            : matchIdController.text.trim(),
                      );
                      await _teamService.upsertHistoryEntry(
                        widget.team.id,
                        entry,
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save history'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTournamentForm() async {
    final nameController = TextEditingController();
    final statusController = TextEditingController(text: 'Upcoming');
    final stageController = TextEditingController(text: 'Group Stage');
    final logoController = TextEditingController();
    final tournamentIdController = TextEditingController();
    DateTime startDate = DateTime.now();

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 24.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Tournament Entry',
                style: TextStyles.font16DarkBlue600Weight,
              ),
              Gap(16.h),
              TextFormField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Tournament name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: stageController,
                decoration: const InputDecoration(labelText: 'Stage'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Starts: ${_dateFormat.format(startDate)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await _pickDate(context, startDate);
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              TextFormField(
                controller: tournamentIdController,
                decoration: const InputDecoration(
                  labelText: 'Linked tournament ID (optional)',
                ),
              ),
              TextFormField(
                controller: logoController,
                decoration: const InputDecoration(
                  labelText: 'Logo URL (optional)',
                ),
              ),
              Gap(20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final entry = TeamTournamentEntry(
                      id: _uuid.v4(),
                      tournamentName: nameController.text.trim(),
                      status: statusController.text.trim(),
                      stage: stageController.text.trim(),
                      startDate: startDate,
                      tournamentId: tournamentIdController.text.trim().isEmpty
                          ? null
                          : tournamentIdController.text.trim(),
                      logoUrl: logoController.text.trim().isEmpty
                          ? null
                          : logoController.text.trim(),
                    );
                    await _teamService.upsertTournamentEntry(
                      widget.team.id,
                      entry,
                    );
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime initialDate) async {
    final date = await _pickDate(context, initialDate);
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

