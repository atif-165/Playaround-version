import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

class MockNotification {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;

  const MockNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
  });
}

class MockPushGenerator {
  MockPushGenerator._internal();

  static final MockPushGenerator _instance = MockPushGenerator._internal();
  factory MockPushGenerator() => _instance;

  final StreamController<MockNotification> _controller =
      StreamController.broadcast();
  Timer? _messageTimer;
  Timer? _orderTimer;
  final Random _random = Random();

  Stream<MockNotification> get notifications => _controller.stream;

  void start() {
    _messageTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => _emitMessageNotification(),
    );

    _orderTimer ??= Timer.periodic(
      const Duration(minutes: 2),
      (_) => _emitOrderNotification(),
    );

    if (kDebugMode) {
      debugPrint('MockPushGenerator started');
    }
  }

  void stop() {
    _messageTimer?.cancel();
    _orderTimer?.cancel();
    _messageTimer = null;
    _orderTimer = null;
    if (kDebugMode) {
      debugPrint('MockPushGenerator stopped');
    }
  }

  void dispose() {
    stop();
    _controller.close();
  }

  void _emitMessageNotification() {
    final notification = MockNotification(
      type: 'chat',
      title: 'New message from Alex',
      body: _sampleMessages[_random.nextInt(_sampleMessages.length)],
      payload: {
        'chatId': 'demo_chat_${_random.nextInt(100)}',
        'senderId': 'demo_user_${_random.nextInt(10)}',
      },
    );
    _notify(notification);
  }

  void _emitOrderNotification() {
    final orderId = 'order_${1000 + _random.nextInt(9000)}';
    final status = _orderStatuses[_random.nextInt(_orderStatuses.length)];
    final notification = MockNotification(
      type: 'order',
      title: 'Order $orderId update',
      body: 'Status changed to ${status.toUpperCase()}',
      payload: {
        'orderId': orderId,
        'status': status,
      },
    );
    _notify(notification);
  }

  void _notify(MockNotification notification) {
    if (_controller.hasListener) {
      _controller.add(notification);
    }
    if (kDebugMode) {
      debugPrint(
          'Mock push emitted: ${notification.title} • ${notification.body}');
    }
  }
}

const List<String> _sampleMessages = [
  'Don\'t miss tonight\'s training session!',
  'Your order has been packaged for shipment.',
  'Reminder: Match starts at 7 PM.',
  'New drills are available in your skill tracker.',
  'Alex sent a new attachment in the group chat.',
];

const List<String> _orderStatuses = ['processing', 'shipped', 'completed'];
