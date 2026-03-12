import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_item.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get pharmacy inventory
  Future<List<InventoryItem>> getInventory({
    int page = 0,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();

    var query = _supabase
        .from('inventory')
        .select('*, medicine:medicines(*)')
        .eq('pharmacy_id', pharmacy['id']);

    final data = await query
        .order('updated_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    var items = (data as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Client-side filtering for search & category
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      items = items
          .where((i) =>
              i.medicine.name.toLowerCase().contains(q) ||
              i.medicine.genericName.toLowerCase().contains(q))
          .toList();
    }
    if (category != null && category.isNotEmpty) {
      items = items
          .where((i) => i.medicine.category == category)
          .toList();
    }

    return items;
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();

    // Create or find medicine
    final existingMeds = await _supabase
        .from('medicines')
        .select()
        .ilike('name', medicineName)
        .limit(1);

    String medicineId;
    if ((existingMeds as List).isNotEmpty) {
      medicineId = existingMeds[0]['id'] as String;
    } else {
      final newMed = await _supabase.from('medicines').insert({
        'name': medicineName,
        'generic_name': genericName,
        'manufacturer': manufacturer,
        'category': category,
        'dosage_form': dosageForm,
        'strength': strength,
        'requires_prescription': requiresPrescription,
      }).select().single();
      medicineId = newMed['id'] as String;
    }

    final item = await _supabase.from('inventory').insert({
      'pharmacy_id': pharmacy['id'],
      'medicine_id': medicineId,
      'price': price,
      'quantity': quantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
    }).select('*, medicine:medicines(*)').single();

    return InventoryItem.fromJson(item);
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
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (price != null) data['price'] = price;
    if (quantity != null) data['quantity'] = quantity;
    if (batchNumber != null) data['batch_number'] = batchNumber;
    if (expiryDate != null) {
      data['expiry_date'] = expiryDate.toIso8601String().split('T')[0];
    }
    if (inStock != null) data['in_stock'] = inStock;

    final item = await _supabase
        .from('inventory')
        .update(data)
        .eq('id', itemId)
        .select('*, medicine:medicines(*)')
        .single();

    return InventoryItem.fromJson(item);
  }

  // Delete inventory item
  Future<void> deleteItem(String itemId) async {
    await _supabase.from('inventory').delete().eq('id', itemId);
  }

  // Low stock alerts
  Future<List<InventoryItem>> getLowStockItems({int threshold = 10}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();

    final data = await _supabase
        .from('inventory')
        .select('*, medicine:medicines(*)')
        .eq('pharmacy_id', pharmacy['id'])
        .lte('quantity', threshold)
        .order('quantity');

    return (data as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get expiring items
  Future<List<InventoryItem>> getExpiringItems({int daysAhead = 30}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();

    final futureDate = DateTime.now()
        .add(Duration(days: daysAhead))
        .toIso8601String()
        .split('T')[0];

    final data = await _supabase
        .from('inventory')
        .select('*, medicine:medicines(*)')
        .eq('pharmacy_id', pharmacy['id'])
        .lte('expiry_date', futureDate)
        .order('expiry_date');

    return (data as List<dynamic>)
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
