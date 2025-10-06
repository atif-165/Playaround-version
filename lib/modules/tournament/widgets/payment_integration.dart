import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

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
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, this would integrate with a payment processor like Stripe
      // For now, we'll just simulate success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processed successfully!'),
            backgroundColor: ColorsManager.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: ColorsManager.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        widget.onPaymentProcessing(false);
      }
    }
  }
}

enum PaymentMethod {
  card,
  paypal,
  applePay,
  googlePay,
  bankTransfer,
}
