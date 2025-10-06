import 'package:flutter/material.dart';

/// Extension methods for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  /// Add a duration to a TimeOfDay
  TimeOfDay add(Duration duration) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
    final newDateTime = dateTime.add(duration);
    return TimeOfDay.fromDateTime(newDateTime);
  }

  /// Subtract a duration from a TimeOfDay
  TimeOfDay subtract(Duration duration) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
    final newDateTime = dateTime.subtract(duration);
    return TimeOfDay.fromDateTime(newDateTime);
  }

  /// Convert TimeOfDay to minutes since midnight
  int toMinutes() {
    return hour * 60 + minute;
  }

  /// Create TimeOfDay from minutes since midnight
  static TimeOfDay fromMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return TimeOfDay(hour: hours, minute: mins);
  }

  /// Check if this time is before another time
  bool isBefore(TimeOfDay other) {
    return toMinutes() < other.toMinutes();
  }

  /// Check if this time is after another time
  bool isAfter(TimeOfDay other) {
    return toMinutes() > other.toMinutes();
  }

  /// Check if this time is the same as another time
  bool isSame(TimeOfDay other) {
    return toMinutes() == other.toMinutes();
  }
}
