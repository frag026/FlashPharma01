import '../models/inventory_item.dart';
import 'api_service.dart';

class InventoryService {
  final ApiService _api = ApiService();

  // Get pharmacy inventory
  Future<List<InventoryItem>> getInventory({
    int page = 0,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null) params['search'] = search;
    if (category != null) params['category'] = category;

    final response = await _api.get('/inventory', queryParams: params);
    return (response['items'] as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Add medicine to inventory
  Future<InventoryItem> addItem({
    required String medicineName,
    required String genericName,
    required String manufacturer,
    required String category,
    required String dosageForm,
    required String strength,
    required double price,
    required int quantity,
    required String batchNumber,
    required DateTime expiryDate,
    bool requiresPrescription = false,
  }) async {
    final response = await _api.post('/inventory', data: {
      'medicine_name': medicineName,
      'generic_name': genericName,
      'manufacturer': manufacturer,
      'category': category,
      'dosage_form': dosageForm,
      'strength': strength,
      'price': price,
      'quantity': quantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate.toIso8601String(),
      'requires_prescription': requiresPrescription,
    });
    return InventoryItem.fromJson(response['item'] as Map<String, dynamic>);
  }

  // Update inventory item
  Future<InventoryItem> updateItem(
    String itemId, {
    double? price,
    int? quantity,
    String? batchNumber,
    DateTime? expiryDate,
    bool? inStock,
  }) async {
    final data = <String, dynamic>{};
    if (price != null) data['price'] = price;
    if (quantity != null) data['quantity'] = quantity;
    if (batchNumber != null) data['batch_number'] = batchNumber;
    if (expiryDate != null) data['expiry_date'] = expiryDate.toIso8601String();
    if (inStock != null) data['in_stock'] = inStock;

    final response = await _api.put('/inventory/$itemId', data: data);
    return InventoryItem.fromJson(response['item'] as Map<String, dynamic>);
  }

  // Delete inventory item
  Future<void> deleteItem(String itemId) async {
    await _api.delete('/inventory/$itemId');
  }

  // Low stock alerts
  Future<List<InventoryItem>> getLowStockItems({int threshold = 10}) async {
    final response = await _api.get('/inventory/low-stock', queryParams: {
      'threshold': threshold,
    });
    return (response['items'] as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get expiring items
  Future<List<InventoryItem>> getExpiringItems({int daysAhead = 30}) async {
    final response = await _api.get('/inventory/expiring', queryParams: {
      'days': daysAhead,
    });
    return (response['items'] as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
