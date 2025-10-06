import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_model.dart';
import '../widgets/tournament_card.dart';

/// Screen for previewing tournament before creation
class TournamentPreviewScreen extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onConfirm;

  const TournamentPreviewScreen({
    super.key,
    required this.tournament,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tournament Preview',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.mainBlue),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Edit',
              style: TextStyles.font14MainBlue500Weight,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Gap(24.h),
            _buildTournamentCard(),
            Gap(24.h),
            _buildDetailsSection(),
            Gap(24.h),
            _buildRulesSection(),
            Gap(24.h),
            _buildQuestionsSection(),
            Gap(32.h),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Your Tournament',
          style: TextStyles.font24Blue700Weight,
        ),
        Gap(8.h),
        Text(
          'This is how your tournament will appear to participants',
          style: TextStyles.font14Grey400Weight,
        ),
      ],
    );
  }

  Widget _buildTournamentCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TournamentCard(
        tournament: tournament,
        onTap: () {}, // No action in preview
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Details',
          style: TextStyles.font18DarkBlueBold,
        ),
        Gap(16.h),
        _buildDetailRow('Sport', tournament.sportType.displayName),
        _buildDetailRow('Format', tournament.format.displayName),
        _buildDetailRow('Max Teams', '${tournament.maxTeams}'),
        _buildDetailRow('Entry Fee', '\$${tournament.entryFee?.toStringAsFixed(2) ?? '0.00'}'),
        _buildDetailRow('Prize Pool', '\$${tournament.winningPrize?.toStringAsFixed(2) ?? '0.00'}'),
        _buildDetailRow('Venue', tournament.venueName ?? tournament.location ?? 'TBD'),
        _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy at HH:mm').format(tournament.startDate)),
        _buildDetailRow('Registration Deadline', DateFormat('MMM dd, yyyy').format(tournament.registrationEndDate)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyles.font14DarkBlueMedium.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyles.font14DarkBlueMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    if (tournament.rules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tournament Rules',
          style: TextStyles.font18DarkBlueBold,
        ),
        Gap(16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tournament.rules.map((rule) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyles.font14DarkBlueMedium.copyWith(
                      color: ColorsManager.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyles.font14DarkBlueMedium,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection() {
    if (tournament.qualifyingQuestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registration Questions',
          style: TextStyles.font18DarkBlueBold,
        ),
        Gap(16.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorsManager.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tournament.qualifyingQuestions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final question = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: ColorsManager.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: TextStyles.font12Grey400Weight.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyles.font14DarkBlueMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Tournament'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsManager.primary,
                  side: BorderSide(color: ColorsManager.primary),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
            Gap(16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                icon: const Icon(Icons.check),
                label: const Text('Create Tournament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
          ],
        ),
        Gap(16.h),
        Text(
          'By creating this tournament, you agree to our terms of service and tournament guidelines.',
          style: TextStyles.font12Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
