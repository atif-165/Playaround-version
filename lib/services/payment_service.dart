import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stripe_sdk/stripe_sdk.dart';

/// Supported payment execution environments.
enum PaymentEnvironment {
  /// Uses a deterministic mock flow that runs entirely on the client.
  emulator,

  /// Executes payments against Stripe via the Firebase payments extension.
  stripe,
}

/// High-level payment state transitions surfaced to the UI.
enum PaymentStatus {
  requiresPaymentMethod,
  requiresConfirmation,
  requiresAction,
  processing,
  succeeded,
  canceled,
  failed,
}

/// Immutable request describing a payment intent to be created.
class PaymentRequest {
  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.description,
    this.orderId,
    Map<String, dynamic>? metadata,
    List<String>? paymentMethodTypes,
  })  : metadata = metadata == null
            ? const <String, dynamic>{}
            : Map.unmodifiable(metadata),
        paymentMethodTypes = paymentMethodTypes == null
            ? const ['card']
            : List.unmodifiable(
                paymentMethodTypes.where((type) => type.isNotEmpty));

  /// Gross charge amount in major currency units (e.g. dollars).
  final double amount;

  /// ISO-4217 3-letter currency code (lowercase).
  final String currency;

  /// Human friendly payment description (surfaceable on receipts).
  final String description;

  /// Optional order identifier to associate with the payment.
  final String? orderId;

  /// Extra metadata forwarded to Stripe / stored alongside the payment.
  final Map<String, dynamic> metadata;

  /// Stripe payment method types to request (defaults to `['card']`).
  final List<String> paymentMethodTypes;
}

/// Card details collected on device. Used exclusively for mock + Stripe flows.
class PaymentCardDetails {
  const PaymentCardDetails({
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvc,
    this.name,
    this.email,
    this.addressCountry,
  });

  final String number;
  final int expMonth;
  final int expYear;
  final String cvc;
  final String? name;
  final String? email;
  final String? addressCountry;

  Map<String, dynamic> toBillingDetails() {
    final billing = <String, dynamic>{};
    if (name != null && name!.isNotEmpty) {
      billing['name'] = name;
    }
    if (email != null && email!.isNotEmpty) {
      billing['email'] = email;
    }
    if (addressCountry != null && addressCountry!.isNotEmpty) {
      billing['address'] = {'country': addressCountry};
    }
    return billing;
  }
}

/// Response returned after registering a payment intent.
class PaymentSession {
  const PaymentSession({
    required this.paymentId,
    required this.status,
    required this.mode,
    required this.provider,
    required this.amount,
    required this.currency,
    this.clientSecret,
    this.paymentIntentId,
  });

  final String paymentId;
  final PaymentStatus status;
  final PaymentEnvironment mode;
  final String provider;
  final int amount;
  final String currency;
  final String? clientSecret;
  final String? paymentIntentId;

  bool get isImmediateSuccess =>
      status == PaymentStatus.succeeded && mode == PaymentEnvironment.emulator;
}

/// Result returned when confirming a payment.
class PaymentResult {
  const PaymentResult({
    required this.paymentId,
    required this.status,
    this.paymentIntentId,
    this.receiptUrl,
    this.errorMessage,
    this.requiresAction = false,
  });

  final String paymentId;
  final PaymentStatus status;
  final String? paymentIntentId;
  final String? receiptUrl;
  final String? errorMessage;
  final bool requiresAction;

  bool get isSuccess => status == PaymentStatus.succeeded;
}

typedef _ClientSecretResolver = Future<String?> Function(
  DocumentReference<Map<String, dynamic>> doc,
  Duration timeout,
);

/// Handles payment flows across emulator and Stripe environments.
class PaymentService {
  PaymentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PaymentEnvironment? environment,
    Stripe? stripe,
    Duration? clientSecretTimeout,
    String? publishableKey,
    String? stripeReturnUrlScheme,
    String? merchantName,
    _ClientSecretResolver? clientSecretResolver,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _environment = environment ?? _resolveEnvironment(),
        _clientSecretTimeout =
            clientSecretTimeout ?? const Duration(seconds: 30),
        _merchantDisplayName = merchantName ??
            const String.fromEnvironment('STRIPE_MERCHANT_NAME',
                defaultValue: 'PlayAround'),
        _returnUrlScheme = stripeReturnUrlScheme ??
            const String.fromEnvironment('STRIPE_RETURN_URL_SCHEME',
                defaultValue: 'playaround'),
        _publishableKey = publishableKey ??
            const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY',
                defaultValue: '') {
    _clientSecretResolver = clientSecretResolver;
    if (_environment == PaymentEnvironment.stripe) {
      if ((_publishableKey ?? '').isEmpty) {
        throw StateError(
          'Stripe publishable key missing. Provide STRIPE_PUBLISHABLE_KEY via --dart-define or pass publishableKey.',
        );
      }
      _stripe = stripe ?? Stripe(_publishableKey!);
    }
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PaymentEnvironment _environment;
  final Duration _clientSecretTimeout;
  final String _merchantDisplayName;
  final String _returnUrlScheme;
  final String? _publishableKey;
  late final Stripe? _stripe;
  _ClientSecretResolver? _clientSecretResolver;

  static PaymentEnvironment _resolveEnvironment() {
    const useMock =
        bool.fromEnvironment('USE_PAYMENTS_EMULATOR', defaultValue: false);
    return useMock ? PaymentEnvironment.emulator : PaymentEnvironment.stripe;
  }

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection('payments');

  PaymentEnvironment get environment => _environment;

  /// Creates a new payment intent document in Firestore.
  Future<PaymentSession> createPaymentIntent(PaymentRequest request) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Cannot start payment without an authenticated user.');
    }

    final trimmedCurrency = request.currency.toLowerCase().trim();
    if (trimmedCurrency.length != 3) {
      throw ArgumentError.value(request.currency, 'currency',
          'Currency must be a 3-letter ISO code.');
    }

    if (request.amount <= 0) {
      throw ArgumentError.value(
          request.amount, 'amount', 'Amount must be greater than zero.');
    }

    final amountMinorUnits = _toMinorUnits(request.amount);

    final docRef = _payments.doc();
    final mode = _environment;
    final now = FieldValue.serverTimestamp();
    final payload = <String, dynamic>{
      'userId': user.uid,
      'amount': amountMinorUnits,
      'currency': trimmedCurrency,
      'description': request.description,
      'mode': mode.name,
      'provider': mode == PaymentEnvironment.emulator ? 'mock' : 'stripe',
      'status': mode == PaymentEnvironment.emulator
          ? 'requires_confirmation'
          : 'requires_payment_method',
      'payment_method_types': request.paymentMethodTypes,
      'paymentMethodTypes': request.paymentMethodTypes,
      'metadata': request.metadata,
      'orderId': request.orderId,
      'createdAt': now,
      'updatedAt': now,
    };

    await docRef.set(payload);

    if (mode == PaymentEnvironment.emulator) {
      final mockSecret =
          'pi_mock_${docRef.id}_${DateTime.now().millisecondsSinceEpoch}';
      final mockIntentId = 'pi_mock_${docRef.id}';

      await docRef.update({
        'status': 'succeeded',
        'client_secret': mockSecret,
        'clientSecret': mockSecret,
        'stripePaymentIntentId': mockIntentId,
        'paymentIntentId': mockIntentId,
        'amountReceived': amountMinorUnits,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastPaymentIntentStatus': 'succeeded',
      });

      return PaymentSession(
        paymentId: docRef.id,
        status: PaymentStatus.succeeded,
        mode: mode,
        provider: 'mock',
        amount: amountMinorUnits,
        currency: trimmedCurrency,
        clientSecret: mockSecret,
        paymentIntentId: mockIntentId,
      );
    }

    return PaymentSession(
      paymentId: docRef.id,
      status: PaymentStatus.requiresPaymentMethod,
      mode: mode,
      provider: 'stripe',
      amount: amountMinorUnits,
      currency: trimmedCurrency,
      clientSecret: null,
    );
  }

  /// Waits for Stripe's extension to populate a client secret for the payment.
  Future<String> waitForClientSecret(
    String paymentId, {
    Duration? timeout,
  }) async {
    final docRef = _payments.doc(paymentId);
    final snapshot = await docRef.get();
    final existing = _extractClientSecret(snapshot.data());
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final resolver = _clientSecretResolver ?? _defaultClientSecretResolver;
    final secret = await resolver(docRef, timeout ?? _clientSecretTimeout);
    if (secret == null || secret.isEmpty) {
      throw StateError(
          'Timed out waiting for client secret on payment $paymentId.');
    }
    return secret;
  }

  /// Confirms a card payment using either the mock flow or Stripe.
  Future<PaymentResult> confirmCardPayment({
    required String paymentId,
    PaymentCardDetails? card,
    String? clientSecret,
  }) async {
    final mode = _environment;
    if (mode == PaymentEnvironment.emulator) {
      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.succeeded,
        paymentIntentId: 'pi_mock_$paymentId',
      );
    }

    if (card == null) {
      throw ArgumentError(
          'card details are required when confirming payments against Stripe.');
    }

    final resolvedSecret = clientSecret ?? await waitForClientSecret(paymentId);
    final stripe = _stripe;
    if (stripe == null) {
      throw StateError('Stripe SDK not initialised.');
    }

    try {
      final cardParams = <String, dynamic>{
        'number': card.number,
        'exp_month': card.expMonth,
        'exp_year': card.expYear,
        'cvc': card.cvc,
      };

      final billingDetails = card.toBillingDetails();
      final paymentMethodPayload = <String, dynamic>{
        'type': 'card',
        'card': cardParams,
        if (billingDetails.isNotEmpty) 'billing_details': billingDetails,
      };

      final paymentMethod =
          await stripe.api.createPaymentMethod(paymentMethodPayload);

      final paymentMethodId = paymentMethod['id'] as String?;
      if (paymentMethodId == null) {
        throw StateError('Stripe did not return a paymentMethod id.');
      }

      await _payments.doc(paymentId).update({
        'paymentMethodId': paymentMethodId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final confirmation = await stripe.api.confirmPaymentIntent(
        resolvedSecret,
        data: {
          'payment_method': paymentMethodId,
          'return_url': 'https://${_returnUrlScheme}.stripe-redirect',
        },
      );

      final status = _parseStatus(confirmation['status'] as String?);
      final requiresAction = confirmation['status'] == 'requires_action';
      final receiptUrl = confirmation['charges']?['data'] is List &&
              (confirmation['charges']['data'] as List).isNotEmpty
          ? (confirmation['charges']['data'] as List).first['receipt_url']
              as String?
          : null;

      await _payments.doc(paymentId).update({
        'lastPaymentIntentStatus': confirmation['status'],
        'paymentIntentId': confirmation['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return PaymentResult(
        paymentId: paymentId,
        status: status ?? PaymentStatus.processing,
        paymentIntentId: confirmation['id'] as String?,
        receiptUrl: receiptUrl,
        requiresAction: requiresAction,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('PaymentService: Stripe confirmation failed - $error');
        debugPrint(stackTrace.toString());
      }

      await _payments.doc(paymentId).update({
        'lastClientError': error.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return PaymentResult(
        paymentId: paymentId,
        status: PaymentStatus.failed,
        errorMessage: error.toString(),
      );
    }
  }

  /// Emits payment status changes for the provided payment document.
  Stream<PaymentStatus> watchPaymentStatus(String paymentId) {
    return _payments.doc(paymentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      final status = data?['status'] as String?;
      return _parseStatus(status) ?? PaymentStatus.processing;
    });
  }

  static int _toMinorUnits(double amount) {
    return max((amount * 100).round(), 1);
  }

  static PaymentStatus? _parseStatus(String? status) {
    switch (status) {
      case 'requires_payment_method':
        return PaymentStatus.requiresPaymentMethod;
      case 'requires_confirmation':
        return PaymentStatus.requiresConfirmation;
      case 'requires_action':
        return PaymentStatus.requiresAction;
      case 'processing':
        return PaymentStatus.processing;
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'canceled':
        return PaymentStatus.canceled;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return null;
    }
  }

  static Future<String?> _defaultClientSecretResolver(
    DocumentReference<Map<String, dynamic>> doc,
    Duration timeout,
  ) async {
    final completer = Completer<String?>();
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        subscription;

    subscription = doc.snapshots().listen(
      (snapshot) {
        final secret = _extractClientSecret(snapshot.data());
        if (secret != null && secret.isNotEmpty) {
          completer.complete(secret);
          subscription.cancel();
        }
      },
      onError: completer.completeError,
    );

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      await subscription.cancel();
      return null;
    }
  }

  static String? _extractClientSecret(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = [
      data['client_secret'],
      data['clientSecret'],
      data['paymentIntentClientSecret'],
      data['clientSecretKey'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }
}
