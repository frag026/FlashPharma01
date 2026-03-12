import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final order = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) setState(() { _order = order; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order #${_order!.id.substring(0, 8)}' : 'Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        _buildStatusCard(),
                        const SizedBox(height: 20),

                        // Progress Tracker
                        _buildProgressTracker(),
                        const SizedBox(height: 24),

                        // Map placeholder for delivery tracking
                        if (_order!.status == 'out_for_delivery')
                          _buildDeliveryMap(),

                        // Order Items
                        const Text(
                          'Order Items',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ...(_order!.items.map((item) => _buildOrderItem(item))),
                        const SizedBox(height: 20),

                        // Price Summary
                        _buildPriceSummary(),
                        const SizedBox(height: 20),

                        // Delivery Info
                        _buildDeliveryInfo(),
                        const SizedBox(height: 20),

                        // Cancel Button for active orders
                        if (_order!.isActive && _order!.status == 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _cancelOrder,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.errorRed),
                                foregroundColor: AppTheme.errorRed,
                              ),
                              child: const Text('Cancel Order'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final statusColors = {
      'pending': AppTheme.accentOrange,
      'confirmed': AppTheme.secondaryBlue,
      'preparing': AppTheme.secondaryBlue,
      'out_for_delivery': AppTheme.primaryGreen,
      'delivered': AppTheme.successGreen,
      'cancelled': AppTheme.errorRed,
    };

    final color = statusColors[_order!.status] ?? AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(_order!.status),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.statusDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusSubtext(_order!.status),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    final steps = [
      {'status': 'pending', 'label': 'Placed'},
      {'status': 'confirmed', 'label': 'Confirmed'},
      {'status': 'preparing', 'label': 'Preparing'},
      {'status': 'out_for_delivery', 'label': 'On the way'},
      {'status': 'delivered', 'label': 'Delivered'},
    ];

    final currentIdx = steps.indexWhere((s) => s['status'] == _order!.status);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIdx;
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : AppTheme.divider,
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index]['label']!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                      color: isCompleted ? AppTheme.primaryGreen : AppTheme.textHint,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: index < currentIdx
                        ? AppTheme.primaryGreen
                        : AppTheme.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDeliveryMap() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_rounded,
                size: 48, color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            const Text(
              'Live delivery tracking',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const Text(
              'Powered by Mapbox',
              style: TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication_rounded,
                size: 20, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicineName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', _order!.subtotal),
          const SizedBox(height: 6),
          _priceRow('Delivery Fee', _order!.deliveryFee),
          if (_order!.discount > 0) ...[
            const SizedBox(height: 6),
            _priceRow('Discount', -_order!.discount, isGreen: true),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryGreen,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        Text(
          '${isGreen ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: isGreen ? AppTheme.successGreen : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Details',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_order!.deliveryAddress,
                    style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          if (_order!.deliveryAgentName != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text('Agent: ${_order!.deliveryAgentName}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text('Payment: ${_order!.paymentMethod.toUpperCase()}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text('Ordered ${timeago.format(_order!.createdAt)}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _orderService.cancelOrder(widget.orderId);
        _loadOrder();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to cancel order')),
          );
        }
      }
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_top_rounded;
      case 'confirmed': return Icons.check_circle_outline;
      case 'preparing': return Icons.inventory_2_outlined;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outlined;
    }
  }

  String _statusSubtext(String status) {
    switch (status) {
      case 'pending': return 'Waiting for pharmacy to confirm';
      case 'confirmed': return 'Pharmacy has accepted your order';
      case 'preparing': return 'Your medicines are being packed';
      case 'out_for_delivery': return 'Your order is on its way!';
      case 'delivered': return 'Order delivered successfully';
      case 'cancelled': return 'This order was cancelled';
      default: return '';
    }
  }
}
