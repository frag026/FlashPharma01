import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../models/analytics_data.dart';
import '../../services/analytics_service.dart';

class PharmacyAnalyticsScreen extends StatefulWidget {
  const PharmacyAnalyticsScreen({super.key});

  @override
  State<PharmacyAnalyticsScreen> createState() =>
      _PharmacyAnalyticsScreenState();
}

class _PharmacyAnalyticsScreenState extends State<PharmacyAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _data;
  bool _isLoading = true;
  String _period = 'week';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final data = await _analyticsService.getPharmacyAnalytics(period: _period);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Unable to load analytics'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Analytics',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            _PeriodSelector(
                              selected: _period,
                              onChanged: (p) {
                                setState(() => _period = p);
                                _loadAnalytics();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stats Summary
                        _buildStatsSummary(),
                        const SizedBox(height: 24),

                        // Revenue Summary
                        _buildSectionTitle('Revenue Overview'),
                        const SizedBox(height: 12),
                        _buildRevenueSummary(),
                        const SizedBox(height: 24),

                        // Order Stats Chart
                        _buildSectionTitle('Order Distribution'),
                        const SizedBox(height: 12),
                        _buildOrderPieChart(),
                        const SizedBox(height: 24),

                        // Top Medicines
                        _buildSectionTitle('Top Selling Medicines'),
                        const SizedBox(height: 12),
                        _buildTopMedicines(),
                        const SizedBox(height: 24),

                        // Demand Trends
                        _buildSectionTitle('Demand Trends'),
                        const SizedBox(height: 12),
                        _buildDemandChart(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildStatsSummary() {
    final stats = _data!.orderStats;
    final revenue = _data!.revenueStats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _SummaryCard(
          title: 'Total Orders',
          value: '${stats.totalOrders}',
          icon: Icons.shopping_bag_rounded,
          color: AppTheme.primaryGreen,
        ),
        _SummaryCard(
          title: 'Revenue',
          value: '₹${revenue.totalRevenue.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppTheme.secondaryBlue,
        ),
        _SummaryCard(
          title: 'Completed',
          value: '${stats.completedOrders}',
          icon: Icons.check_circle_rounded,
          color: AppTheme.successGreen,
        ),
        _SummaryCard(
          title: 'Cancelled',
          value: '${stats.cancelledOrders}',
          icon: Icons.cancel_rounded,
          color: AppTheme.errorRed,
        ),
      ],
    );
  }

  Widget _buildRevenueSummary() {
    final revenue = _data!.revenueStats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _RevenueRow(label: 'Today', value: revenue.todayRevenue),
          const Divider(height: 20),
          _RevenueRow(label: 'This Week', value: revenue.weekRevenue),
          const Divider(height: 20),
          _RevenueRow(label: 'This Month', value: revenue.monthRevenue),
          const Divider(height: 20),
          _RevenueRow(label: 'Avg. Order Value', value: revenue.averageOrderValue),
        ],
      ),
    );
  }

  Widget _buildOrderPieChart() {
    final stats = _data!.orderStats;
    final total = stats.totalOrders;
    if (total == 0) return _emptyChart();

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: stats.completedOrders.toDouble(),
        color: AppTheme.successGreen,
        title: '${((stats.completedOrders / total) * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        radius: 50,
      ),
      PieChartSectionData(
        value: stats.pendingOrders.toDouble(),
        color: AppTheme.accentOrange,
        title: '${((stats.pendingOrders / total) * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        radius: 50,
      ),
      PieChartSectionData(
        value: stats.cancelledOrders.toDouble(),
        color: AppTheme.errorRed,
        title: '${((stats.cancelledOrders / total) * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        radius: 50,
      ),
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(child: PieChart(PieChartData(sections: sections))),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(
                  color: AppTheme.successGreen,
                  label: 'Completed (${stats.completedOrders})'),
              const SizedBox(height: 8),
              _LegendItem(
                  color: AppTheme.accentOrange,
                  label: 'Pending (${stats.pendingOrders})'),
              const SizedBox(height: 8),
              _LegendItem(
                  color: AppTheme.errorRed,
                  label: 'Cancelled (${stats.cancelledOrders})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMedicines() {
    final medicines = _data!.topMedicines;
    if (medicines.isEmpty) return _emptyChart();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: List.generate(medicines.length, (i) {
          final med = medicines[i];
          final maxQty =
              medicines.map((m) => m.orderCount).reduce((a, b) => a > b ? a : b);
          return Padding(
            padding: EdgeInsets.only(bottom: i < medicines.length - 1 ? 12 : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.textHint),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.medicineName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxQty > 0 ? med.orderCount / maxQty : 0,
                          backgroundColor: AppTheme.divider,
                          valueColor: AlwaysStoppedAnimation(
                            i == 0
                                ? AppTheme.primaryGreen
                                : i == 1
                                    ? AppTheme.secondaryBlue
                                    : AppTheme.accentOrange,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${med.orderCount} orders',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${med.searchCount} searches',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDemandChart() {
    final trends = _data!.demandTrends;
    if (trends.isEmpty) return _emptyChart();

    final maxDemand =
        trends.map((t) => t.totalOrders.toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            trends.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trends[i].totalOrders.toDouble(),
                  color: AppTheme.secondaryBlue,
                  width: trends.length > 10 ? 8 : 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxDemand > 0 ? (maxDemand / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < trends.length) {
                    final date = trends[idx].date;
                    return Text(
                      date.length > 5
                          ? date.substring(date.length - 5)
                          : date,
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.textHint),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, _) => Text(
                  val.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textHint),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${trends[group.x].date}\n${rod.toY.toStringAsFixed(0)} orders',
                const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyChart() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Text('No data available',
          style: TextStyle(color: AppTheme.textHint)),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final double value;

  const _RevenueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary)),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const periods = ['week', 'month', 'year'];
    const labels = ['7D', '30D', '1Y'];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isSelected = selected == periods[i];
          return GestureDetector(
            onTap: () => onChanged(periods[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
