import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _selectedPayment = 'upi';
  bool _isPlacingOrder = false;
  String? _prescriptionUrl;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'upi', 'label': 'UPI', 'icon': Icons.account_balance_rounded},
    {'id': 'card', 'label': 'Card', 'icon': Icons.credit_card_rounded},
    {'id': 'wallet', 'label': 'Wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'id': 'netbanking', 'label': 'Net Banking', 'icon': Icons.language_rounded},
    {'id': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressController.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final cart = context.read<CartProvider>();
      final user = context.read<AuthProvider>().user;

      await OrderService().createOrder(
        pharmacyId: cart.pharmacyId!,
        items: cart.toOrderItems(),
        deliveryAddress: _addressController.text.trim(),
        deliveryLatitude: user?.latitude ?? 0.0,
        deliveryLongitude: user?.longitude ?? 0.0,
        prescriptionUrl: _prescriptionUrl,
        paymentMethod: _selectedPayment,
      );

      cart.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-success',
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address
            const Text(
              'Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your delivery address',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  // Pharmacy name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_pharmacy_rounded,
                            size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          cart.pharmacyName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.medicineName} x${item.quantity}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(color: AppTheme.textSecondary)),
                            Text('₹${cart.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee',
                                style: TextStyle(color: AppTheme.textSecondary)),
                            Text('₹${cart.deliveryFee.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              '₹${cart.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload Prescription
            const Text(
              'Prescription (if required)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(
                    context, '/upload-prescription');
                if (result is String) {
                  setState(() => _prescriptionUrl = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _prescriptionUrl != null
                        ? AppTheme.successGreen
                        : AppTheme.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _prescriptionUrl != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      color: _prescriptionUrl != null
                          ? AppTheme.successGreen
                          : AppTheme.textHint,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _prescriptionUrl != null
                          ? 'Prescription uploaded'
                          : 'Upload prescription image',
                      style: TextStyle(
                        color: _prescriptionUrl != null
                            ? AppTheme.successGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(_paymentMethods.length, (index) {
              final method = _paymentMethods[index];
              final isSelected = _selectedPayment == method['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  value: method['id'] as String,
                  groupValue: _selectedPayment,
                  onChanged: (v) => setState(() => _selectedPayment = v!),
                  activeColor: AppTheme.primaryGreen,
                  title: Row(
                    children: [
                      Icon(method['icon'] as IconData,
                          size: 20, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Text(method['label'] as String),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Place Order • ₹${cart.total.toStringAsFixed(2)}'),
            ),
          ),
        ),
      ),
    );
  }
}
