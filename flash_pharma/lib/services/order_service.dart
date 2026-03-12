import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create order
  Future<Order> createOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? prescriptionUrl,
    String? notes,
    required String paymentMethod,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Get user and pharmacy names
    final profile = await _supabase
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .single();
    final pharmacy = await _supabase
        .from('pharmacies')
        .select('name, delivery_fee')
        .eq('id', pharmacyId)
        .single();

    double subtotal = 0;
    for (final item in items) {
      subtotal += (item['unit_price'] as num) * (item['quantity'] as num);
    }
    final deliveryFee = (pharmacy['delivery_fee'] as num).toDouble();
    final totalAmount = subtotal + deliveryFee;

    final orderData = await _supabase.from('orders').insert({
      'patient_id': userId,
      'patient_name': profile['name'],
      'pharmacy_id': pharmacyId,
      'pharmacy_name': pharmacy['name'],
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'prescription_url': prescriptionUrl,
      'payment_method': paymentMethod,
      'notes': notes,
    }).select().single();

    final orderId = orderData['id'] as String;

    // Insert order items
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'medicine_id': item['medicine_id'],
      'medicine_name': item['medicine_name'],
      'medicine_image_url': item['medicine_image_url'],
      'quantity': item['quantity'],
      'unit_price': item['unit_price'],
      'total_price': (item['unit_price'] as num) * (item['quantity'] as num),
    }).toList();

    await _supabase.from('order_items').insert(orderItems);

    // Fetch complete order with items
    return _fetchOrder(orderId);
  }

  // Get patient orders
  Future<List<Order>> getMyOrders({int page = 0, int limit = 20}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = await _supabase
        .from('orders')
        .select('*, items:order_items(*)')
        .eq('patient_id', userId)
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return (data as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get pharmacy orders
  Future<List<Order>> getPharmacyOrders({
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Get pharmacy owned by this user
    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();

    var query = _supabase
        .from('orders')
        .select('*, items:order_items(*)')
        .eq('pharmacy_id', pharmacy['id']);

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return (data as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get order details
  Future<Order> getOrderDetails(String orderId) async {
    return _fetchOrder(orderId);
  }

  // Update order status (pharmacy)
  Future<Order> updateOrderStatus(String orderId, String status) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == 'delivered') {
      updateData['delivered_at'] = DateTime.now().toIso8601String();
    }

    await _supabase.from('orders').update(updateData).eq('id', orderId);
    return _fetchOrder(orderId);
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _supabase.from('orders').update({
      'status': 'cancelled',
      'notes': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  // Get active order (for tracking)
  Future<Order?> getActiveOrder() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('patient_id', userId)
          .not('status', 'in', '("delivered","cancelled")')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return Order.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // Rate order
  Future<void> rateOrder(String orderId, int rating, String? review) async {
    // Update pharmacy rating based on the order
    final order = await _supabase
        .from('orders')
        .select('pharmacy_id')
        .eq('id', orderId)
        .single();

    final pharmacyId = order['pharmacy_id'] as String;
    final pharmacy = await _supabase
        .from('pharmacies')
        .select('rating, total_ratings')
        .eq('id', pharmacyId)
        .single();

    final totalRatings = (pharmacy['total_ratings'] as int) + 1;
    final currentRating = (pharmacy['rating'] as num).toDouble();
    final newRating =
        ((currentRating * (totalRatings - 1)) + rating) / totalRatings;

    await _supabase.from('pharmacies').update({
      'rating': newRating,
      'total_ratings': totalRatings,
    }).eq('id', pharmacyId);
  }

  Future<Order> _fetchOrder(String orderId) async {
    final data = await _supabase
        .from('orders')
        .select('*, items:order_items(*)')
        .eq('id', orderId)
        .single();
    return Order.fromJson(data);
  }
}
