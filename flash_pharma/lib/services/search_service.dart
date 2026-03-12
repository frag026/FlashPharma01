import '../models/search_result.dart';
import 'api_service.dart';

class SearchService {
  final ApiService _api = ApiService();

  Future<List<SearchResult>> searchMedicines({
    required String query,
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int page = 0,
    int limit = 20,
  }) async {
    final response = await _api.get('/search/medicines', queryParams: {
      'q': query,
      'lat': latitude,
      'lng': longitude,
      'radius': radius,
      'page': page,
      'limit': limit,
    });

    final results = (response['results'] as List<dynamic>)
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return results;
  }

  Future<List<String>> getSuggestions(String query) async {
    final response = await _api.get('/search/suggestions', queryParams: {
      'q': query,
    });
    return (response['suggestions'] as List<dynamic>).cast<String>();
  }

  Future<List<String>> getTrendingSearches() async {
    final response = await _api.get('/search/trending');
    return (response['trending'] as List<dynamic>).cast<String>();
  }

  Future<List<SearchResult>> searchByCategory({
    required String category,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.get('/search/category', queryParams: {
      'category': category,
      'lat': latitude,
      'lng': longitude,
    });
    return (response['results'] as List<dynamic>)
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
