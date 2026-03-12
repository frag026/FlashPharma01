import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result.dart';

class SearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<SearchResult>> searchMedicines({
    required String query,
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 0,
    int limit = 20,
  }) async {
    // Log the search
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('search_logs').insert({
      'query': query,
      'user_id': userId,
    });

    // Search medicines
    final medicines = await _supabase
        .from('medicines')
        .select()
        .or('name.ilike.%$query%,generic_name.ilike.%$query%,manufacturer.ilike.%$query%')
        .range(page * limit, (page + 1) * limit - 1);

    final results = <SearchResult>[];
    for (final med in (medicines as List)) {
      final medMap = med as Map<String, dynamic>;
      final medId = medMap['id'] as String;

      // Find pharmacies stocking this medicine
      final stock = await _supabase
          .from('inventory')
          .select('*, pharmacy:pharmacies(*)')
          .eq('medicine_id', medId)
          .eq('in_stock', true);

      final pharmacyStocks = (stock as List).map((s) {
        final sMap = s as Map<String, dynamic>;
        final pMap = sMap['pharmacy'] as Map<String, dynamic>;
        return PharmacyStock(
          pharmacyId: pMap['id'] as String,
          pharmacyName: pMap['name'] as String,
          address: pMap['address'] as String? ?? '',
          latitude: (pMap['latitude'] as num).toDouble(),
          longitude: (pMap['longitude'] as num).toDouble(),
          distance: 0.0,
          price: (sMap['price'] as num).toDouble(),
          quantity: sMap['quantity'] as int? ?? 0,
          inStock: sMap['in_stock'] as bool? ?? true,
          rating: (pMap['rating'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      results.add(SearchResult(
        medicineId: medId,
        medicineName: medMap['name'] as String,
        genericName: medMap['generic_name'] as String? ?? '',
        manufacturer: medMap['manufacturer'] as String? ?? '',
        category: medMap['category'] as String? ?? '',
        imageUrl: medMap['image_url'] as String?,
        requiresPrescription: medMap['requires_prescription'] as bool? ?? false,
        pharmacies: pharmacyStocks,
      ));
    }
    return results;
  }

  Future<List<String>> getSuggestions(String query) async {
    final data = await _supabase
        .from('medicines')
        .select('name')
        .ilike('name', '%$query%')
        .limit(10);

    return (data as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .toList();
  }

  Future<List<String>> getTrendingSearches() async {
    final data = await _supabase
        .from('search_logs')
        .select('query')
        .order('created_at', ascending: false)
        .limit(50);

    // Count occurrences and return top queries
    final counts = <String, int>{};
    for (final row in (data as List)) {
      final q = (row as Map<String, dynamic>)['query'] as String;
      counts[q] = (counts[q] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }

  Future<List<SearchResult>> searchByCategory({
    required String category,
    required double latitude,
    required double longitude,
  }) async {
    return searchMedicines(
      query: category,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
