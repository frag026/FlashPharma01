import '../models/pharmacy.dart';
import 'api_service.dart';

class PharmacyService {
  final ApiService _api = ApiService();

  Future<List<Pharmacy>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 0,
    int limit = 20,
  }) async {
    final response = await _api.get('/pharmacies/nearby', queryParams: {
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'page': page,
      'limit': limit,
    });
    return (response['pharmacies'] as List<dynamic>)
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Pharmacy> getPharmacyDetails(String pharmacyId) async {
    final response = await _api.get('/pharmacies/$pharmacyId');
    return Pharmacy.fromJson(response['pharmacy'] as Map<String, dynamic>);
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    final response = await _api.get('/pharmacies/search', queryParams: {
      'q': query,
    });
    return (response['pharmacies'] as List<dynamic>)
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Update pharmacy profile (pharmacy-side)
  Future<Pharmacy> updatePharmacyProfile(Map<String, dynamic> data) async {
    final response = await _api.put('/pharmacies/profile', data: data);
    return Pharmacy.fromJson(response['pharmacy'] as Map<String, dynamic>);
  }

  // Toggle pharmacy open/close
  Future<void> toggleOpenStatus(bool isOpen) async {
    await _api.patch('/pharmacies/status', data: {'is_open': isOpen});
  }
}
