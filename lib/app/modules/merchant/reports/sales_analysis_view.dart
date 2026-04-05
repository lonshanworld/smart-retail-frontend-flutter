import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/constants/currency.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import 'package:smart_retail/app/modules/merchant/reports/report_analysis_utils.dart';

class SalesAnalysisView extends GetView<SalesAnalysisController> {
  const SalesAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Reports',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(child: Text('Error: ${controller.errorMessage.value}'));
        }

        final snapshot = controller.analysisSnapshot.value;
        if (snapshot == null) {
          return const Center(
            child: Text('No sales data found for the selected period.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilterBar(context),
              const SizedBox(height: 16),
              _buildKpiGrid(snapshot),
              const SizedBox(height: 16),
              _buildTrendCard(snapshot),
              const SizedBox(height: 16),
              _buildSummaryRow(snapshot),
              const SizedBox(height: 16),
              _buildTopProductsTable(snapshot.topProducts),
              const SizedBox(height: 16),
              _buildInventoryInsights(snapshot),
              const SizedBox(height: 16),
              _buildRecommendations(snapshot.recommendations),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          _buildPeriodDropdown(),
          const SizedBox(width: 16),
          Obx(
            () => controller.selectedPeriod.value == ReportPeriod.custom
                ? _buildCustomDateRange(context)
                : const SizedBox.shrink(),
          ),
          _buildShopDropdown(),
          const SizedBox(width: 16),
          _buildGroupByDropdown(),
        ],
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Obx(
      () => DropdownButton<ReportPeriod>(
        value: controller.selectedPeriod.value,
        onChanged: controller.onPeriodChanged,
        items: const [
          DropdownMenuItem(
            value: ReportPeriod.daily,
            child: Text('Last 24 Hours'),
          ),
          DropdownMenuItem(
            value: ReportPeriod.weekly,
            child: Text('Last 7 Days'),
          ),
          DropdownMenuItem(
            value: ReportPeriod.monthly,
            child: Text('Last 30 Days'),
          ),
          DropdownMenuItem(
            value: ReportPeriod.yearly,
            child: Text('Last Year'),
          ),
          DropdownMenuItem(
            value: ReportPeriod.custom,
            child: Text('Custom Range'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateRange(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => controller.selectCustomDate(context, true),
          child: Obx(
            () => Text(
              'Start: ${controller.customStartDate.value != null ? DateFormat.yMd().format(controller.customStartDate.value!) : 'Select'}',
            ),
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => controller.selectCustomDate(context, false),
          child: Obx(
            () => Text(
              'End: ${controller.customEndDate.value != null ? DateFormat.yMd().format(controller.customEndDate.value!) : 'Select'}',
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildShopDropdown() {
    return Obx(
      () => DropdownButton<Shop?>(
        value: controller.selectedShop.value,
        hint: const Text('All Shops'),
        onChanged: controller.onShopChanged,
        items: [
          const DropdownMenuItem<Shop?>(value: null, child: Text('All Shops')),
          ...controller.shops.map(
            (s) => DropdownMenuItem(value: s, child: Text(s.name)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupByDropdown() {
    return Obx(
      () => DropdownButton<String>(
        value: controller.selectedGroupBy.value,
        onChanged: controller.onGroupByChanged,
        items: const [
          DropdownMenuItem(value: 'daily', child: Text('By Day')),
          DropdownMenuItem(value: 'weekly', child: Text('By Week')),
          DropdownMenuItem(value: 'monthly', child: Text('By Month')),
          DropdownMenuItem(value: 'item', child: Text('By Item')),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BusinessAnalysisSnapshot snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 6
            : constraints.maxWidth > 800
            ? 3
            : 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard(
              'Revenue',
              _money(snapshot.revenue),
              Icons.payments_outlined,
              Colors.teal,
              columns,
            ),
            _metricCard(
              'Profit',
              _money(snapshot.profit),
              Icons.trending_up,
              Colors.green,
              columns,
            ),
            _metricCard(
              'Margin',
              '${(snapshot.margin * 100).toStringAsFixed(1)}%',
              Icons.percent,
              Colors.indigo,
              columns,
            ),
            _metricCard(
              'Orders',
              snapshot.totalSales.toString(),
              Icons.receipt_long_outlined,
              Colors.blue,
              columns,
            ),
            _metricCard(
              'Units sold',
              snapshot.totalUnitsSold.toString(),
              Icons.shopping_cart_outlined,
              Colors.orange,
              columns,
            ),
            _metricCard(
              'Avg order',
              _money(snapshot.averageOrderValue),
              Icons.summarize_outlined,
              Colors.purple,
              columns,
            ),
          ],
        );
      },
    );
  }

  String _money(double value) => formatCurrency(value);

  String _compactMoney(double value) =>
      '$currencySymbol ${NumberFormat.compact().format(value)}';

  Widget _metricCard(
    String label,
    String value,
    IconData icon,
    Color accent,
    int columns,
  ) {
    return Container(
      width: columns == 2 ? double.infinity : 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BusinessAnalysisSnapshot snapshot) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue and profit trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${snapshot.trendGroupingLabel} trend for ${DateFormat.yMMMd().format(snapshot.startDate)} - ${DateFormat.yMMMd().format(snapshot.endDate)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: snapshot.trendPoints.isEmpty
                  ? const Center(child: Text('No trend data for this period.'))
                  : LineChart(
                      _buildTrendChart(
                        snapshot.trendPoints,
                        snapshot.trendGroupingLabel,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildTrendChart(
    List<TrendPoint> points,
    String groupingLabel,
  ) {
    final maxY = max(
      points.fold<double>(0, (value, point) => max(value, point.revenue)),
      points.fold<double>(0, (value, point) => max(value, point.profit)),
    );
    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(
              _compactMoney(value),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: max(1, (points.length / 4).ceil().toDouble()),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _trendAxisLabel(points[index], groupingLabel),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: points.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.revenue);
          }).toList(),
          isCurved: true,
          color: Colors.teal,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: points.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.profit);
          }).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
      minY: 0,
      maxY: maxY <= 0 ? 10 : maxY * 1.2,
    );
  }

  String _trendAxisLabel(TrendPoint point, String groupingLabel) {
    switch (groupingLabel) {
      case 'Week':
        return 'Wk ${DateFormat.MMMd().format(point.date)}';
      case 'Month':
        return DateFormat.yMMM().format(point.date);
      case 'Item':
        return point.label ?? point.date.toIso8601String();
      case 'Day':
      default:
        return DateFormat.Md().format(point.date);
    }
  }

  Widget _buildSummaryRow(BusinessAnalysisSnapshot snapshot) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryChip('Active products', snapshot.activeProducts.toString()),
        _summaryChip('Unsold', snapshot.unsoldProductsCount.toString()),
        _summaryChip(
          'Slow moving',
          snapshot.slowMovingProductsCount.toString(),
        ),
        _summaryChip('Low stock', snapshot.lowStockProductsCount.toString()),
      ],
    );
  }

  Widget _summaryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.merchant.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: AppColors.merchant.shade900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTopProductsTable(List<ProductPerformance> products) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ResponsiveDataTable<ProductPerformance>(
              items: products,
              columns: const [
                DataColumn(
                  label: Text(
                    'Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Units',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Revenue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Profit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Stock',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              buildCells: (product) => [
                DataCell(Text(product.name)),
                DataCell(Text(product.unitsSold.toString())),
                DataCell(Text(_money(product.revenue))),
                DataCell(Text(_money(product.profit))),
                DataCell(Text(product.currentStock.toString())),
              ],
              buildMobileCard: (product) => DataRowCard(
                leading: CircleAvatar(
                  backgroundColor: AppColors.merchant.shade100,
                  child: Icon(
                    Icons.inventory_2,
                    color: AppColors.merchant,
                    size: 20,
                  ),
                ),
                title: product.name,
                subtitle: 'Units sold: ${product.unitsSold}',
                details: [
                  DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Revenue',
                    value: _money(product.revenue),
                  ),
                  DetailRow(
                    icon: Icons.trending_up,
                    label: 'Profit',
                    value: _money(product.profit),
                  ),
                  DetailRow(
                    icon: Icons.warehouse_outlined,
                    label: 'Stock',
                    value: product.currentStock.toString(),
                  ),
                ],
              ),
              headingRowColor: AppColors.merchant.shade50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryInsights(BusinessAnalysisSnapshot snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final unsold = _buildInsightTable(
          'Unsold inventory',
          snapshot.unsoldProducts,
        );
        final slowMovers = _buildInsightTable(
          'Slow movers',
          snapshot.slowMovingProducts,
        );

        if (isNarrow) {
          return Column(
            children: [unsold, const SizedBox(height: 16), slowMovers],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: unsold),
            const SizedBox(width: 16),
            Expanded(child: slowMovers),
          ],
        );
      },
    );
  }

  Widget _buildInsightTable(String title, List<ProductPerformance> items) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No items to show.')),
              )
            else
              Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.merchant.shade100,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.merchant,
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            'Stock ${item.currentStock} • Sold ${item.unitsSold} • Age ${item.ageDays} days',
                          ),
                          trailing: Text(
                            _money(item.profit),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(List<BusinessRecommendation> recommendations) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actionable recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (recommendations.isEmpty)
              const Text('No immediate actions detected from this period.')
            else
              Column(
                children: recommendations
                    .map(
                      (recommendation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.merchant.shade100,
                            child: Icon(
                              recommendation.icon,
                              color: AppColors.merchant,
                            ),
                          ),
                          title: Text(recommendation.title),
                          subtitle: Text(recommendation.detail),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
