import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pharmacy.dart';

class PharmacyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Pharmacy>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 0,
    int limit = 20,
  }) async {
    final data = await _supabase
        .from('pharmacies')
        .select()
        .order('rating', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return (data as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      // Calculate approximate distance (Haversine simplified)
      final dLat = (map['latitude'] as num).toDouble() - latitude;
      final dLng = (map['longitude'] as num).toDouble() - longitude;
      final dist = _approxDistance(latitude, longitude,
          (map['latitude'] as num).toDouble(),
          (map['longitude'] as num).toDouble());
      map['distance'] = dist;
      return Pharmacy.fromJson(map);
    }).where((p) => p.distance <= radius).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  double _approxDistance(double lat1, double lng1, double lat2, double lng2) {
    const kmPerDegLat = 111.0;
    final kmPerDegLng = 111.0 * _cos(lat1);
    final dLat = (lat2 - lat1) * kmPerDegLat;
    final dLng = (lng2 - lng1) * kmPerDegLng;
    return _sqrt(dLat * dLat + dLng * dLng);
  }

  double _cos(double degrees) {
    return _cosTable(degrees);
  }

  static double _cosTable(double deg) {
    // Simple cos approximation
    final rad = deg * 3.14159265 / 180.0;
    return 1.0 - (rad * rad) / 2.0 + (rad * rad * rad * rad) / 24.0;
  }

  static double _sqrt(double val) {
    if (val <= 0) return 0;
    double x = val;
    for (int i = 0; i < 10; i++) {
      x = (x + val / x) / 2.0;
    }
    return x;
  }

  Future<Pharmacy> getPharmacyDetails(String pharmacyId) async {
    final data = await _supabase
        .from('pharmacies')
        .select()
        .eq('id', pharmacyId)
        .single();
    data['distance'] = 0.0;
    return Pharmacy.fromJson(data);
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    final data = await _supabase
        .from('pharmacies')
        .select()
        .ilike('name', '%$query%');
    return (data as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      map['distance'] = 0.0;
      return Pharmacy.fromJson(map);
    }).toList();
  }

  Future<Pharmacy> updatePharmacyProfile(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('pharmacies')
        .update(data)
        .eq('owner_id', userId);

    final updated = await _supabase
        .from('pharmacies')
        .select()
        .eq('owner_id', userId)
        .single();
    updated['distance'] = 0.0;
    return Pharmacy.fromJson(updated);
  }

  Future<void> toggleOpenStatus(bool isOpen) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase
        .from('pharmacies')
        .update({'is_open': isOpen})
        .eq('owner_id', userId);
  }
}
