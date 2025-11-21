import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/widgets/progress_indicaror.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/tournament_registration.dart';
import '../services/tournament_service.dart';

/// Widget displaying list of teams registered for a tournament
class TournamentTeamsList extends StatefulWidget {
  final String tournamentId;

  const TournamentTeamsList({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentTeamsList> createState() => _TournamentTeamsListState();
}

class _TournamentTeamsListState extends State<TournamentTeamsList> {
  final TournamentService _tournamentService = TournamentService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentRegistration>>(
      stream:
          _tournamentService.getTournamentRegistrations(widget.tournamentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 16.sp,
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    'Failed to load registered teams',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final registrations = snapshot.data ?? [];
        final approvedRegistrations = registrations
            .where((reg) => reg.status == RegistrationStatus.approved)
            .toList();

        if (approvedRegistrations.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 16.sp,
                  color: Colors.grey[600],
                ),
                Gap(8.w),
                Text(
                  'No teams registered yet',
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          );
        }

        return Column(
          children: approvedRegistrations.map((registration) {
            return _buildTeamItem(registration);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTeamItem(TournamentRegistration registration) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                registration.teamName.isNotEmpty
                    ? registration.teamName[0].toUpperCase()
                    : 'T',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.mainBlue,
                ),
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration.teamName,
                  style: TextStyles.font14DarkBlueBold
                      .copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  'Registered by ${registration.registeredByName}',
                  style: TextStyles.font10Grey400Weight
                      .copyWith(color: Colors.grey[300]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Gap(8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Registered',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
