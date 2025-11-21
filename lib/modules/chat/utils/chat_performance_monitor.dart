import 'package:flutter/foundation.dart';

/// Utility class for monitoring chat performance
class ChatPerformanceMonitor {
  static final ChatPerformanceMonitor _instance =
      ChatPerformanceMonitor._internal();
  factory ChatPerformanceMonitor() => _instance;
  ChatPerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, Duration> _measurements = {};

  /// Start timing a performance operation
  void startTiming(String operation) {
    _startTimes[operation] = DateTime.now();
    if (kDebugMode) {
      debugPrint('⏱️ ChatPerformanceMonitor: Started timing $operation');
    }
  }

  /// End timing and record the duration
  Duration endTiming(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ ChatPerformanceMonitor: No start time found for $operation');
      }
      return Duration.zero;
    }

    final duration = DateTime.now().difference(startTime);
    _measurements[operation] = duration;

    if (kDebugMode) {
      debugPrint(
          '⏱️ ChatPerformanceMonitor: $operation took ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Get measurement for a specific operation
  Duration? getMeasurement(String operation) {
    return _measurements[operation];
  }

  /// Get all measurements
  Map<String, Duration> getAllMeasurements() {
    return Map.from(_measurements);
  }

  /// Check if an operation meets performance requirements
  bool meetsPerformanceRequirement(String operation, Duration maxDuration) {
    final measurement = _measurements[operation];
    if (measurement == null) return false;
    return measurement <= maxDuration;
  }

  /// Clear all measurements
  void clearMeasurements() {
    _measurements.clear();
    _startTimes.clear();
    if (kDebugMode) {
      debugPrint('🧹 ChatPerformanceMonitor: Cleared all measurements');
    }
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    for (final entry in _measurements.entries) {
      report[entry.key] = {
        'duration_ms': entry.value.inMilliseconds,
        'meets_3s_requirement': entry.value <= const Duration(seconds: 3),
        'meets_1s_requirement': entry.value <= const Duration(seconds: 1),
      };
    }

    return report;
  }

  /// Log performance report
  void logPerformanceReport() {
    if (kDebugMode) {
      debugPrint('📊 ChatPerformanceMonitor: Performance Report');
      debugPrint('=====================================');

      final report = getPerformanceReport();
      for (final entry in report.entries) {
        final data = entry.value as Map<String, dynamic>;
        final duration = data['duration_ms'] as int;
        final meets3s = data['meets_3s_requirement'] as bool;
        final meets1s = data['meets_1s_requirement'] as bool;

        debugPrint(
            '${entry.key}: ${duration}ms (3s: ${meets3s ? "✅" : "❌"}, 1s: ${meets1s ? "✅" : "❌"})');
      }

      debugPrint('=====================================');
    }
  }
}
