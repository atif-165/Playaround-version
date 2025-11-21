import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/live_match_models.dart';
import '../models/tournament_match_model.dart';
import '../models/tournament_model.dart';
import '../services/live_match_service.dart';
import '../services/live_reaction_service.dart';

const _matchHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

class LiveMatchDetailScreen extends StatefulWidget {
  const LiveMatchDetailScreen({
    super.key,
    required this.match,
    this.tournament,
  });

  final TournamentMatch match;
  final Tournament? tournament;

  @override
  State<LiveMatchDetailScreen> createState() => _LiveMatchDetailScreenState();
}
class _LiveMatchDetailScreenState extends State<LiveMatchDetailScreen> {
  final LiveMatchService _liveService = LiveMatchService();
  final LiveReactionService _reactionService = LiveReactionService();
  StreamSubscription<LiveMatch>? _subscription;
  StreamSubscription<List<LiveReaction>>? _reactionSubscription;
  LiveMatch? _liveMatch;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _commentaryScrollController = ScrollController();
  final ScrollController _reactionsScrollController = ScrollController();
  final List<LiveReaction> _optimisticReactions = [];
  List<LiveReaction> _remoteReactions = [];

  final List<Map<String, String>> _quickReplyEmojis = const [
    {'emoji': '🔥', 'label': 'Fire'},
    {'emoji': '💯', 'label': 'Hot 100'},
    {'emoji': '💀', 'label': 'Skull'},
    {'emoji': '🎉', 'label': 'Celebration'},
    {'emoji': '❤️', 'label': 'Heart'},
    {'emoji': '⚡', 'label': 'Lightning'},
    {'emoji': '👏', 'label': 'Clap'},
    {'emoji': '🙌', 'label': 'Hands Up'},
    {'emoji': '😍', 'label': 'Love'},
    {'emoji': '🥳', 'label': 'Party'},
    {'emoji': '🤯', 'label': 'Mind Blown'},
    {'emoji': '😱', 'label': 'Shocked'},
  ];

  final List<Map<String, String>> _quickReplies = const [
    {'text': 'Great match!', 'emoji': '👏'},
    {'text': 'What a goal!', 'emoji': '⚽'},
    {'text': 'Unbelievable!', 'emoji': '🤯'},
    {'text': 'Well played!', 'emoji': '🙌'},
    {'text': 'Amazing!', 'emoji': '🔥'},
  ];

  List<LiveReaction> get _displayReactions {
    final combined = [..._optimisticReactions, ..._remoteReactions];
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final seenIds = <String>{};
    final deduped = <LiveReaction>[];
    for (final reaction in combined) {
      if (reaction.id.startsWith('local-')) {
        deduped.add(reaction);
        continue;
      }
      if (seenIds.add(reaction.id)) {
        deduped.add(reaction);
      }
    }
    return deduped.take(40).toList();
  }

  @override
  void initState() {
    super.initState();
    _liveMatch = LiveMatchMapper.fromTournamentMatch(widget.match);
    _subscription = _liveService.watchMatch(widget.match.id).listen((event) {
      if (!mounted) return;
      setState(() {
        _liveMatch = event;
      });
    });
    _reactionSubscription =
        _reactionService.watchReactions(widget.match.id).listen((event) {
      if (!mounted) return;
      setState(() {
        _remoteReactions = event;
        _optimisticReactions.removeWhere(
          (local) => event.any(
            (remote) => _areReactionsEquivalent(local, remote),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reactionSubscription?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _commentaryScrollController.dispose();
    _reactionsScrollController.dispose();
    super.dispose();
  }

  void _scrollReactionsToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_reactionsScrollController.hasClients) {
        _reactionsScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _addOptimisticReaction({
    required String userId,
    required String userName,
    String? emoji,
    String? text,
    required String reactionType,
  }) {
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final reaction = LiveReaction(
      id: tempId,
      userId: userId,
      userName: userName,
      emoji: emoji,
      text: text,
      reactionType: reactionType,
      timestamp: DateTime.now(),
    );
    setState(() {
      _optimisticReactions.insert(0, reaction);
      if (_optimisticReactions.length > 12) {
        _optimisticReactions.removeLast();
      }
    });
    _scrollReactionsToTop();
    return tempId;
  }

  void _removeOptimisticReaction(String tempId) {
    if (!mounted) return;
    setState(() {
      _optimisticReactions.removeWhere((reaction) => reaction.id == tempId);
    });
  }

  Future<void> _submitReaction({
    String? emoji,
    String? text,
    required String reactionType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'fan';
    final userName = user?.displayName ?? user?.email ?? 'Fan';
    final tempId = _addOptimisticReaction(
      userId: userId,
      userName: userName,
      emoji: emoji,
      text: text,
      reactionType: reactionType,
    );
    try {
      await _reactionService.addReaction(
        matchId: widget.match.id,
        userId: userId,
        userName: userName,
        emoji: emoji,
        text: text,
        reactionType: reactionType,
      );
      // removed auto-clearing. Remote snapshot will replace optimistic entry.
    } catch (e) {
      _removeOptimisticReaction(tempId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to send reaction. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  bool get _isAdmin => false;

  String get _heroTournamentName =>
      widget.tournament?.name ?? widget.match.tournamentName;

  String get _heroMatchLabel => widget.match.matchNumber;

  String get _heroRoundLabel =>
      widget.match.round?.toUpperCase() ?? widget.match.status.displayName;

  String get _heroVenueLabel =>
      widget.match.venueName ??
      widget.match.venueLocation ??
      widget.tournament?.venueName ??
      'Venue to be announced';

  @override
  Widget build(BuildContext context) {
    final live = _liveMatch;
    if (live == null) {
      return const Scaffold(
        backgroundColor: ColorsManager.surface,
        body: Center(
          child: CircularProgressIndicator(color: ColorsManager.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.match.matchNumber,
          style: TextStyles.font16White600Weight,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: _matchHeroGradient,
          ),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: _showAdminQuickActions,
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1100;
              return SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    _buildHeroSection(live),
                    Gap(16.h),
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildLivePlayersSection(live),
                              ),
                              Gap(16.w),
                              Expanded(
                                flex: 2,
                                child: _buildEngagementSection(live),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildLivePlayersSection(live),
                              Gap(16.h),
                              _buildEngagementSection(live),
                            ],
                          ),
                    if (_isAdmin) ...[
                      Gap(20.h),
                      _buildAdminControlPanel(live),
                    ],
                    Gap(40.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(LiveMatch match) {
    final statusLabel = switch (match.phase) {
      MatchPhase.upcoming => 'UPCOMING',
      MatchPhase.live => 'LIVE',
      MatchPhase.completed => 'FINAL',
      MatchPhase.cancelled => 'CANCELLED',
    };
    final statusColor = switch (match.phase) {
      MatchPhase.upcoming => ColorsManager.primary,
      MatchPhase.live => Colors.redAccent,
      MatchPhase.completed => Colors.greenAccent,
      MatchPhase.cancelled => Colors.grey,
    };
    final dateLabel =
        DateFormat('EEE, MMM d • h:mm a').format(match.startTime.toLocal());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 50,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.r),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
        gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
          colors: [
                    Color(0xFF22204F),
                    Color(0xFF090817),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorsManager.mainBlue.withOpacity(0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -20,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorsManager.primary.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(32.r),
      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(26.w),
      child: Column(
        children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12.w,
                    runSpacing: 8.h,
            children: [
              _statusPill(statusLabel, statusColor),
                      _heroBadge(
                        icon: Icons.calendar_today_outlined,
                        label: dateLabel,
                      ),
                    ],
                  ),
                  Gap(18.h),
                  Column(
                    children: [
              Text(
                        _heroTournamentName,
                        style: TextStyles.font14White600Weight.copyWith(
                  color: Colors.white70,
                ),
              ),
                      Gap(6.h),
                      Text(
                        _heroRoundLabel,
                        style: TextStyles.font24WhiteBold,
                      ),
                    ],
                  ),
                  Gap(24.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26.r),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.04),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
            children: [
                        Expanded(
                          child: _teamScoreTile(
                            match.teamA,
                            alignEnd: true,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 12.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorsManager.primary.withOpacity(0.95),
                                ColorsManager.mainBlue.withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    ColorsManager.mainBlue.withOpacity(0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: _scoreCenter(match),
                        ),
              Expanded(child: _teamScoreTile(match.teamB)),
                      ],
                    ),
                  ),
                  Gap(20.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16.sp,
                        color: Colors.white70,
                      ),
                      Gap(6.w),
                      Expanded(
                        child: Text(
                          _heroVenueLabel,
                          style: TextStyles.font12White500Weight.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      _heroBadge(
                        icon: match.isLive
                            ? Icons.wifi_tethering
                            : Icons.timer_outlined,
                        label: match.isLive
                            ? 'Streaming live'
                            : DateFormat('h:mm a').format(match.startTime),
                      ),
            ],
          ),
          if (match.isCompleted && match.winnerTeamId != null) ...[
                    Gap(16.h),
            _winnerBanner(match),
          ],
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Gap(6.w),
          Text(
            text,
            style: TextStyles.font12White600Weight.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _teamScoreTile(LiveTeam team, {bool alignEnd = false}) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) _teamAvatar(team),
            if (!alignEnd) Gap(10.w),
            Expanded(
              child: Text(
          team.name,
                style: TextStyles.font16White600Weight.copyWith(
            color: team.isWinner ? ColorsManager.primary : Colors.white,
          ),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (alignEnd) ...[
              Gap(10.w),
              _teamAvatar(team),
            ],
          ],
        ),
        Gap(10.h),
        Align(
          alignment:
              alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: team.isWinner
                    ? ColorsManager.primary.withOpacity(0.45)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${team.score}',
                  style: TextStyles.font28White700Weight.copyWith(
                    color:
                        team.isWinner ? ColorsManager.primary : Colors.white,
              ),
            ),
            if (team.isWinner) ...[
              Gap(6.w),
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
            ],
          ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _teamAvatar(LiveTeam team) {
    final initials =
        team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyles.font16White600Weight,
      ),
    );
  }

  Widget _scoreCenter(LiveMatch match) {
    final defaultValue = match.isLive
        ? '${match.currentMinute}′'
        : match.isUpcoming
            ? 'Kickoff in ${_formatCountdown(match.countdownSeconds)}'
            : 'Full Time';
    final badge = _centerBadgeConfig(match);
    final label =
        (badge?['label'] as String?)?.trim().isNotEmpty == true
            ? (badge?['label'] as String).trim()
            : match.template.label;
    final configuredValue =
        (badge?['value'] as String?)?.trim().isNotEmpty == true
            ? (badge?['value'] as String).trim()
            : null;
    final value = configuredValue ?? defaultValue;
    final countdownWidget = _buildCenterCountdown(badge);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyles.font12White500Weight.copyWith(
            color: Colors.white70,
          ),
        ),
        Gap(6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyles.font13White500Weight,
              ),
              if (countdownWidget != null) ...[
                Gap(8.w),
                countdownWidget,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _centerBadgeConfig(LiveMatch match) {
    final metadata = match.metadata;
    if (metadata == null) return null;
    final badge = metadata['centerBadge'];
    if (badge is Map<String, dynamic>) {
      return badge;
    }
    return null;
  }

  Widget? _buildCenterCountdown(Map<String, dynamic>? badge) {
    if (badge == null) return null;
    final countdown = badge['countdown'];
    if (countdown is! Map<String, dynamic>) return null;
    if (countdown['enabled'] != true) return null;

    final direction = (countdown['direction'] as String?) ?? 'up';
    final initial = (countdown['initialSeconds'] as num?)?.toInt() ?? 0;
    final savedAt = _parseMetadataDateTime(countdown['savedAt']) ?? DateTime.now();
    return _CountdownBadge(
      direction: direction,
      initialSeconds: initial,
      savedAt: savedAt,
      formatter: _formatBadgeCountdown,
    );
  }

  DateTime? _parseMetadataDateTime(dynamic value) {
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

  String _formatBadgeCountdown(int seconds) {
    if (seconds <= 0) return '00s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes <= 0) {
      return '${secs.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }
  Widget _heroBadge({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: Colors.white70),
          Gap(6.w),
          Text(
            label,
            style: TextStyles.font12White500Weight.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamBadge({
    required String label,
    required Color color,
    required Alignment alignment,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyles.font12White600Weight,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return 'Moments';
    final d = Duration(seconds: seconds);
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  Widget _winnerBanner(LiveMatch match) {
    final winner = match.winnerTeamId == match.teamA.id
        ? match.teamA.name
        : match.teamB.name;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: ColorsManager.primary.withOpacity(0.12),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          Gap(10.w),
          Expanded(
            child: Text(
              '$winner win the match!',
              style: TextStyles.font14White600Weight.copyWith(
                color: ColorsManager.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePlayersSection(LiveMatch match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Player stats board'),
        Gap(12.h),
        _playerStatsMatrix(match),
      ],
    );
  }

  Widget _playerStatsMatrix(LiveMatch match) {
    final leftPlayers = match.teamA.players;
    final rightPlayers = match.teamB.players;
    final rowCount = math.max(leftPlayers.length, rightPlayers.length);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 26),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
        children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF181638),
                    Color(0xFF0B0A1F),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -30,
              left: -10,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorsManager.primary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -40,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ColorsManager.mainBlue.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
            ),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
              child: Column(
                children: [
                  Row(
              children: [
                Expanded(
                        child: _teamBadge(
                          label: match.teamA.name,
                          color: ColorsManager.primary,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      Gap(12.w),
                Expanded(
                        child: _teamBadge(
                          label: match.teamB.name,
                          color: ColorsManager.mainBlue,
                          alignment: Alignment.centerRight,
          ),
                ),
              ],
            ),
                  Gap(16.h),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          if (rowCount == 0)
            Padding(
                      padding: EdgeInsets.all(24.w),
              child: Text(
                'Player stats will appear here once added.',
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white70,
                        ),
              ),
            )
          else
                    ...List.generate(rowCount, (index) {
                      return _playerStatsMatrixRow(
                        left: index < leftPlayers.length
                            ? leftPlayers[index]
                            : null,
                        right: index < rightPlayers.length
                            ? rightPlayers[index]
                            : null,
                        isStriped: index.isOdd,
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerStatsMatrixRow({
    LivePlayer? left,
    LivePlayer? right,
    required bool isStriped,
  }) {
    final stripeColor =
        isStriped ? Colors.white.withOpacity(0.02) : Colors.transparent;
    return Container(
      decoration: BoxDecoration(
        color: stripeColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      margin: EdgeInsets.only(bottom: 8.h, top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _playerStatsCell(left)),
          Container(
                width: 1,
            height: 70.h,
            margin: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.0),
                ],
                  ),
                ),
              ),
              Expanded(child: _playerStatsCell(right, alignEnd: true)),
            ],
          ),
    );
  }

  Widget _playerStatsCell(
    LivePlayer? player, {
    bool alignEnd = false,
  }) {
    if (player == null) {
      return const SizedBox.shrink();
    }

    final statsEntries = player.stats.entries.toList();

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16.r,
              backgroundColor: Colors.white.withOpacity(0.08),
              backgroundImage: player.avatarUrl != null
                  ? NetworkImage(player.avatarUrl!)
                  : null,
                    child: player.avatarUrl == null
                        ? Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  Gap(8.w),
                  Expanded(
              child: Text(
                          player.name,
                          style: TextStyles.font12White600Weight,
                          overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                              ),
                            ),
                          ],
                        ),
        Gap(8.h),
        if (statsEntries.isEmpty)
          Text(
            'No metrics yet',
            style: TextStyles.font11Grey400Weight,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: statsEntries
                .map(
                  (entry) => _statPill(
                    _formatStatKey(entry.key),
                    entry.value,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _statPill(String label, dynamic value) {
    final displayValue = value is num
        ? value.toStringAsFixed(value % 1 == 0 ? 0 : 1)
        : value?.toString() ?? '';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        '$label: $displayValue',
        style: TextStyles.font10White500Weight,
      ),
    );
  }

  String _formatStatKey(String raw) {
    if (raw.isEmpty) return raw;
    final spaced = raw.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  Widget _buildEngagementSection(LiveMatch match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Match engagement'),
        Gap(12.h),
        _buildCommentaryCard(match),
        Gap(16.h),
        _buildReactionsCard(match),
        Gap(16.h),
        _buildQuickReplyEmojis(),
        Gap(12.h),
        _buildCommentInputRow(),
      ],
    );
  }

  Widget _buildCommentaryCard(LiveMatch match) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1845).withOpacity(0.95),
            const Color(0xFF0D0B24).withOpacity(0.95),
          ],
        ),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: _commentaryList(match),
    );
  }

  Widget _commentaryList(LiveMatch match) {
    final realCommentary = match.commentary.reversed.toList();
    final listHeight = 320.h;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_commentaryScrollController.hasClients && realCommentary.isNotEmpty) {
        _commentaryScrollController.jumpTo(
          _commentaryScrollController.position.maxScrollExtent,
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
        Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorsManager.primary.withOpacity(0.3),
                    ColorsManager.mainBlue.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: ColorsManager.primary.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    size: 16.sp,
                    color: ColorsManager.primary,
                  ),
                  Gap(6.w),
                  Text(
                    'COMMENTARY',
                    style: TextStyles.font12White600Weight.copyWith(
                      color: ColorsManager.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${realCommentary.length} updates',
                style: TextStyles.font11Grey400Weight.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        Gap(16.h),
        Container(
          height: listHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: realCommentary.isEmpty
              ? Center(
          child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
            children: [
                      Icon(
                        Icons.mic_none_rounded,
                        size: 48.sp,
                        color: Colors.white.withOpacity(0.3),
                      ),
                        Gap(12.h),
                      Text(
                        match.isLive
                            ? 'Official commentary will appear here'
                            : 'No commentary available',
                        style: TextStyles.font12Grey400Weight.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  controller: _commentaryScrollController,
                  child: ListView.builder(
                    controller: _commentaryScrollController,
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                    itemCount: realCommentary.length,
                    itemBuilder: (context, index) {
                      final entry = realCommentary[index];
                      final isNew = index == realCommentary.length - 1;
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: isNew
                              ? LinearGradient(
                                  colors: [
                                    ColorsManager.primary.withOpacity(0.12),
                                    ColorsManager.primary.withOpacity(0.05),
                                  ],
                                )
                              : null,
                          color: isNew ? null : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(14.r),
                          border: isNew
                              ? Border.all(
                                  color: ColorsManager.primary.withOpacity(0.3),
                                  width: 1.5,
                                )
                              : Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                        ),
                        child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    ColorsManager.primary.withOpacity(0.25),
                                    ColorsManager.mainBlue.withOpacity(0.25),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: ColorsManager.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                entry.minute != null
                                    ? '${entry.minute}′'
                                    : DateFormat.Hm().format(entry.timestamp),
                                style:
                                    TextStyles.font11Grey400Weight.copyWith(
                                  color: ColorsManager.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Gap(14.w),
                      Expanded(
                              child: Text(
                                entry.text,
                                style:
                                    TextStyles.font13White500Weight.copyWith(
                                  height: 1.5,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                        ),
                      ),
                    ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReactionsCard(LiveMatch match) {
    final displayReactions = _displayReactions;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF451845).withOpacity(0.4),
            const Color(0xFF240D24).withOpacity(0.4),
          ],
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.3),
                      Colors.orange.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16.sp,
                      color: Colors.amber,
                    ),
                    Gap(6.w),
                    Text(
                      'LIVE REACTIONS',
                      style: TextStyles.font12White600Weight.copyWith(
                        color: Colors.amber,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${_displayReactions.length} reactions',
                  style: TextStyles.font11Grey400Weight.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.black.withOpacity(0.25),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: displayReactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 48.sp,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        Gap(12.h),
                        Text(
                          'Fan reactions will appear here',
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    controller: _reactionsScrollController,
                    child: ListView.builder(
                      controller: _reactionsScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                      itemCount: displayReactions.length,
                      itemBuilder: (context, index) {
                        final reaction = displayReactions[index];
                        final isRecent = index < 3;
                        final isTextBased = reaction.reactionType != 'emoji' &&
                            (reaction.text?.isNotEmpty ?? false);
                        final emojiToShow = reaction.emoji ??
                            (reaction.reactionType == 'emoji' ? '👏' : '💬');
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18.r),
                                    gradient: isRecent
                                        ? LinearGradient(
                                            colors: [
                                              Colors.amber.withOpacity(0.2),
                                              Colors.orange.withOpacity(0.2),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.08),
                                              Colors.white.withOpacity(0.03),
                                            ],
                                          ),
                                    border: Border.all(
                                      color: isRecent
                                          ? Colors.amber.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.15),
                                      width: isRecent ? 2 : 1,
                                    ),
                                    boxShadow: isRecent
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.amber.withOpacity(0.3),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isTextBased)
                                        Text(
                                          emojiToShow,
                                          style: TextStyle(
                                            fontSize: isRecent ? 22.sp : 20.sp,
                                          ),
                                        )
                                      else ...[
                                        Text(
                                          emojiToShow,
                                          style: TextStyle(fontSize: 18.sp),
                                        ),
                                        Gap(6.w),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: 140.w,
                                          ),
                                          child: Text(
                                            reaction.text ?? '',
                                            style: TextStyles
                                                .font12White600Weight
                                                .copyWith(
                                              fontSize:
                                                  isRecent ? 13.sp : 12.sp,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyEmojis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick reactions & replies',
          style: TextStyles.font12White600Weight.copyWith(
            color: Colors.white70,
          ),
        ),
        Gap(10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Quick reactions (emojis)
              ..._quickReplyEmojis
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: GestureDetector(
                        onTap: () => _handleReactionTap(item['emoji']!),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
          Text(
                                item['emoji']!,
                                style: TextStyle(fontSize: 22.sp),
                              ),
                              Gap(8.w),
                              Text(
                                item['label']!,
                                style: TextStyles.font12White600Weight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              // Quick replies (text with emojis)
              ..._quickReplies
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: GestureDetector(
                        onTap: () => _handleQuickReply(item['text']!, item['emoji']!),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            gradient: LinearGradient(
                              colors: [
                                ColorsManager.primary.withOpacity(0.2),
                                ColorsManager.mainBlue.withOpacity(0.15),
                              ],
                            ),
                            border: Border.all(
                              color: ColorsManager.primary.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                  child: Row(
                            mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                                item['emoji']!,
                                style: TextStyle(fontSize: 18.sp),
                      ),
                      Gap(8.w),
                              Text(
                                item['text']!,
                                style: TextStyles.font12White600Weight.copyWith(
                                  color: ColorsManager.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInputRow() {
    return Row(
      children: [
                      Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.3),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                      ),
                    ],
                  ),
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              style: TextStyles.font13White500Weight,
              decoration: InputDecoration(
                hintText: 'Type a comment…',
                hintStyle: TextStyles.font12Grey400Weight.copyWith(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleFanMessage,
            ),
          ),
        ),
        Gap(12.w),
        GestureDetector(
          onTap: () => _handleFanMessage(_commentController.text),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  ColorsManager.primary,
                  ColorsManager.mainBlue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorsManager.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.send_rounded,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
              ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorsManager.primary.withOpacity(0.2),
                ColorsManager.mainBlue.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ColorsManager.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
          title,
            style: TextStyles.font14White600Weight.copyWith(
              letterSpacing: 0.5,
            ),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Container(
          height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white24,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminControlPanel(LiveMatch match) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: ColorsManager.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin quick actions',
            style: TextStyles.font14White600Weight,
          ),
          Gap(12.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _adminActionChip(
                icon: Icons.sports_score,
                label: 'Update live score',
                onTap: () {},
              ),
              _adminActionChip(
                icon: Icons.mic_none,
                label: 'Add commentary',
                onTap: () {},
              ),
              _adminActionChip(
                icon: Icons.bar_chart,
                label: 'Update stats',
                onTap: () {},
              ),
              _adminActionChip(
                icon: Icons.emoji_events,
                label: 'Declare winner',
                onTap: match.isCompleted ? null : () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminActionChip({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: onTap == null
              ? Colors.white12
              : ColorsManager.primary.withOpacity(0.2),
          border: Border.all(
            color: onTap == null
                ? Colors.white12
                : ColorsManager.primary.withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            Gap(8.h),
            Text(
              label,
              style: TextStyles.font12White600Weight,
            ),
          ],
        ),
      ),
    );
  }

  void _handleFanMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _commentController.clear();
    _commentFocusNode.requestFocus();
    _submitReaction(
      emoji: '💬',
      text: trimmed,
      reactionType: 'text',
    );
  }

  void _handleReactionTap(String emoji) {
    _submitReaction(
      emoji: emoji,
      reactionType: 'emoji',
    );
  }

  void _handleQuickReply(String text, String emoji) {
    _submitReaction(
      emoji: emoji,
      text: text,
      reactionType: 'quick_reply',
    );
  }

  bool _areReactionsEquivalent(LiveReaction a, LiveReaction b) {
    if (a.reactionType != b.reactionType) return false;
    if (a.userId != b.userId) return false;
    if ((a.emoji ?? '') != (b.emoji ?? '')) return false;
    if ((a.text?.trim() ?? '') != (b.text?.trim() ?? '')) return false;
    final difference = (a.timestamp.millisecondsSinceEpoch - b.timestamp.millisecondsSinceEpoch).abs();
    return difference < 4000;
  }

  void _showAdminQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AdminQuickActionsSheet(
          onCreateMatch: _openCreateMatchFlow,
          onRemoveMatch: _openRemoveMatchFlow,
        );
      },
    );
  }

  Future<void> _openCreateMatchFlow() async {
    Navigator.of(context).pop();
  }

  Future<void> _openRemoveMatchFlow() async {
    Navigator.of(context).pop();
  }
}
 
class _AdminQuickActionsSheet extends StatelessWidget {
  const _AdminQuickActionsSheet({
    required this.onCreateMatch,
    required this.onRemoveMatch,
  });

  final VoidCallback onCreateMatch;
  final VoidCallback onRemoveMatch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.schedule_outlined, color: Colors.redAccent),
              title: const Text('Remove scheduled matches'),
              subtitle: const Text('Cancel upcoming fixtures'),
              onTap: onRemoveMatch,
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.add_circle_outline,
                  color: ColorsManager.primary),
              title: const Text('Create new match'),
              subtitle: const Text('Select teams, players & kickoff time'),
              onTap: onCreateMatch,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatefulWidget {
  const _CountdownBadge({
    required this.direction,
    required this.initialSeconds,
    required this.savedAt,
    required this.formatter,
  });

  final String direction;
  final int initialSeconds;
  final DateTime savedAt;
  final String Function(int seconds) formatter;

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.savedAt).inSeconds;
    final currentSeconds = widget.direction == 'down'
        ? math.max(0, widget.initialSeconds - elapsed)
        : widget.initialSeconds + elapsed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.direction == 'down' ? Icons.south : Icons.north,
          size: 14.sp,
          color: Colors.white,
        ),
        Gap(4.w),
        Text(
          widget.formatter(currentSeconds),
          style: TextStyles.font12White500Weight,
        ),
      ],
    );
  }
}