import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getPharmacyOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to $newStatus'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders.where((o) => o.status == 'pending').toList();
    final active = _orders.where((o) =>
        o.status == 'confirmed' || o.status == 'preparing').toList();
    final delivery = _orders.where((o) => o.status == 'out_for_delivery').toList();
    final completed = _orders.where((o) =>
        o.status == 'delivered' || o.status == 'cancelled').toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryGreen,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'New (${pending.length})'),
              Tab(text: 'Active (${active.length})'),
              Tab(text: 'Delivery (${delivery.length})'),
              Tab(text: 'Completed (${completed.length})'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(pending, isPending: true),
                      _buildOrderList(active),
                      _buildOrderList(delivery),
                      _buildOrderList(completed),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {bool isPending = false}) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text('No orders', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _PharmacyOrderCard(
            order: order,
            isPending: isPending,
            onAccept: () => _updateStatus(order.id, 'confirmed'),
            onReject: () => _updateStatus(order.id, 'cancelled'),
            onPreparing: () => _updateStatus(order.id, 'preparing'),
            onReady: () => _updateStatus(order.id, 'out_for_delivery'),
          );
        },
      ),
    );
  }
}

class _PharmacyOrderCard extends StatelessWidget {
  final Order order;
  final bool isPending;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onPreparing;
  final VoidCallback onReady;

  const _PharmacyOrderCard({
    required this.order,
    this.isPending = false,
    required this.onAccept,
    required this.onReject,
    required this.onPreparing,
    required this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? AppTheme.accentOrange : AppTheme.divider,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.patientName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    timeago.format(order.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded,
                        size: 14, color: AppTheme.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.medicineName} × ${item.quantity}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )),

          // Prescription indicator
          if (order.prescriptionUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 14, color: AppTheme.secondaryBlue),
                  SizedBox(width: 4),
                  Text(
                    'Prescription attached',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Delivery Address
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Action Buttons
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ] else if (order.status == 'confirmed') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPreparing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue,
                ),
                child: const Text('Start Preparing'),
              ),
            ),
          ] else if (order.status == 'preparing') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReady,
                child: const Text('Ready for Delivery'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
