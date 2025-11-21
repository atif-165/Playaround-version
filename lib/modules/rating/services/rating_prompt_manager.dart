import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/rating_model.dart';
import '../../../services/rating_service.dart';
import '../widgets/rating_prompt.dart';

/// Service for managing rating prompts and notifications
class RatingPromptManager {
  static final RatingPromptManager _instance = RatingPromptManager._internal();
  factory RatingPromptManager() => _instance;
  RatingPromptManager._internal();

  final RatingService _ratingService = RatingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check for pending ratings and show prompts if necessary
  Future<void> checkAndShowPendingRatings(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get pending ratings for the current user
      final pendingRatingsStream =
          _ratingService.getPendingRatingsForUser(user.uid);

      // Listen to the first emission to get current pending ratings
      final pendingRatings = await pendingRatingsStream.first;

      if (pendingRatings.isNotEmpty && context.mounted) {
        // Show rating prompts based on the number of pending ratings
        if (pendingRatings.length == 1) {
          // Show modal for single rating
          _showSingleRatingPrompt(context, pendingRatings.first);
        } else {
          // Show full-screen prompt for multiple ratings
          _showMultipleRatingPrompts(context, pendingRatings);
        }
      }
    } catch (e) {
      // Silently handle errors - rating prompts are not critical
      debugPrint('⚠️ RatingPromptManager: Error checking pending ratings: $e');
    }
  }

  /// Show modal prompt for a single pending rating
  void _showSingleRatingPrompt(
      BuildContext context, PendingRatingModel pendingRating) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingPromptModal(
        pendingRating: pendingRating,
        onCompleted: () {
          Navigator.of(context).pop();
          _showThankYouSnackBar(context);
        },
        onSkipped: () {
          Navigator.of(context).pop();
          _showSkippedSnackBar(context);
        },
      ),
    );
  }

  /// Show full-screen prompt for multiple pending ratings
  void _showMultipleRatingPrompts(
      BuildContext context, List<PendingRatingModel> pendingRatings) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenRatingPrompt(
          pendingRatings: pendingRatings,
          onRatingCompleted: (completedRating) {
            // Handle individual rating completion
            debugPrint('✅ Rating completed for ${completedRating.entityName}');
          },
          onAllCompleted: () {
            Navigator.of(context).pop();
            _showThankYouSnackBar(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show thank you message after rating completion
  void _showThankYouSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Thank you for your feedback!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show message when rating is skipped
  void _showSkippedSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('You can rate your experience later from the Ratings tab'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Check if user has pending ratings (for badge display)
  Stream<int> getPendingRatingsCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _ratingService
        .getPendingRatingsForUser(user.uid)
        .map((pendingRatings) => pendingRatings.length);
  }

  /// Mark a pending rating as completed (for manual completion)
  Future<void> markPendingRatingCompleted(String pendingRatingId) async {
    try {
      // This would be implemented in the RatingService if needed
      // For now, ratings are automatically marked as completed when submitted
      debugPrint(
          '✅ RatingPromptManager: Marked pending rating as completed: $pendingRatingId');
    } catch (e) {
      debugPrint(
          '❌ RatingPromptManager: Error marking pending rating as completed: $e');
    }
  }

  /// Show rating prompt for a specific booking (manual trigger)
  Future<void> showRatingPromptForBooking(
    BuildContext context,
    String bookingId,
    String entityId,
    RatingType ratingType,
    String entityName,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user has already rated this booking
      final hasRated = await _ratingService.hasUserRatedBooking(
        bookingId,
        user.uid,
        entityId,
      );

      if (!context.mounted) return;

      if (hasRated) {
        _showAlreadyRatedSnackBar(context);
        return;
      }

      // Create a temporary pending rating for the prompt
      final pendingRating = PendingRatingModel(
        id: '${user.uid}_${entityId}_$bookingId',
        bookingId: bookingId,
        userId: user.uid,
        ratedEntityId: entityId,
        ratingType: ratingType,
        entityName: entityName,
        bookingDate: DateTime.now(), // This would be the actual booking date
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      _showSingleRatingPrompt(context, pendingRating);
    } catch (e) {
      debugPrint(
          '❌ RatingPromptManager: Error showing rating prompt for booking: $e');
    }
  }

  /// Show message when user tries to rate something they've already rated
  void _showAlreadyRatedSnackBar(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star, color: Colors.white),
            SizedBox(width: 8),
            Text('You have already rated this booking'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Get rating statistics for display
  Future<RatingStats> getRatingStatsForEntity(
      String entityId, RatingType ratingType) async {
    return await _ratingService.getRatingStats(entityId, ratingType);
  }

  /// Get ratings stream for real-time updates
  Stream<List<RatingModel>> getRatingsForEntity(
      String entityId, RatingType ratingType) {
    return _ratingService.getRatingsForEntity(entityId, ratingType);
  }

  /// Dispose resources (if needed)
  void dispose() {
    // Clean up any resources if needed
  }
}

/// Widget that automatically checks for pending ratings when built
class AutoRatingPromptChecker extends StatefulWidget {
  final Widget child;
  final Duration checkDelay;

  const AutoRatingPromptChecker({
    super.key,
    required this.child,
    this.checkDelay = const Duration(seconds: 2),
  });

  @override
  State<AutoRatingPromptChecker> createState() =>
      _AutoRatingPromptCheckerState();
}

class _AutoRatingPromptCheckerState extends State<AutoRatingPromptChecker> {
  final RatingPromptManager _promptManager = RatingPromptManager();
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _scheduleRatingCheck();
  }

  void _scheduleRatingCheck() {
    Future.delayed(widget.checkDelay, () {
      if (mounted && !_hasChecked) {
        _hasChecked = true;
        _promptManager.checkAndShowPendingRatings(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Badge widget that shows pending ratings count
class PendingRatingsBadge extends StatelessWidget {
  final Widget child;
  final RatingPromptManager _promptManager = RatingPromptManager();

  PendingRatingsBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _promptManager.getPendingRatingsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        if (count == 0) {
          return child;
        }

        return Badge(
          label: Text(count.toString()),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          child: child,
        );
      },
    );
  }
}
