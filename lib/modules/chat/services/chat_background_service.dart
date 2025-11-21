import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_background.dart';

/// Service to manage chat background preferences (per-chat basis)
class ChatBackgroundService {
  static const String _backgroundKeyPrefix = 'chat_background_';
  static const String _globalBackgroundKey = 'chat_background_global';
  static const String _bubbleColorsKeyPrefix = 'chat_bubble_colors_';

  /// Get background for a specific chat
  Future<ChatBackground> getBackgroundForChat(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_backgroundKeyPrefix$chatId');

      if (jsonString == null) {
        // Fall back to global background if no per-chat background set
        return getGlobalBackground();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChatBackground.fromJson(json);
    } catch (e) {
      return ChatBackgrounds.defaultBackground;
    }
  }

  /// Save background for a specific chat
  Future<bool> saveBackgroundForChat(
      String chatId, ChatBackground background) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(background.toJson());
      return await prefs.setString('$_backgroundKeyPrefix$chatId', jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Get global background (fallback for chats without specific background)
  Future<ChatBackground> getGlobalBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_globalBackgroundKey);

      if (jsonString == null) {
        return ChatBackgrounds.defaultBackground;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChatBackground.fromJson(json);
    } catch (e) {
      return ChatBackgrounds.defaultBackground;
    }
  }

  /// Save global background (applies to all chats without specific background)
  Future<bool> saveGlobalBackground(ChatBackground background) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(background.toJson());
      return await prefs.setString(_globalBackgroundKey, jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Reset background for a specific chat to global default
  Future<bool> resetChatBackground(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final removedBackground =
          await prefs.remove('$_backgroundKeyPrefix$chatId');
      await prefs.remove('$_bubbleColorsKeyPrefix$chatId');
      return removedBackground;
    } catch (e) {
      return false;
    }
  }

  /// Reset all backgrounds to default
  Future<bool> resetAllBackgrounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_backgroundKeyPrefix) ||
            key == _globalBackgroundKey) {
          await prefs.remove(key);
        }
        if (key.startsWith(_bubbleColorsKeyPrefix)) {
          await prefs.remove(key);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ChatBubbleColors> getBubbleColors(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_bubbleColorsKeyPrefix$chatId');
      if (jsonString == null) {
        return ChatBubbleColors.defaults;
      }
      final json =
          jsonDecode(jsonString) as Map<String, dynamic>? ?? const {};
      return ChatBubbleColors.fromJson(json);
    } catch (_) {
      return ChatBubbleColors.defaults;
    }
  }

  Future<bool> saveBubbleColors(
      String chatId, ChatBubbleColors colors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(colors.toJson());
      return await prefs.setString(
          '$_bubbleColorsKeyPrefix$chatId', jsonString);
    } catch (_) {
      return false;
    }
  }
}
