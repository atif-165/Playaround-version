import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/user_profile.dart';

/// Service for caching chat-related data to improve performance
class ChatCacheService {
  static final ChatCacheService _instance = ChatCacheService._internal();
  factory ChatCacheService() => _instance;
  ChatCacheService._internal();

  // Cache for user profiles
  final Map<String, UserProfile> _userProfileCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cache for chat room participant data
  final Map<String, Map<String, dynamic>> _participantCache = {};

  // Cache for chat room display names and images
  final Map<String, Map<String, String?>> _displayDataCache = {};

  /// Get cached user profile
  UserProfile? getCachedUserProfile(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return null;

    // Check if cache is expired
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _userProfileCache.remove(userId);
      _cacheTimestamps.remove(userId);
      return null;
    }

    return _userProfileCache[userId];
  }

  /// Cache user profile
  void cacheUserProfile(String userId, UserProfile profile) {
    _userProfileCache[userId] = profile;
    _cacheTimestamps[userId] = DateTime.now();

    if (kDebugMode) {
      debugPrint('📦 ChatCacheService: Cached profile for user $userId');
    }
  }

  /// Get cached participant data
  Map<String, dynamic>? getCachedParticipantData(String chatId) {
    return _participantCache[chatId];
  }

  /// Cache participant data
  void cacheParticipantData(String chatId, Map<String, dynamic> data) {
    _participantCache[chatId] = data;
  }

  /// Get cached display data (name, image)
  Map<String, String?>? getCachedDisplayData(
      String chatId, String currentUserId) {
    final key = '${chatId}_$currentUserId';
    return _displayDataCache[key];
  }

  /// Cache display data
  void cacheDisplayData(
      String chatId, String currentUserId, String name, String? imageUrl) {
    final key = '${chatId}_$currentUserId';
    _displayDataCache[key] = {
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheDuration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _userProfileCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint(
          '🧹 ChatCacheService: Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear all cache
  void clearAllCache() {
    _userProfileCache.clear();
    _cacheTimestamps.clear();
    _participantCache.clear();
    _displayDataCache.clear();

    if (kDebugMode) {
      debugPrint('🧹 ChatCacheService: Cleared all cache');
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'userProfiles': _userProfileCache.length,
      'participantData': _participantCache.length,
      'displayData': _displayDataCache.length,
    };
  }
}
