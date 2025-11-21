import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/team_profile_models.dart';
import '../../tournament/models/tournament_model.dart';
import '../../tournament/screens/tournament_detail_screen.dart';
import '../../tournament/services/tournament_service.dart';

class TeamTournamentDetailScreen extends StatefulWidget {
  const TeamTournamentDetailScreen({
    super.key,
    required this.entry,
  });

  final TeamTournamentEntry entry;

  @override
  State<TeamTournamentDetailScreen> createState() =>
      _TeamTournamentDetailScreenState();
}

class _TeamTournamentDetailScreenState
    extends State<TeamTournamentDetailScreen> {
  final TournamentService _tournamentService = TournamentService();
  bool _isOpeningTournament = false;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(widget.entry.startDate);

    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tournament Participation',
          style: TextStyles.font16White600Weight,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: widget.entry.tournamentName,
              subtitle: formattedDate,
              children: [
                _buildDetailRow('Status', widget.entry.status),
                _buildDetailRow('Stage', widget.entry.stage),
              ],
            ),
            if (widget.entry.logoUrl != null &&
                widget.entry.logoUrl!.isNotEmpty) ...[
              Gap(16.h),
              _buildImageCard(widget.entry.logoUrl!),
            ],
            Gap(24.h),
            if (widget.entry.tournamentId != null &&
                widget.entry.tournamentId!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isOpeningTournament
                      ? null
                      : () => _openTournamentDetail(
                            context,
                            widget.entry.tournamentId!,
                          ),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('View full tournament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PublicProfileTheme.panelAccentColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              )
            else
              Text(
                'Tournament link unavailable. Contact your admin if this is a mistake.',
                style: TextStyles.font12White500Weight
                    .copyWith(color: Colors.white60),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: PublicProfileTheme.glassPanelDecoration(
        borderRadius: 20.r,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.font16White600Weight,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            Gap(4.h),
            Text(
              subtitle,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white70),
            ),
          ],
          Gap(16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      height: 160.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyles.font12White500Weight
                  .copyWith(color: Colors.white60),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.font13White500Weight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTournamentDetail(
      BuildContext context, String tournamentId) async {
    setState(() {
      _isOpeningTournament = true;
    });

    try {
      final tournament =
          await _tournamentService.getTournamentById(tournamentId);
      if (!mounted) return;

      if (tournament == null) {
        _showSnackBar(context, 'Tournament not found.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TournamentDetailScreen(tournament: tournament),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(context, 'Failed to open tournament: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningTournament = false;
        });
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


