import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../services/payment_service.dart';

/// Payment integration widget for tournament entry fees
class PaymentIntegration extends StatefulWidget {
  final double amount;
  final Function(String) onPaymentMethodSelected;
  final Function(bool) onPaymentProcessing;

  const PaymentIntegration({
    super.key,
    required this.amount,
    required this.onPaymentMethodSelected,
    required this.onPaymentProcessing,
  });

  @override
  State<PaymentIntegration> createState() => _PaymentIntegrationState();
}

class _PaymentIntegrationState extends State<PaymentIntegration> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  late final PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(12.h),
        _buildPaymentMethods(),
        Gap(16.h),
        _buildPaymentSummary(),
        Gap(16.h),
        _buildPaymentButton(),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: PaymentMethod.values.map((method) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          child: RadioListTile<PaymentMethod>(
            title: Row(
              children: [
                Icon(
                  _getPaymentMethodIcon(method),
                  color: ColorsManager.primary,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  _getPaymentMethodName(method),
                  style: TextStyles.font14DarkBlueMedium,
                ),
              ],
            ),
            subtitle: Text(
              _getPaymentMethodDescription(method),
              style: TextStyles.font12Grey400Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
            ),
            value: method,
            groupValue: _selectedMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMethod = value;
                });
                widget.onPaymentMethodSelected(_generatePaymentMethodId());
              }
            },
            activeColor: ColorsManager.primary,
            contentPadding: EdgeInsets.zero,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorsManager.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entry Fee',
                style: TextStyles.font14DarkBlueMedium,
              ),
              Text(
                '\$${widget.amount.toStringAsFixed(2)}',
                style: TextStyles.font14DarkBlueMedium,
              ),
            ],
          ),
          Gap(8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing Fee',
                style: TextStyles.font14DarkBlueMedium,
              ),
              Text(
                '\$${(widget.amount * 0.029 + 0.30).toStringAsFixed(2)}',
                style: TextStyles.font14DarkBlueMedium,
              ),
            ],
          ),
          Divider(color: ColorsManager.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyles.font16DarkBlueBold,
              ),
              Text(
                '\$${(widget.amount + (widget.amount * 0.029 + 0.30)).toStringAsFixed(2)}',
                style: TextStyles.font16DarkBlueBold.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _processPayment,
        icon: _isProcessing
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.payment),
        label: Text(
          _isProcessing ? 'Processing Payment...' : 'Pay Now',
          style: TextStyles.font16WhiteSemiBold,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorsManager.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.account_balance_wallet;
      case PaymentMethod.applePay:
        return Icons.apple;
      case PaymentMethod.googlePay:
        return Icons.g_mobiledata;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Visa, Mastercard, American Express';
      case PaymentMethod.paypal:
        return 'Pay with your PayPal account';
      case PaymentMethod.applePay:
        return 'Pay with Touch ID or Face ID';
      case PaymentMethod.googlePay:
        return 'Pay with your Google account';
      case PaymentMethod.bankTransfer:
        return 'Direct bank transfer (may take 1-3 days)';
    }
  }

  String _generatePaymentMethodId() {
    // In a real app, this would generate a proper payment method ID
    return '${_selectedMethod.name}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    widget.onPaymentProcessing(true);

    try {
      if (_selectedMethod != PaymentMethod.card &&
          _paymentService.environment == PaymentEnvironment.stripe) {
        throw StateError(
          '${_getPaymentMethodName(_selectedMethod)} is currently unavailable with Stripe. Please select card.',
        );
      }

      PaymentCardDetails? cardDetails;
      if (_selectedMethod == PaymentMethod.card ||
          _paymentService.environment == PaymentEnvironment.stripe) {
        cardDetails = await _collectCardDetails();
        if (cardDetails == null) {
          return;
        }
      }

      final session = await _paymentService.createPaymentIntent(
        PaymentRequest(
          amount: widget.amount,
          currency: 'usd',
          description:
              'Tournament entry fee - ${DateTime.now().toIso8601String()}',
          metadata: {
            'flow': 'tournament_checkout',
            'paymentMethod': _selectedMethod.name,
          },
        ),
      );

      String? clientSecret = session.clientSecret;
      if (!session.isImmediateSuccess && clientSecret == null) {
        clientSecret = await _paymentService.waitForClientSecret(
          session.paymentId,
          timeout: const Duration(seconds: 45),
        );
      }

      final result = await _paymentService.confirmCardPayment(
        paymentId: session.paymentId,
        card: session.mode == PaymentEnvironment.stripe ? cardDetails : null,
        clientSecret: clientSecret,
      );

      if (result.isSuccess) {
        widget.onPaymentMethodSelected(
          result.paymentIntentId ?? session.paymentId,
        );
        _showSnackBar(
          'Payment processed successfully!',
          ColorsManager.success,
        );
      } else if (result.requiresAction) {
        throw StateError(
          'Additional authentication is required to complete this payment.',
        );
      } else {
        throw StateError(
            result.errorMessage ?? 'Payment failed. Please try again.');
      }
    } on TimeoutException {
      _showSnackBar(
        'Timed out waiting for Stripe confirmation.',
        ColorsManager.error,
      );
    } catch (error) {
      _showSnackBar(
        'Payment failed: $error',
        ColorsManager.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        widget.onPaymentProcessing(false);
      }
    }
  }

  Future<PaymentCardDetails?> _collectCardDetails() async {
    final cardController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<PaymentCardDetails>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Card Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Cardholder Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: cardController,
                  decoration: const InputDecoration(labelText: 'Card Number'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 16) {
                      return 'Enter a valid card number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: expiryController,
                  decoration:
                      const InputDecoration(labelText: 'Expiry (MM/YY)'),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter expiry date';
                    }
                    final parts = value.split('/');
                    if (parts.length != 2) {
                      return 'Use MM/YY format';
                    }
                    final month = int.tryParse(parts.first) ?? 0;
                    final year = _normalizeExpiryYear(parts[1]);
                    if (month < 1 || month > 12 || year < DateTime.now().year) {
                      return 'Enter a valid expiry';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: cvcController,
                  decoration: const InputDecoration(labelText: 'CVC'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'Enter a valid CVC';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(
                    context,
                    PaymentCardDetails(
                      number: cardController.text.replaceAll(RegExp(r'\D'), ''),
                      expMonth:
                          int.parse(expiryController.text.split('/').first),
                      expYear: _normalizeExpiryYear(
                        expiryController.text.split('/')[1],
                      ),
                      cvc: cvcController.text.replaceAll(RegExp(r'\D'), ''),
                      name: nameController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    cardController.dispose();
    expiryController.dispose();
    cvcController.dispose();
    nameController.dispose();

    return result;
  }

  int _normalizeExpiryYear(String value) {
    final sanitized = value.trim();
    final parsed = int.tryParse(sanitized);
    if (parsed == null) {
      return 0;
    }
    if (sanitized.length == 2) {
      final currentYear = DateTime.now().year % 100;
      final century = DateTime.now().year - currentYear;
      return parsed + (parsed >= currentYear ? century : century + 100);
    }
    if (sanitized.length == 4) {
      return parsed;
    }
    return 0;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

enum PaymentMethod {
  card,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
}
