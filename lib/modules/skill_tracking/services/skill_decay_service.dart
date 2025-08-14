import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../services/user_activity_service.dart';
import 'automated_skill_service.dart';

/// Service for managing skill decay due to user inactivity
class SkillDecayService {
  static final SkillDecayService _instance = SkillDecayService._internal();
  factory SkillDecayService() => _instance;
  SkillDecayService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserActivityService _activityService = UserActivityService();
  final AutomatedSkillService _automatedSkillService = AutomatedSkillService();

  // Configuration
  static const int defaultInactivityThreshold = 10; // days
  static const int batchSize = 50; // Process users in batches
  static const String lastDecayCheckKey = 'lastDecayCheck';

  /// Run skill decay check for all users
  Future<void> runSkillDecayCheck() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 SkillDecayService: Starting skill decay check...');
      }

      // Check if we should run decay (don't run more than once per day)
      if (!await _shouldRunDecayCheck()) {
        if (kDebugMode) {
          debugPrint('⏭️ SkillDecayService: Decay check already run today, skipping');
        }
        return;
      }

      // Get inactive users
      final inactiveUsers = await _activityService.getInactiveUsers(defaultInactivityThreshold);
      
      if (inactiveUsers.isEmpty) {
        if (kDebugMode) {
          debugPrint('✅ SkillDecayService: No inactive users found');
        }
        await _updateLastDecayCheck();
        return;
      }

      if (kDebugMode) {
        debugPrint('🎯 SkillDecayService: Found ${inactiveUsers.length} inactive users');
      }

      // Process users in batches
      int processedCount = 0;
      int decayedCount = 0;

      for (int i = 0; i < inactiveUsers.length; i += batchSize) {
        final batch = inactiveUsers.skip(i).take(batchSize).toList();
        
        for (final userId in batch) {
          try {
            final wasDecayed = await _processUserDecay(userId);
            if (wasDecayed) decayedCount++;
            processedCount++;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ SkillDecayService: Error processing decay for user $userId: $e');
            }
          }
        }

        // Small delay between batches to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _updateLastDecayCheck();

      if (kDebugMode) {
        debugPrint('✅ SkillDecayService: Processed $processedCount users, applied decay to $decayedCount users');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error running skill decay check: $e');
      }
    }
  }

  /// Process skill decay for a specific user
  Future<bool> _processUserDecay(String userId) async {
    try {
      final daysSinceActive = await _activityService.getDaysSinceLastActive(userId);
      
      if (daysSinceActive < defaultInactivityThreshold) {
        return false; // User is not inactive enough for decay
      }

      // Apply decay
      await _automatedSkillService.applyInactivityDecay(userId);
      
      if (kDebugMode) {
        debugPrint('🔄 SkillDecayService: Applied decay to user $userId ($daysSinceActive days inactive)');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error processing decay for user $userId: $e');
      }
      return false;
    }
  }

  /// Check if we should run decay check (once per day)
  Future<bool> _shouldRunDecayCheck() async {
    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('skill_decay')
          .get();

      if (!doc.exists) {
        return true; // First time running
      }

      final data = doc.data() as Map<String, dynamic>;
      final lastCheck = (data[lastDecayCheckKey] as Timestamp?)?.toDate();
      
      if (lastCheck == null) {
        return true;
      }

      // Check if last run was more than 24 hours ago
      final hoursSinceLastCheck = DateTime.now().difference(lastCheck).inHours;
      return hoursSinceLastCheck >= 24;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error checking if should run decay: $e');
      }
      return true; // Default to running if error
    }
  }

  /// Update the last decay check timestamp
  Future<void> _updateLastDecayCheck() async {
    try {
      await _firestore
          .collection('system_config')
          .doc('skill_decay')
          .set({
        lastDecayCheckKey: Timestamp.fromDate(DateTime.now()),
        'lastRunBy': 'system',
        'version': '1.0',
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error updating last decay check: $e');
      }
    }
  }

  /// Force run decay for a specific user (admin function)
  Future<void> forceDecayForUser(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 SkillDecayService: Force running decay for user $userId');
      }

      await _automatedSkillService.applyInactivityDecay(userId);
      
      if (kDebugMode) {
        debugPrint('✅ SkillDecayService: Force decay completed for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error force running decay for user $userId: $e');
      }
      throw Exception('Failed to apply skill decay: $e');
    }
  }

  /// Get decay statistics
  Future<Map<String, dynamic>> getDecayStatistics() async {
    try {
      final inactiveUsers = await _activityService.getInactiveUsers(defaultInactivityThreshold);
      
      // Get last decay check info
      final configDoc = await _firestore
          .collection('system_config')
          .doc('skill_decay')
          .get();

      DateTime? lastDecayCheck;
      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        lastDecayCheck = (data[lastDecayCheckKey] as Timestamp?)?.toDate();
      }

      return {
        'inactiveUsersCount': inactiveUsers.length,
        'inactivityThresholdDays': defaultInactivityThreshold,
        'lastDecayCheck': lastDecayCheck?.toIso8601String(),
        'nextDecayCheckDue': lastDecayCheck != null 
            ? lastDecayCheck.add(const Duration(hours: 24)).toIso8601String()
            : 'Now',
        'shouldRunDecayCheck': await _shouldRunDecayCheck(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error getting decay statistics: $e');
      }
      return {
        'error': e.toString(),
      };
    }
  }

  /// Initialize decay service (call on app start for admin users)
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 SkillDecayService: Initializing...');
      }

      // Check if we need to run decay check
      if (await _shouldRunDecayCheck()) {
        // Run in background without blocking app startup
        Future.delayed(const Duration(seconds: 30), () {
          runSkillDecayCheck();
        });
      }

      if (kDebugMode) {
        debugPrint('✅ SkillDecayService: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SkillDecayService: Error initializing: $e');
      }
    }
  }
}
