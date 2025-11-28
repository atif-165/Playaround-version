import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_text_button.dart';
import '../../core/widgets/progress_indicator.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theming/colors.dart';
import '../../theming/public_profile_theme.dart';
import '../../theming/styles.dart';
import '../../config/app_route_paths.dart';
import '../../modules/coach/services/coach_associations_service.dart';
import '../../modules/tournament/services/tournament_service.dart';
import '../dashboard/services/user_profile_dashboard_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _notificationHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

/// Screen displaying user notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final CoachAssociationsService _coachAssociationsService = CoachAssociationsService();
  final PublicProfileService _publicProfileService = PublicProfileService();
  final TournamentService _tournamentService = TournamentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initializedListener = false;

  @override
  void initState() {
    super.initState();
    _ensureRealtimeListener();
  }

  Future<void> _ensureRealtimeListener() async {
    if (_initializedListener) return;
    try {
      await _notificationService.startRealtimeListener();
      setState(() {
        _initializedListener = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start notification listener: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 40.h,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _notificationHeroGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyles.font18White600Weight,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(
                      'Mark All Read',
                      style: TextStyles.font14MainBlue500Weight
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Gap(20.h),
                Expanded(
                  child: StreamBuilder<List<NotificationModel>>(
                    stream: _notificationService.getUserNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CustomProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _buildStateMessage(
                          icon: Icons.error_outline,
                          title: 'Error loading notifications',
                          message: snapshot.error.toString(),
                        );
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return _buildStateMessage(
                          icon: Icons.notifications_none_outlined,
                          title: 'No notifications yet',
                          message:
                              'You\'ll see notifications here when you have updates.',
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 24.h),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: Colors.white30),
            Gap(16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
            ),
            Gap(8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.font14Grey400Weight
                  .copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final cardColor = notification.isRead
        ? PublicProfileTheme.panelColor.withOpacity(0.92)
        : PublicProfileTheme.panelOverlayColor.withOpacity(0.96);
    final borderColor = notification.isRead
        ? Colors.white.withOpacity(0.04)
        : ColorsManager.mainBlue.withOpacity(0.35);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 18.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
          onTap: () {
          // Don't navigate for coach player requests, association requests, or tournament approval - they have action buttons
          if (notification.type == NotificationType.coachPlayerRequest || 
              _isAssociationRequest(notification) ||
              notification.type == NotificationType.tournamentApproval) {
            return;
          }
          _onNotificationTap(notification);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type)
                      .withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 22.sp,
                ),
              ),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyles.font16DarkBlueBold
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyles.font12Grey400Weight
                              .copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                    Gap(6.h),
                    Text(
                      notification.message,
                      style: TextStyles.font14Grey400Weight
                          .copyWith(color: Colors.white70, height: 1.4),
                    ),
                    // Show approve/deny buttons for coach player requests
                    if (notification.type == NotificationType.coachPlayerRequest &&
                        notification.data != null) ...[
                      Gap(12.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Approve',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleApproveCoachRequest(notification),
                              backgroundColor: ColorsManager.success,
                              buttonHeight: 38,
                            ),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Deny',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleDenyCoachRequest(notification),
                              backgroundColor: ColorsManager.error,
                              buttonHeight: 38,
                            ),
                          ),
                        ],
                      ),
                    ] 
                    // Show approve/deny buttons for tournament approval requests
                    else if (notification.type == NotificationType.tournamentApproval &&
                        notification.data != null &&
                        notification.data!['tournamentId'] != null) ...[
                      Gap(12.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Accept',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleApproveTournamentRequest(notification),
                              backgroundColor: ColorsManager.success,
                              buttonHeight: 38,
                            ),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Deny',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleDenyTournamentRequest(notification),
                              backgroundColor: ColorsManager.error,
                              buttonHeight: 38,
                            ),
                          ),
                        ],
                      ),
                    ]
                    // Show approve/deny buttons for association requests (team, tournament, venue, coach)
                    else if (_isAssociationRequest(notification)) ...[
                      Gap(12.h),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Approve',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleApproveAssociationRequest(notification),
                              backgroundColor: ColorsManager.success,
                              buttonHeight: 38,
                            ),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: AppTextButton(
                              buttonText: 'Deny',
                              textStyle: TextStyles.font14White600Weight,
                              onPressed: () => _handleDenyAssociationRequest(notification),
                              backgroundColor: ColorsManager.error,
                              buttonHeight: 38,
                            ),
                          ),
                        ],
                      ),
                    ] 
                    else if (notification.data != null &&
                        notification.data!['action'] != null) ...[
                      Gap(12.h),
                      AppTextButton(
                        buttonText: 'View Details',
                        textStyle: TextStyles.font14White600Weight,
                        onPressed: () => _handleNotificationAction(notification),
                        backgroundColor: ColorsManager.mainBlue,
                        buttonHeight: 38,
                      ),
                    ],
                    Gap(2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.venueBooking:
        return Icons.location_city;
      case NotificationType.tournamentRegistration:
        return Icons.emoji_events;
      case NotificationType.tournamentApproval:
        return Icons.check_circle;
      case NotificationType.tournamentRejection:
        return Icons.cancel;
      case NotificationType.tournamentRemoval:
        return Icons.remove_circle;
      case NotificationType.tournamentTeamUpdate:
        return Icons.update;
      case NotificationType.matchScheduled:
        return Icons.schedule;
      case NotificationType.scoreUpdate:
        return Icons.scoreboard;
      case NotificationType.tournamentComplete:
        return Icons.emoji_events;
      case NotificationType.tournamentUpdate:
        return Icons.update;
      case NotificationType.teamInvite:
        return Icons.group_add;
      case NotificationType.ratingReceived:
        return Icons.star;
      case NotificationType.ratingRequest:
        return Icons.rate_review;
      case NotificationType.profileLike:
        return Icons.favorite;
      case NotificationType.profileComment:
        return Icons.comment;
      case NotificationType.profileFollow:
        return Icons.person_add_alt_1;
      case NotificationType.profileUpdate:
        return Icons.campaign_outlined;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.newPost:
        return Icons.article;
      case NotificationType.userMatch:
        return Icons.people;
      case NotificationType.coachVenueRequest:
        return Icons.apartment;
      case NotificationType.coachTeamRequest:
        return Icons.groups;
      case NotificationType.coachPlayerRequest:
        return Icons.person_add_alt_1;
      case NotificationType.sessionCreated:
        return Icons.event_available;
      case NotificationType.sessionUpdated:
        return Icons.edit_calendar;
      case NotificationType.sessionCancelled:
        return Icons.event_busy;
      case NotificationType.bookingUpdate:
        return Icons.calendar_month_outlined;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.venueBooking:
        return ColorsManager.success;
      case NotificationType.tournamentRegistration:
        return ColorsManager.secondary;
      case NotificationType.tournamentApproval:
        return ColorsManager.success;
      case NotificationType.tournamentRejection:
        return ColorsManager.error;
      case NotificationType.tournamentRemoval:
        return ColorsManager.error;
      case NotificationType.tournamentTeamUpdate:
        return ColorsManager.primary;
      case NotificationType.matchScheduled:
        return ColorsManager.secondary;
      case NotificationType.scoreUpdate:
        return ColorsManager.warning;
      case NotificationType.tournamentComplete:
        return ColorsManager.success;
      case NotificationType.tournamentUpdate:
        return ColorsManager.primary;
      case NotificationType.teamInvite:
        return ColorsManager.primary;
      case NotificationType.ratingReceived:
        return ColorsManager.warning;
      case NotificationType.ratingRequest:
        return ColorsManager.tertiary;
      case NotificationType.profileLike:
        return Colors.pink;
      case NotificationType.profileComment:
        return Colors.blue;
      case NotificationType.profileFollow:
        return ColorsManager.primary;
      case NotificationType.profileUpdate:
        return ColorsManager.secondary;
      case NotificationType.newMessage:
        return ColorsManager.mainBlue;
      case NotificationType.newPost:
        return ColorsManager.primary;
      case NotificationType.userMatch:
        return Colors.green;
      case NotificationType.coachVenueRequest:
        return ColorsManager.coachAccent;
      case NotificationType.coachTeamRequest:
        return ColorsManager.primary;
      case NotificationType.coachPlayerRequest:
        return ColorsManager.success;
      case NotificationType.sessionCreated:
        return ColorsManager.secondary;
      case NotificationType.sessionUpdated:
        return ColorsManager.primary;
      case NotificationType.sessionCancelled:
        return ColorsManager.error;
      case NotificationType.bookingUpdate:
        return ColorsManager.coachAccent;
      case NotificationType.general:
        return ColorsManager.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      // final data = notification.data!;

      switch (notification.type) {
        case NotificationType.venueBooking:
          // Navigate to venue bookings or venue detail
          // TODO: Implement navigation to venue detail
          break;
        case NotificationType.tournamentRegistration:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentApproval:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentRejection:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentRemoval:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentTeamUpdate:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.matchScheduled:
          // Navigate to match detail
          // TODO: Implement navigation to match detail
          break;
        case NotificationType.scoreUpdate:
          // Navigate to match detail
          // TODO: Implement navigation to match detail
          break;
        case NotificationType.tournamentComplete:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentUpdate:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.teamInvite:
          // Navigate to team detail or team invites
          // TODO: Implement navigation to team detail
          break;
        case NotificationType.ratingReceived:
          // Navigate to ratings screen
          // TODO: Implement navigation to ratings detail
          break;
        case NotificationType.ratingRequest:
          // Navigate to pending ratings
          // TODO: Implement navigation to pending ratings
          break;
        case NotificationType.profileLike:
          // Navigate to people search or profile
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.profileComment:
          // Navigate to profile or comments
          Navigator.pushNamed(context, '/profileScreen');
          break;
        case NotificationType.profileFollow:
          // Navigate to follower's profile
          final followerId = notification.data?['followerId'] as String?;
          if (followerId != null) {
            context.push('/dashboard/$followerId');
          } else {
            Navigator.pushNamed(context, '/peopleSearchScreen');
          }
          break;
        case NotificationType.profileUpdate:
          final profileUserId = notification.data?['profileUserId'] as String?;
          if (profileUserId != null) {
            context.push('/dashboard/$profileUserId');
          } else {
            Navigator.pushNamed(context, '/profileScreen');
          }
          break;
        case NotificationType.newMessage:
          // Navigate to chat
          final chatId = notification.data?['chatId'] as String?;
          if (chatId != null) {
            context.push('/chat/$chatId');
          }
          break;
        case NotificationType.newPost:
          // Navigate to post
          final postId = notification.data?['postId'] as String?;
          if (postId != null) {
            context.push('/community/post/$postId');
          }
          break;
        case NotificationType.userMatch:
          // Navigate to matches or chat
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.coachVenueRequest:
          // Navigate to venue management or requests
          // TODO: Implement navigation for coach venue requests
          break;
        case NotificationType.coachTeamRequest:
          // Navigate to team requests management
          // TODO: Implement navigation for coach team requests
          break;
        case NotificationType.coachPlayerRequest:
          // Navigate to player management or approvals
          // TODO: Implement navigation for coach player requests
          break;
        case NotificationType.sessionCreated:
          // Navigate to schedule
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.sessionUpdated:
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.sessionCancelled:
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.bookingUpdate:
          // Navigate to booking detail screen if available
          // TODO: Implement navigation to booking detail
          break;
        case NotificationType.general:
          // Handle general notifications
          // TODO: Implement general notification handling
          break;
      }
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    final data = notification.data;
    if (data == null) {
      _onNotificationTap(notification);
      return;
    }

    final action = data['action'] as String?;
    if (action == null) {
      _onNotificationTap(notification);
      return;
    }

    switch (action) {
      case 'navigate':
      case 'navigate_to_route':
      case 'open_route':
      case 'route':
        final routeName = data['routeName'] as String?;
        final routePath =
            data['route'] as String? ?? data['path'] as String?;
        final extra = data['extra'];

        if (routeName != null) {
          context.pushNamed(routeName, extra: extra);
        } else if (routePath != null) {
          context.push(routePath, extra: extra);
        } else {
          _onNotificationTap(notification);
        }
        break;
      case 'open_profile':
        context.pushNamed(
          AppRouteNames.profile,
          extra: data['userId'],
        );
        break;
      default:
        _onNotificationTap(notification);
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveCoachRequest(NotificationModel notification) async {
    if (notification.data == null) return;

    final coachId = notification.data!['coachId'] as String?;
    final playerId = notification.data!['playerId'] as String?;
    final playerName = notification.data!['playerName'] as String? ?? 'Player';

    if (coachId == null || playerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid request data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final success = await _coachAssociationsService.approvePlayerAssociation(
        coachId,
        playerId,
        playerName,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          // Mark notification as read and delete it
          await _notificationService.markAsRead(notification.id);
          await _notificationService.deleteNotification(notification.id);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request approved! You have been added to ${notification.data!['coachName'] ?? 'the coach'}\'s profile.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve request. It may have already been processed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDenyCoachRequest(NotificationModel notification) async {
    if (notification.data == null) return;

    final coachId = notification.data!['coachId'] as String?;
    final playerId = notification.data!['playerId'] as String?;
    final playerName = notification.data!['playerName'] as String? ?? 'Player';

    if (coachId == null || playerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid request data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Reject Request?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to reject ${notification.data!['coachName'] ?? 'the coach'}\'s request to add you to their coaching profile?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      final success = await _coachAssociationsService.rejectPlayerAssociation(
        coachId,
        playerId,
        playerName,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          // Mark notification as read and delete it
          await _notificationService.markAsRead(notification.id);
          await _notificationService.deleteNotification(notification.id);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject request. It may have already been processed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isAssociationRequest(NotificationModel notification) {
    if (notification.data == null) return false;
    final data = notification.data!;
    
    // Check if this is an association request notification
    return (notification.type == NotificationType.teamInvite ||
            notification.type == NotificationType.tournamentRegistration ||
            notification.type == NotificationType.venueBooking ||
            notification.type == NotificationType.general) &&
           data.containsKey('associationType') &&
           data.containsKey('associationId') &&
           data.containsKey('requesterId');
  }

  Future<void> _handleApproveAssociationRequest(NotificationModel notification) async {
    if (notification.data == null) return;

    final data = notification.data!;
    final requesterId = data['requesterId'] as String?;
    final associationId = data['associationId'] as String?;
    final associationTitle = data['associationTitle'] as String? ?? 'item';
    final associationType = data['associationType'] as String?;

    if (requesterId == null || associationId == null || associationType == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid request data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Find the request document
    try {
      final firestore = FirebaseFirestore.instance;
      final requestsSnapshot = await firestore
          .collection('profile_association_requests')
          .where('requesterId', isEqualTo: requesterId)
          .where('associationId', isEqualTo: associationId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (requestsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request not found or already processed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final requestDoc = requestsSnapshot.docs.first;
      final requestId = requestDoc.id;

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      try {
        await _publicProfileService.approveAssociationRequest(
          requestId: requestId,
          requesterId: requesterId,
          associationId: associationId,
          type: associationType,
          associationTitle: associationTitle,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Mark notification as read and delete it
          await _notificationService.markAsRead(notification.id);
          await _notificationService.deleteNotification(notification.id);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request approved! $associationTitle will appear on the requester\'s profile.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error approving request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to find request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDenyAssociationRequest(NotificationModel notification) async {
    if (notification.data == null) return;

    final data = notification.data!;
    final requesterId = data['requesterId'] as String?;
    final associationId = data['associationId'] as String?;
    final associationTitle = data['associationTitle'] as String? ?? 'item';

    if (requesterId == null || associationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid request data'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Reject Request?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to reject the request to add $associationTitle to the requester\'s profile?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Find the request document
    try {
      final firestore = FirebaseFirestore.instance;
      final requestsSnapshot = await firestore
          .collection('profile_association_requests')
          .where('requesterId', isEqualTo: requesterId)
          .where('associationId', isEqualTo: associationId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (requestsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request not found or already processed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final requestDoc = requestsSnapshot.docs.first;
      final requestId = requestDoc.id;

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      try {
        await _publicProfileService.rejectAssociationRequest(
          requestId: requestId,
          requesterId: requesterId,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Mark notification as read and delete it
          await _notificationService.markAsRead(notification.id);
          await _notificationService.deleteNotification(notification.id);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to find request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveTournamentRequest(NotificationModel notification) async {
    if (notification.data == null) return;
    if (!mounted) return;

    final tournamentId = notification.data!['tournamentId'] as String?;
    final venueTitle = notification.data!['venueTitle'] as String? ?? 'the venue';

    if (tournamentId == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Invalid notification data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store navigator and messenger before async operations
    final navigator = Navigator.of(context, rootNavigator: false);
    final messenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _tournamentService.respondToVenueApproval(
        tournamentId: tournamentId,
        ownerId: user.uid,
        approve: true,
      );

      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      // Mark notification as read and delete it
      await _notificationService.markAsRead(notification.id);
      await _notificationService.deleteNotification(notification.id);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournament approved! It will now be visible to players.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error approving tournament: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDenyTournamentRequest(NotificationModel notification) async {
    if (notification.data == null) return;
    if (!mounted) return;

    final tournamentId = notification.data!['tournamentId'] as String?;
    final venueTitle = notification.data!['venueTitle'] as String? ?? 'the venue';

    if (tournamentId == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Invalid notification data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store navigator and messenger before async operations
    final navigator = Navigator.of(context, rootNavigator: false);
    final messenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: PublicProfileTheme.panelColor,
        title: const Text(
          'Reject Tournament Request?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to reject the tournament request for $venueTitle?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _tournamentService.respondToVenueApproval(
        tournamentId: tournamentId,
        ownerId: user.uid,
        approve: false,
      );

      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }

      // Mark notification as read and delete it
      await _notificationService.markAsRead(notification.id);
      await _notificationService.deleteNotification(notification.id);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournament request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop(); // Close loading dialog
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error rejecting tournament: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

