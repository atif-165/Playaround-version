import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import '../../../models/booking_model.dart';
import '../../../models/booking_analytics_model.dart';
import '../../../models/user_profile.dart';

/// Service for calculating booking analytics and generating reports
class BookingAnalyticsService {
  final FirebaseFirestore _firestore;

  static const String _bookingsCollection = 'bookings';
  static const String _analyticsCollection = 'booking_analytics';

  BookingAnalyticsService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate comprehensive booking analytics for a user
  Future<BookingAnalytics> generateUserAnalytics({
    required String userId,
    required UserRole userRole,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final defaultStartDate = startDate ?? DateTime(now.year, now.month, 1);
      final defaultEndDate = endDate ?? now;

      // Get all bookings for the user in the specified period
      final bookings = await _getUserBookingsInPeriod(
        userId,
        userRole,
        defaultStartDate,
        defaultEndDate,
      );

      // Calculate basic statistics
      final totalBookings = bookings.length;
      final completedBookings = bookings.where((b) => b.isCompleted).length;
      final cancelledBookings = bookings.where((b) => b.isCancelled).length;
      final upcomingBookings = bookings.where((b) => b.isUpcoming).length;

      // Calculate earnings/spending
      double totalEarnings = 0.0;
      double totalSpent = 0.0;

      for (final booking in bookings) {
        if (booking.isCompleted) {
          if (userRole == UserRole.coach && booking.ownerId == userId) {
            totalEarnings += booking.totalAmount;
          } else if (booking.userId == userId) {
            totalSpent += booking.totalAmount;
          }
        }
      }

      // Calculate bookings by sport
      final bookingsBySport = <String, int>{};
      final earningsBySport = <String, double>{};
      final spentBySport = <String, double>{};

      for (final booking in bookings) {
        final sport = booking.sportType.displayName;
        bookingsBySport[sport] = (bookingsBySport[sport] ?? 0) + 1;

        if (booking.isCompleted) {
          if (userRole == UserRole.coach && booking.ownerId == userId) {
            earningsBySport[sport] =
                (earningsBySport[sport] ?? 0.0) + booking.totalAmount;
          } else if (booking.userId == userId) {
            spentBySport[sport] =
                (spentBySport[sport] ?? 0.0) + booking.totalAmount;
          }
        }
      }

      // Generate daily statistics
      final dailyStats = _generateDailyStats(
          bookings, userId, userRole, defaultStartDate, defaultEndDate);

      return BookingAnalytics(
        userId: userId,
        userRole: userRole.value,
        periodStart: defaultStartDate,
        periodEnd: defaultEndDate,
        totalBookings: totalBookings,
        completedBookings: completedBookings,
        cancelledBookings: cancelledBookings,
        upcomingBookings: upcomingBookings,
        totalEarnings: totalEarnings,
        totalSpent: totalSpent,
        bookingsBySport: bookingsBySport,
        earningsBySport: earningsBySport,
        spentBySport: spentBySport,
        dailyStats: dailyStats,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingAnalyticsService: Error generating analytics: $e');
      }
      throw Exception('Failed to generate analytics: $e');
    }
  }

  /// Get user bookings in a specific period
  Future<List<BookingModel>> _getUserBookingsInPeriod(
    String userId,
    UserRole userRole,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final List<BookingModel> allBookings = [];

      // Get bookings as player
      final playerQuery = await _firestore
          .collection(_bookingsCollection)
          .where('userId', isEqualTo: userId)
          .where('selectedDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('selectedDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      for (final doc in playerQuery.docs) {
        allBookings.add(BookingModel.fromFirestore(doc));
      }

      // Get bookings as coach (if applicable)
      if (userRole == UserRole.coach || userRole == UserRole.admin) {
        final coachQuery = await _firestore
            .collection(_bookingsCollection)
            .where('ownerId', isEqualTo: userId)
            .where('selectedDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('selectedDate',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .get();

        for (final doc in coachQuery.docs) {
          final booking = BookingModel.fromFirestore(doc);
          // Avoid duplicates
          if (!allBookings.any((b) => b.id == booking.id)) {
            allBookings.add(booking);
          }
        }
      }

      return allBookings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ BookingAnalyticsService: Error getting user bookings: $e');
      }
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Generate daily statistics from bookings
  List<DailyBookingStats> _generateDailyStats(
    List<BookingModel> bookings,
    String userId,
    UserRole userRole,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyStats = <DateTime, DailyBookingStats>{};

    // Initialize all days in the period with zero stats
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      final dayKey = DateTime(date.year, date.month, date.day);
      dailyStats[dayKey] = DailyBookingStats(
        date: dayKey,
        bookingsCount: 0,
        completedCount: 0,
        cancelledCount: 0,
        earnings: 0.0,
        spent: 0.0,
      );
    }

    // Populate with actual booking data
    for (final booking in bookings) {
      final dayKey = DateTime(
        booking.selectedDate.year,
        booking.selectedDate.month,
        booking.selectedDate.day,
      );

      if (dailyStats.containsKey(dayKey)) {
        final currentStats = dailyStats[dayKey]!;

        int bookingsCount = currentStats.bookingsCount + 1;
        int completedCount = currentStats.completedCount;
        int cancelledCount = currentStats.cancelledCount;
        double earnings = currentStats.earnings;
        double spent = currentStats.spent;

        if (booking.isCompleted) {
          completedCount++;
          if (userRole == UserRole.coach && booking.ownerId == userId) {
            earnings += booking.totalAmount;
          } else if (booking.userId == userId) {
            spent += booking.totalAmount;
          }
        } else if (booking.isCancelled) {
          cancelledCount++;
        }

        dailyStats[dayKey] = DailyBookingStats(
          date: dayKey,
          bookingsCount: bookingsCount,
          completedCount: completedCount,
          cancelledCount: cancelledCount,
          earnings: earnings,
          spent: spent,
        );
      }
    }

    return dailyStats.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Save analytics to Firestore for caching
  Future<void> saveAnalytics(BookingAnalytics analytics) async {
    try {
      final docId =
          '${analytics.userId}_${analytics.periodStart.millisecondsSinceEpoch}_${analytics.periodEnd.millisecondsSinceEpoch}';

      await _firestore
          .collection(_analyticsCollection)
          .doc(docId)
          .set(analytics.toFirestore());

      if (kDebugMode) {
        debugPrint(
            '✅ BookingAnalyticsService: Saved analytics for user: ${analytics.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ BookingAnalyticsService: Error saving analytics: $e');
      }
      throw Exception('Failed to save analytics: $e');
    }
  }

  /// Get cached analytics from Firestore
  Future<BookingAnalytics?> getCachedAnalytics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final docId =
          '${userId}_${startDate.millisecondsSinceEpoch}_${endDate.millisecondsSinceEpoch}';

      final doc =
          await _firestore.collection(_analyticsCollection).doc(docId).get();

      if (doc.exists) {
        return BookingAnalytics.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ BookingAnalyticsService: Error getting cached analytics: $e');
      }
      return null;
    }
  }

  /// Calculate revenue trends for coach
  Future<Map<String, double>> calculateRevenueTrends({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
    String period = 'monthly', // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      final bookings = await _getUserBookingsInPeriod(
        coachId,
        UserRole.coach,
        startDate,
        endDate,
      );

      final completedBookings =
          bookings.where((b) => b.isCompleted && b.ownerId == coachId).toList();

      final trends = <String, double>{};

      for (final booking in completedBookings) {
        String key;
        switch (period) {
          case 'daily':
            key =
                '${booking.selectedDate.year}-${booking.selectedDate.month.toString().padLeft(2, '0')}-${booking.selectedDate.day.toString().padLeft(2, '0')}';
            break;
          case 'weekly':
            final weekStart = booking.selectedDate
                .subtract(Duration(days: booking.selectedDate.weekday - 1));
            key =
                '${weekStart.year}-W${((weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays) / 7).ceil()}';
            break;
          case 'monthly':
          default:
            key =
                '${booking.selectedDate.year}-${booking.selectedDate.month.toString().padLeft(2, '0')}';
            break;
        }

        trends[key] = (trends[key] ?? 0.0) + booking.totalAmount;
      }

      return trends;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ BookingAnalyticsService: Error calculating revenue trends: $e');
      }
      throw Exception('Failed to calculate revenue trends: $e');
    }
  }

  /// Get top performing sports for coach
  Future<Map<String, double>> getTopPerformingSports({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();
      final defaultStartDate = startDate ?? DateTime(now.year, 1, 1);
      final defaultEndDate = endDate ?? now;

      final bookings = await _getUserBookingsInPeriod(
        coachId,
        UserRole.coach,
        defaultStartDate,
        defaultEndDate,
      );

      final completedBookings =
          bookings.where((b) => b.isCompleted && b.ownerId == coachId).toList();

      final sportEarnings = <String, double>{};

      for (final booking in completedBookings) {
        final sport = booking.sportType.displayName;
        sportEarnings[sport] =
            (sportEarnings[sport] ?? 0.0) + booking.totalAmount;
      }

      // Sort by earnings and take top performers
      final sortedSports = sportEarnings.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedSports.take(limit));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ BookingAnalyticsService: Error getting top performing sports: $e');
      }
      throw Exception('Failed to get top performing sports: $e');
    }
  }
}
