import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/public_profile_theme.dart';
import '../../../theming/styles.dart';
import '../models/team_profile_models.dart';
import '../../../core/navigation/detail_navigator.dart';

class TeamHistoryDetailScreen extends StatelessWidget {
  const TeamHistoryDetailScreen({
    super.key,
    required this.entry,
  });

  final TeamHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMMM d, yyyy').format(entry.date);

    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Venue History',
          style: TextStyles.font16White600Weight,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              context,
              title: entry.venue,
              subtitle: entry.location,
              children: [
                _buildDetailRow('Date', dateLabel),
                _buildDetailRow('Match Type', entry.matchType),
                _buildDetailRow('Opponent', entry.opponent),
                _buildDetailRow('Result', entry.result),
              ],
            ),
            if (entry.summary.trim().isNotEmpty) ...[
              Gap(16.h),
              _buildSectionCard(
                context,
                title: 'Match Summary',
                children: [
                  Text(
                    entry.summary,
                    style: TextStyles.font13White500Weight
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
            if (entry.matchId != null && entry.matchId!.isNotEmpty) ...[
              Gap(24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMatchDetail(context, entry.matchId!),
                  icon: const Icon(Icons.sports),
                  label: const Text('View match details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PublicProfileTheme.panelAccentColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
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

  void _openMatchDetail(BuildContext context, String matchId) {
    DetailNavigator.openMatch(
      context,
      matchId: matchId,
    );
  }
}


