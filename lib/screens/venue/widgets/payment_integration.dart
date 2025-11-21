import 'dart:async';

import 'package:flutter/material.dart';

import 'package:playaround/services/payment_service.dart';

class PaymentIntegration extends StatefulWidget {
  final double amount;
  final String currency;
  final Function(String) onPaymentSuccess;
  final Function(String) onPaymentError;

  const PaymentIntegration({
    Key? key,
    required this.amount,
    this.currency = 'USD',
    required this.onPaymentSuccess,
    required this.onPaymentError,
  }) : super(key: key);

  @override
  State<PaymentIntegration> createState() => _PaymentIntegrationState();
}

class _PaymentIntegrationState extends State<PaymentIntegration> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  late final PaymentService _paymentService;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        // Payment Method Selection
        _buildPaymentMethodSelection(),
        const SizedBox(height: 16),
        // Payment Form
        if (_selectedPaymentMethod == 'card') _buildCardForm(),
        if (_selectedPaymentMethod == 'wallet') _buildWalletOptions(),
        const SizedBox(height: 24),
        // Payment Summary
        _buildPaymentSummary(),
        const SizedBox(height: 24),
        // Pay Button
        _buildPayButton(),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: [
        _buildPaymentMethodOption(
          'card',
          'Credit/Debit Card',
          Icons.credit_card,
          'Pay with your card',
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodOption(
          'wallet',
          'Digital Wallet',
          Icons.account_balance_wallet,
          'Pay with Apple Pay, Google Pay',
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodOption(
          'bank',
          'Bank Transfer',
          Icons.account_balance,
          'Direct bank transfer',
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              if (value.replaceAll(' ', '').length < 16) {
                return 'Please enter a valid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Expiry and CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Invalid format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cardholder Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'John Doe',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletOptions() {
    return Column(
      children: [
        _buildWalletOption(
          'Apple Pay',
          Icons.apple,
          () => _processWalletPayment('apple_pay'),
        ),
        const SizedBox(height: 8),
        _buildWalletOption(
          'Google Pay',
          Icons.g_mobiledata,
          () => _processWalletPayment('google_pay'),
        ),
        const SizedBox(height: 8),
        _buildWalletOption(
          'PayPal',
          Icons.payment,
          () => _processWalletPayment('paypal'),
        ),
      ],
    );
  }

  Widget _buildWalletOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\$${(widget.amount * 0.9).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (10%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\$${(widget.amount * 0.1).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\$${widget.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _processPayment(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text('Pay \$${widget.amount.toStringAsFixed(2)}'),
      ),
    );
  }

  Future<void> _processPayment({
    String? overrideMethod,
    Map<String, dynamic>? extraMetadata,
  }) async {
    final method = overrideMethod ?? _selectedPaymentMethod;

    if (method == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (method != 'card' &&
          _paymentService.environment == PaymentEnvironment.stripe) {
        throw StateError(
          'The selected payment method is not yet supported in Stripe mode. Please use a card.',
        );
      }

      final metadata = <String, dynamic>{
        'flow': 'venue_booking',
        'paymentMethod': method,
        if (extraMetadata != null) ...extraMetadata,
      };

      final session = await _paymentService.createPaymentIntent(
        PaymentRequest(
          amount: widget.amount,
          currency: widget.currency.toLowerCase(),
          description:
              'Venue booking payment - ${DateTime.now().toIso8601String()}',
          metadata: metadata,
        ),
      );

      String? clientSecret = session.clientSecret;
      if (!session.isImmediateSuccess && clientSecret == null) {
        clientSecret = await _paymentService.waitForClientSecret(
          session.paymentId,
          timeout: const Duration(seconds: 45),
        );
      }

      PaymentResult result;
      if (session.mode == PaymentEnvironment.emulator) {
        result = await _paymentService.confirmCardPayment(
          paymentId: session.paymentId,
          clientSecret: clientSecret,
        );
      } else {
        final cardDetails = method == 'card'
            ? _buildCardDetails()
            : throw StateError(
                'Unsupported payment method $method for Stripe processing',
              );
        result = await _paymentService.confirmCardPayment(
          paymentId: session.paymentId,
          card: cardDetails,
          clientSecret: clientSecret,
        );
      }

      if (result.isSuccess) {
        final paymentIntentId = result.paymentIntentId ??
            session.paymentIntentId ??
            session.paymentId;
        widget.onPaymentSuccess(paymentIntentId);
        _showSnackBar(
          context,
          'Payment successful',
          Theme.of(context).colorScheme.primary,
        );
      } else if (result.requiresAction) {
        widget.onPaymentError(
          result.errorMessage ?? 'Additional authentication required.',
        );
        _showSnackBar(
          context,
          'Payment requires additional authentication. Please follow the prompts in the Stripe dialog.',
          Colors.orange,
        );
      } else {
        throw StateError(
            result.errorMessage ?? 'Payment failed. Please try again.');
      }
    } on TimeoutException {
      widget
          .onPaymentError('Timed out while waiting for payment confirmation.');
      _showSnackBar(
        context,
        'Timed out waiting for payment confirmation.',
        Colors.red,
      );
    } catch (error) {
      widget.onPaymentError(error.toString());
      _showSnackBar(
        context,
        'Payment failed: $error',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processWalletPayment(String walletType) {
    return _processPayment(
      overrideMethod: 'wallet',
      extraMetadata: {'walletType': walletType},
    );
  }

  PaymentCardDetails _buildCardDetails() {
    final number = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final parts = _expiryController.text.split('/');
    final month = parts.isNotEmpty ? int.tryParse(parts.first) ?? 0 : 0;
    final yearRaw = parts.length > 1 ? parts[1].trim() : '';
    final year = _normalizeExpiryYear(yearRaw);
    final cvc = _cvvController.text.replaceAll(RegExp(r'\D'), '');

    if (month < 1 || month > 12 || year < DateTime.now().year) {
      throw const FormatException('Invalid expiry date.');
    }

    if (cvc.length < 3) {
      throw const FormatException('Invalid security code.');
    }

    return PaymentCardDetails(
      number: number,
      expMonth: month,
      expYear: year,
      cvc: cvc,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );
  }

  int _normalizeExpiryYear(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 0;
    }

    if (value.length == 2) {
      final currentYear = DateTime.now().year % 100;
      final century = DateTime.now().year - currentYear;
      return parsed + (parsed >= currentYear ? century : century + 100);
    }

    if (value.length == 4) {
      return parsed;
    }

    return 0;
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
