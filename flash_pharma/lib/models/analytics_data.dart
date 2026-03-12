class AnalyticsData {
  final List<TopMedicine> topMedicines;
  final List<TopPharmacy> topPharmacies;
  final List<DemandTrend> demandTrends;
  final OrderStats orderStats;
  final RevenueStats revenueStats;

  AnalyticsData({
    required this.topMedicines,
    required this.topPharmacies,
    required this.demandTrends,
    required this.orderStats,
    required this.revenueStats,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      topMedicines: (json['top_medicines'] as List<dynamic>)
          .map((e) => TopMedicine.fromJson(e as Map<String, dynamic>))
          .toList(),
      topPharmacies: (json['top_pharmacies'] as List<dynamic>)
          .map((e) => TopPharmacy.fromJson(e as Map<String, dynamic>))
          .toList(),
      demandTrends: (json['demand_trends'] as List<dynamic>)
          .map((e) => DemandTrend.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderStats: OrderStats.fromJson(json['order_stats'] as Map<String, dynamic>),
      revenueStats:
          RevenueStats.fromJson(json['revenue_stats'] as Map<String, dynamic>),
    );
  }
}

class TopMedicine {
  final String medicineName;
  final int searchCount;
  final int orderCount;
  final String category;

  TopMedicine({
    required this.medicineName,
    required this.searchCount,
    required this.orderCount,
    required this.category,
  });

  factory TopMedicine.fromJson(Map<String, dynamic> json) {
    return TopMedicine(
      medicineName: json['medicine_name'] as String,
      searchCount: json['search_count'] as int,
      orderCount: json['order_count'] as int,
      category: json['category'] as String? ?? '',
    );
  }
}

class TopPharmacy {
  final String pharmacyId;
  final String pharmacyName;
  final int totalOrders;
  final double revenue;
  final double fulfillmentRate;

  TopPharmacy({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.totalOrders,
    required this.revenue,
    required this.fulfillmentRate,
  });

  factory TopPharmacy.fromJson(Map<String, dynamic> json) {
    return TopPharmacy(
      pharmacyId: json['pharmacy_id'] as String,
      pharmacyName: json['pharmacy_name'] as String,
      totalOrders: json['total_orders'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      fulfillmentRate: (json['fulfillment_rate'] as num).toDouble(),
    );
  }
}

class DemandTrend {
  final String date;
  final int totalOrders;
  final int totalSearches;
  final double revenue;

  DemandTrend({
    required this.date,
    required this.totalOrders,
    required this.totalSearches,
    required this.revenue,
  });

  factory DemandTrend.fromJson(Map<String, dynamic> json) {
    return DemandTrend(
      date: json['date'] as String,
      totalOrders: json['total_orders'] as int,
      totalSearches: json['total_searches'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class OrderStats {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double fulfillmentRate;

  OrderStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.fulfillmentRate,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      totalOrders: json['total_orders'] as int,
      pendingOrders: json['pending_orders'] as int,
      completedOrders: json['completed_orders'] as int,
      cancelledOrders: json['cancelled_orders'] as int,
      fulfillmentRate: (json['fulfillment_rate'] as num).toDouble(),
    );
  }
}

class RevenueStats {
  final double totalRevenue;
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double averageOrderValue;

  RevenueStats({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.averageOrderValue,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      todayRevenue: (json['today_revenue'] as num).toDouble(),
      weekRevenue: (json['week_revenue'] as num).toDouble(),
      monthRevenue: (json['month_revenue'] as num).toDouble(),
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
    );
  }
}
