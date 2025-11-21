import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void localNotificationBackgroundHandler(NotificationResponse response) {
  LocalNotificationService()._handleNotificationResponse(response);
}

/// Handles initialization and delivery of local notifications across the app.
class LocalNotificationService {
  LocalNotificationService._internal();

  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _payloadStreamController =
      StreamController.broadcast();

  bool _initialized = false;

  /// Stream notifying listeners when a notification is tapped.
  Stream<Map<String, dynamic>> get payloadStream =>
      _payloadStreamController.stream;

  /// Initialize the local notifications plugin.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      notificationCategories: const <DarwinNotificationCategory>[],
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          localNotificationBackgroundHandler,
    );

    await _requestPermissions();
    _initialized = true;
  }

  /// Request runtime permissions where required (Android 13+/iOS).
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Display a notification immediately.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'playaround_engagement',
      'Engagement Updates',
      channelDescription:
          'Notifications for bookings, sessions, and tournaments',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _payloadStreamController.add(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalNotificationService: failed to decode payload: $e');
      }
    }
  }

  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _payloadStreamController.add(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'LocalNotificationService: failed to decode legacy payload: $e');
      }
    }
  }

  /// Dispose resources. Only used in tests.
  @visibleForTesting
  Future<void> dispose() async {
    await _payloadStreamController.close();
    _initialized = false;
  }
}
