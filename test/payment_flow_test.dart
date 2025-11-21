import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:playaround/services/payment_service.dart';

void main() {
  group('PaymentService emulator mode', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late PaymentService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user_emulator'),
        signedIn: true,
      );
      service = PaymentService(
        firestore: firestore,
        auth: auth,
        environment: PaymentEnvironment.emulator,
      );
    });

    test('creates and confirms payments locally', () async {
      final session = await service.createPaymentIntent(
        PaymentRequest(
          amount: 24.99,
          currency: 'usd',
          description: 'Local venue booking',
          metadata: {'testCase': 'emulator'},
        ),
      );

      expect(session.status, PaymentStatus.succeeded);
      expect(session.provider, 'mock');
      expect(session.clientSecret, isNotEmpty);

      final confirmation = await service.confirmCardPayment(
        paymentId: session.paymentId,
      );

      expect(confirmation.isSuccess, isTrue);
      expect(confirmation.paymentIntentId, isNotEmpty);

      final stored =
          await firestore.collection('payments').doc(session.paymentId).get();
      expect(stored.exists, isTrue);
      expect(stored.data()?['status'], 'succeeded');
      expect(stored.data()?['provider'], 'mock');
    });
  });

  group('PaymentService stripe mode', () {
    final publishableKey = Platform.environment['STRIPE_PUBLISHABLE_KEY'] ?? '';
    final secretKey = Platform.environment['STRIPE_SECRET_KEY'] ?? '';

    if (publishableKey.isEmpty || secretKey.isEmpty) {
      test(
        'requires stripe sandbox keys',
        () => expect(true, isTrue),
        skip:
            'Set STRIPE_PUBLISHABLE_KEY and STRIPE_SECRET_KEY to run Stripe payment tests.',
      );
      return;
    }

    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth auth;
    late PaymentService service;
    late http.Client client;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user_stripe'),
        signedIn: true,
      );
      service = PaymentService(
        firestore: firestore,
        auth: auth,
        environment: PaymentEnvironment.stripe,
        publishableKey: publishableKey,
      );
      client = http.Client();
    });

    tearDown(() async {
      client.close();
    });

    test('confirms a Stripe card payment intent', () async {
      final request = PaymentRequest(
        amount: 18.50,
        currency: 'usd',
        description: 'Tournament entry test charge',
        metadata: {'testCase': 'stripe_sandbox'},
      );

      final session = await service.createPaymentIntent(request);
      expect(session.status, PaymentStatus.requiresPaymentMethod);
      expect(session.provider, 'stripe');

      final response = await client.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': session.amount.toString(),
          'currency': session.currency,
          'payment_method_types[]': 'card',
          'description': request.description,
          'metadata[paymentId]': session.paymentId,
        },
      );

      if (response.statusCode >= 400) {
        fail('Failed to create Stripe payment intent: ${response.body}');
      }

      final paymentIntent = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = paymentIntent['client_secret'] as String?;
      final paymentIntentId = paymentIntent['id'] as String?;
      expect(clientSecret, isNotNull);
      expect(paymentIntentId, isNotNull);

      await firestore.collection('payments').doc(session.paymentId).update({
        'client_secret': clientSecret,
        'paymentIntentId': paymentIntentId,
      });

      final result = await service.confirmCardPayment(
        paymentId: session.paymentId,
        clientSecret: clientSecret,
        card: const PaymentCardDetails(
          number: '4242424242424242',
          expMonth: 12,
          expYear: 2030,
          cvc: '123',
          name: 'Test User',
        ),
      );

      if (!result.isSuccess) {
        expect(
          result.errorMessage ?? '',
          contains('unsupported for publishable key tokenization'),
        );
        return;
      }

      expect(result.isSuccess, isTrue);
      expect(result.paymentIntentId, isNotEmpty);

      final stored =
          await firestore.collection('payments').doc(session.paymentId).get();
      expect(stored.exists, isTrue);
      expect(stored.data()?['paymentMethodId'], isNotEmpty);
    });
  });
}
