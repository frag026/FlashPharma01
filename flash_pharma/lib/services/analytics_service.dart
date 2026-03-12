import '../models/analytics_data.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _api = ApiService();

  Future<AnalyticsData> getPharmacyAnalytics({
    String period = 'week', // day, week, month, year
  }) async {
    final response = await _api.get('/analytics/pharmacy', queryParams: {
      'period': period,
    });
    return AnalyticsData.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AnalyticsData> getAdminAnalytics({
    String period = 'week',
  }) async {
    final response = await _api.get('/analytics/admin', queryParams: {
      'period': period,
    });
    return AnalyticsData.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<TopMedicine>> getTopSearchedMedicines({int limit = 10}) async {
    final response = await _api.get('/analytics/top-medicines', queryParams: {
      'limit': limit,
    });
    return (response['medicines'] as List<dynamic>)
        .map((e) => TopMedicine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DemandTrend>> getDemandTrends({
    required String startDate,
    required String endDate,
  }) async {
    final response = await _api.get('/analytics/demand-trends', queryParams: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return (response['trends'] as List<dynamic>)
        .map((e) => DemandTrend.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
