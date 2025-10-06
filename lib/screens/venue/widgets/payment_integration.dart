import 'package:flutter/material.dart';

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

  bool _isProcessing = false;
  String _selectedPaymentMethod = 'card';

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
        onPressed: _isProcessing ? null : _processPayment,
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

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would integrate with Stripe, PayPal, or other payment providers
      final paymentIntentId = 'pi_${DateTime.now().millisecondsSinceEpoch}';
      
      widget.onPaymentSuccess(paymentIntentId);
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _processWalletPayment(String walletType) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate wallet payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final paymentIntentId = 'pi_${walletType}_${DateTime.now().millisecondsSinceEpoch}';
      
      widget.onPaymentSuccess(paymentIntentId);
    } catch (e) {
      widget.onPaymentError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
