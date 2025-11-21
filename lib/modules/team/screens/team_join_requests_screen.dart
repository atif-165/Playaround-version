import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import '../widgets/join_request_card.dart';

class TeamJoinRequestsScreen extends StatefulWidget {
  final TeamModel team;

  const TeamJoinRequestsScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamJoinRequestsScreen> createState() => _TeamJoinRequestsScreenState();
}

class _TeamJoinRequestsScreenState extends State<TeamJoinRequestsScreen> {
  final TeamService _teamService = TeamService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Join Requests',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<TeamJoinRequest>>(
        stream: _teamService.getTeamJoinRequests(widget.team.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ColorsManager.mainBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                  Gap(16.h),
                  Text(
                    'Error loading requests',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  ),
                  Gap(8.h),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64.sp,
                    color: Colors.grey[600],
                  ),
                  Gap(16.h),
                  Text(
                    'No pending requests',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16.sp,
                    ),
                  ),
                  Gap(8.h),
                  Text(
                    'When players or coaches request to join your team,\nthey will appear here.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: requests.length,
            separatorBuilder: (context, index) => Gap(12.h),
            itemBuilder: (context, index) {
              final request = requests[index];
              return JoinRequestCard(
                request: request,
                onApprove: () => _approveRequest(request.id),
                onReject: () => _rejectRequest(request.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await _teamService.approveJoinRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    // Show rejection reason dialog
    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Reject Request',
          style:
              TextStyles.font18DarkBlue600Weight.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason (Optional)',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            Gap(8.h),
            TextField(
              controller: reasonController,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why are you rejecting this request?',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (shouldReject == true) {
      try {
        await _teamService.rejectJoinRequest(
          requestId,
          responseMessage: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
