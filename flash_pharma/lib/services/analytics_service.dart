import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_data.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AnalyticsData> getPharmacyAnalytics({
    String period = 'week',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final pharmacy = await _supabase
        .from('pharmacies')
        .select('id')
        .eq('owner_id', userId)
        .single();
    final pharmacyId = pharmacy['id'] as String;

    final now = DateTime.now();
    final startDate = _periodStart(now, period);

    // Get orders for this pharmacy in period
    final orders = await _supabase
        .from('orders')
        .select()
        .eq('pharmacy_id', pharmacyId)
        .gte('created_at', startDate.toIso8601String());

    final orderList = orders as List<dynamic>;
    final completed = orderList.where((o) => o['status'] == 'delivered').length;
    final cancelled = orderList.where((o) => o['status'] == 'cancelled').length;
    final pending = orderList.where((o) => o['status'] == 'pending').length;
    final totalRevenue = orderList
        .where((o) => o['status'] == 'delivered')
        .fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);

    final todayRev = orderList
        .where((o) => o['status'] == 'delivered' && DateTime.parse(o['created_at'] as String).isAfter(todayStart))
        .fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));
    final weekRev = orderList
        .where((o) => o['status'] == 'delivered' && DateTime.parse(o['created_at'] as String).isAfter(weekStart))
        .fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));
    final monthRev = orderList
        .where((o) => o['status'] == 'delivered' && DateTime.parse(o['created_at'] as String).isAfter(monthStart))
        .fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));

    return AnalyticsData(
      topMedicines: [],
      topPharmacies: [],
      demandTrends: [],
      orderStats: OrderStats(
        totalOrders: orderList.length,
        pendingOrders: pending,
        completedOrders: completed,
        cancelledOrders: cancelled,
        fulfillmentRate: orderList.isEmpty ? 0 : completed / orderList.length,
      ),
      revenueStats: RevenueStats(
        totalRevenue: totalRevenue,
        todayRevenue: todayRev,
        weekRevenue: weekRev,
        monthRevenue: monthRev,
        averageOrderValue: completed > 0 ? totalRevenue / completed : 0,
      ),
    );
  }

  Future<AnalyticsData> getAdminAnalytics({
    String period = 'week',
  }) async {
    return getPharmacyAnalytics(period: period);
  }

  Future<List<TopMedicine>> getTopSearchedMedicines({int limit = 10}) async {
    final data = await _supabase
        .from('search_logs')
        .select('query')
        .order('created_at', ascending: false)
        .limit(200);

    final counts = <String, int>{};
    for (final row in (data as List)) {
      final q = (row as Map<String, dynamic>)['query'] as String;
      counts[q] = (counts[q] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => TopMedicine(
      medicineName: e.key,
      searchCount: e.value,
      orderCount: 0,
      category: '',
    )).toList();
  }

  Future<List<DemandTrend>> getDemandTrends({
    required String startDate,
    required String endDate,
  }) async {
    final orders = await _supabase
        .from('orders')
        .select()
        .gte('created_at', startDate)
        .lte('created_at', endDate);

    // Group by date
    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final o in (orders as List)) {
      final map = o as Map<String, dynamic>;
      final date = (map['created_at'] as String).split('T')[0];
      byDate.putIfAbsent(date, () => []).add(map);
    }

    return byDate.entries.map((e) {
      final dayOrders = e.value;
      final rev = dayOrders
          .where((o) => o['status'] == 'delivered')
          .fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));
      return DemandTrend(
        date: e.key,
        totalOrders: dayOrders.length,
        totalSearches: 0,
        revenue: rev,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  DateTime _periodStart(DateTime now, String period) {
    switch (period) {
      case 'day':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }
}
