import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_model.dart';

/// Model for booking analytics and earnings data
class BookingAnalytics {
  final String userId;
  final String userRole; // 'player' or 'coach'
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int upcomingBookings;
  final double totalEarnings; // For coaches
  final double totalSpent; // For players
  final Map<String, int> bookingsBySport;
  final Map<String, double> earningsBySport; // For coaches
  final Map<String, double> spentBySport; // For players
  final List<DailyBookingStats> dailyStats;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingAnalytics({
    required this.userId,
    required this.userRole,
    required this.periodStart,
    required this.periodEnd,
    required this.totalBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.upcomingBookings,
    required this.totalEarnings,
    required this.totalSpent,
    required this.bookingsBySport,
    required this.earningsBySport,
    required this.spentBySport,
    required this.dailyStats,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userRole': userRole,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'totalBookings': totalBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'upcomingBookings': upcomingBookings,
      'totalEarnings': totalEarnings,
      'totalSpent': totalSpent,
      'bookingsBySport': bookingsBySport,
      'earningsBySport': earningsBySport,
      'spentBySport': spentBySport,
      'dailyStats': dailyStats.map((stat) => stat.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory BookingAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingAnalytics.fromMap(data);
  }

  /// Create from Map
  factory BookingAnalytics.fromMap(Map<String, dynamic> map) {
    return BookingAnalytics(
      userId: map['userId'] as String,
      userRole: map['userRole'] as String,
      periodStart: (map['periodStart'] as Timestamp).toDate(),
      periodEnd: (map['periodEnd'] as Timestamp).toDate(),
      totalBookings: map['totalBookings'] as int,
      completedBookings: map['completedBookings'] as int,
      cancelledBookings: map['cancelledBookings'] as int,
      upcomingBookings: map['upcomingBookings'] as int,
      totalEarnings: (map['totalEarnings'] as num).toDouble(),
      totalSpent: (map['totalSpent'] as num).toDouble(),
      bookingsBySport: Map<String, int>.from(map['bookingsBySport'] as Map),
      earningsBySport: Map<String, double>.from(
        (map['earningsBySport'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))
      ),
      spentBySport: Map<String, double>.from(
        (map['spentBySport'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))
      ),
      dailyStats: (map['dailyStats'] as List<dynamic>)
          .map((stat) => DailyBookingStats.fromMap(stat as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Calculate completion rate
  double get completionRate {
    if (totalBookings == 0) return 0.0;
    return (completedBookings / totalBookings) * 100;
  }

  /// Calculate cancellation rate
  double get cancellationRate {
    if (totalBookings == 0) return 0.0;
    return (cancelledBookings / totalBookings) * 100;
  }

  /// Get average earnings per booking (for coaches)
  double get averageEarningsPerBooking {
    if (completedBookings == 0) return 0.0;
    return totalEarnings / completedBookings;
  }

  /// Get average spent per booking (for players)
  double get averageSpentPerBooking {
    if (completedBookings == 0) return 0.0;
    return totalSpent / completedBookings;
  }
}

/// Model for daily booking statistics
class DailyBookingStats {
  final DateTime date;
  final int bookingsCount;
  final int completedCount;
  final int cancelledCount;
  final double earnings; // For coaches
  final double spent; // For players

  const DailyBookingStats({
    required this.date,
    required this.bookingsCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.earnings,
    required this.spent,
  });

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'bookingsCount': bookingsCount,
      'completedCount': completedCount,
      'cancelledCount': cancelledCount,
      'earnings': earnings,
      'spent': spent,
    };
  }

  /// Create from Map
  factory DailyBookingStats.fromMap(Map<String, dynamic> map) {
    return DailyBookingStats(
      date: (map['date'] as Timestamp).toDate(),
      bookingsCount: map['bookingsCount'] as int,
      completedCount: map['completedCount'] as int,
      cancelledCount: map['cancelledCount'] as int,
      earnings: (map['earnings'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
    );
  }
}

/// Model for earnings summary
class EarningsSummary {
  final String coachId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalEarnings;
  final double pendingEarnings; // From confirmed but not completed bookings
  final int totalSessions;
  final int completedSessions;
  final Map<String, double> earningsBySport;
  final Map<String, double> earningsByMonth;
  final double averageSessionEarnings;
  final double highestSessionEarnings;
  final String mostProfitableSport;

  const EarningsSummary({
    required this.coachId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.totalSessions,
    required this.completedSessions,
    required this.earningsBySport,
    required this.earningsByMonth,
    required this.averageSessionEarnings,
    required this.highestSessionEarnings,
    required this.mostProfitableSport,
  });

  /// Create earnings summary from booking list
  factory EarningsSummary.fromBookings(
    String coachId,
    List<BookingModel> bookings,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final completedBookings = bookings.where((b) => b.isCompleted).toList();
    final confirmedBookings = bookings.where((b) => 
      b.status == BookingStatus.confirmed || b.status == BookingStatus.pending
    ).toList();

    final totalEarnings = completedBookings.fold<double>(
      0.0, (total, booking) => total + booking.totalAmount
    );

    final pendingEarnings = confirmedBookings.fold<double>(
      0.0, (total, booking) => total + booking.totalAmount
    );

    // Calculate earnings by sport
    final earningsBySport = <String, double>{};
    for (final booking in completedBookings) {
      final sport = booking.sportType.displayName;
      earningsBySport[sport] = (earningsBySport[sport] ?? 0.0) + booking.totalAmount;
    }

    // Calculate earnings by month
    final earningsByMonth = <String, double>{};
    for (final booking in completedBookings) {
      final monthKey = '${booking.selectedDate.year}-${booking.selectedDate.month.toString().padLeft(2, '0')}';
      earningsByMonth[monthKey] = (earningsByMonth[monthKey] ?? 0.0) + booking.totalAmount;
    }

    final averageSessionEarnings = completedBookings.isNotEmpty 
        ? totalEarnings / completedBookings.length 
        : 0.0;

    final highestSessionEarnings = completedBookings.isNotEmpty
        ? completedBookings.map((b) => b.totalAmount).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final mostProfitableSport = earningsBySport.isNotEmpty
        ? earningsBySport.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : '';

    return EarningsSummary(
      coachId: coachId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalEarnings: totalEarnings,
      pendingEarnings: pendingEarnings,
      totalSessions: bookings.length,
      completedSessions: completedBookings.length,
      earningsBySport: earningsBySport,
      earningsByMonth: earningsByMonth,
      averageSessionEarnings: averageSessionEarnings,
      highestSessionEarnings: highestSessionEarnings,
      mostProfitableSport: mostProfitableSport,
    );
  }
}
