import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../theming/colors.dart';
import '../../../models/geo_models.dart';

/// Card widget for displaying match request information
class MatchRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isReceived;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const MatchRequestCard({
    super.key,
    required this.request,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<MatchRequestCard> createState() => _MatchRequestCardState();
}

class _MatchRequestCardState extends State<MatchRequestCard> {
  GeoPlayer? _playerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerProfile();
  }

  Future<void> _loadPlayerProfile() async {
    try {
      final playerId = widget.isReceived
          ? widget.request['fromPlayerId']
          : widget.request['toPlayerId'];

      final playerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();

      if (playerDoc.exists && mounted) {
        setState(() {
          _playerProfile = GeoPlayer.fromFirestore(playerDoc);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_playerProfile == null) {
      return Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const Center(
          child: Text('Failed to load player profile'),
        ),
      );
    }

    final status = widget.request['status'] as String;
    final createdAt = widget.request['createdAt'] as Timestamp?;
    final matchScore =
        (widget.request['matchScore'] as num?)?.toDouble() ?? 0.0;
    final commonSports =
        List<String>.from(widget.request['commonSports'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header with player info and status
            Row(
              children: [
                // Profile picture
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStatusColor(status).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _playerProfile!.profilePictureUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _playerProfile!.profilePictureUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 24.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 24.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 24.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),

                Gap(12.w),

                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _playerProfile!.fullName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Gap(2.h),
                      Text(
                        widget.isReceived
                            ? 'wants to team up with you'
                            : 'match request sent',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(createdAt.toDate()),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),

            Gap(12.h),

            // Match details
            Row(
              children: [
                // Match score
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${matchScore.round()}% Match',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: ColorsManager.mainBlue,
                    ),
                  ),
                ),

                Gap(8.w),

                // Common sports
                if (commonSports.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4.w,
                      children: commonSports.take(2).map((sport) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            sport,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.green[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),

            // Action buttons for received requests
            if (widget.isReceived && status == 'pending') ...[
              Gap(12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  Gap(8.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primary,
                        foregroundColor: ColorsManager.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }
}
