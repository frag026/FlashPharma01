import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _api = ApiService();

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
    final response = await _api.post('/orders', data: {
      'pharmacy_id': pharmacyId,
      'items': items,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'prescription_url': prescriptionUrl,
      'notes': notes,
      'payment_method': paymentMethod,
    });
    return Order.fromJson(response['order'] as Map<String, dynamic>);
  }

  // Get patient orders
  Future<List<Order>> getMyOrders({int page = 0, int limit = 20}) async {
    final response = await _api.get('/orders/my', queryParams: {
      'page': page,
      'limit': limit,
    });
    return (response['orders'] as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get pharmacy orders
  Future<List<Order>> getPharmacyOrders({
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    final response = await _api.get('/orders/pharmacy', queryParams: params);
    return (response['orders'] as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get order details
  Future<Order> getOrderDetails(String orderId) async {
    final response = await _api.get('/orders/$orderId');
    return Order.fromJson(response['order'] as Map<String, dynamic>);
  }

  // Update order status (pharmacy)
  Future<Order> updateOrderStatus(String orderId, String status) async {
    final response = await _api.patch('/orders/$orderId/status', data: {
      'status': status,
    });
    return Order.fromJson(response['order'] as Map<String, dynamic>);
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _api.post('/orders/$orderId/cancel', data: {
      'reason': reason,
    });
  }

  // Get active order (for tracking)
  Future<Order?> getActiveOrder() async {
    try {
      final response = await _api.get('/orders/active');
      if (response['order'] != null) {
        return Order.fromJson(response['order'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // Rate order
  Future<void> rateOrder(String orderId, int rating, String? review) async {
    await _api.post('/orders/$orderId/rate', data: {
      'rating': rating,
      'review': review,
    });
  }
}
