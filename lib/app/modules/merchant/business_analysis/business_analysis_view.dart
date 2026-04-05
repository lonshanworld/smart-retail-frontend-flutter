import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/constants/currency.dart';
import 'package:smart_retail/app/modules/merchant/business_analysis/business_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/reports/report_analysis_utils.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class BusinessAnalysisView extends GetView<BusinessAnalysisController> {
  const BusinessAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Business analysis page',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: ${controller.errorMessage.value}'),
            ),
          );
        }

        final snapshot = controller.analysisSnapshot.value;
        if (snapshot == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No analysis data available.'),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            final maxWidth = constraints.maxWidth > 1440
                ? 1360.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(snapshot, isWide),
                      const SizedBox(height: 16),
                      _buildFilterBar(context, isWide),
                      const SizedBox(height: 16),
                      _buildKpiGrid(snapshot),
                      const SizedBox(height: 16),
                      _buildTrendAndMarketing(snapshot, isWide),
                      const SizedBox(height: 16),
                      _buildProductPanels(snapshot, isWide),
                      const SizedBox(height: 16),
                      _buildActionBoard(snapshot),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildHero(BusinessAnalysisSnapshot snapshot, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.merchant.shade900, AppColors.merchant.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business analysis page',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Revenue, profit, product health, and marketing actions for ${DateFormat.yMMMd().format(snapshot.startDate)} - ${DateFormat.yMMMd().format(snapshot.endDate)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _heroChip('Revenue ${_money(snapshot.revenue)}'),
                          _heroChip('Profit ${_money(snapshot.profit)}'),
                          _heroChip(
                            'Margin ${(snapshot.margin * 100).toStringAsFixed(1)}%',
                          ),
                          _heroChip('Unsold ${snapshot.unsoldProductsCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    _heroStatTile('Revenue', _money(snapshot.revenue)),
                    const SizedBox(height: 12),
                    _heroStatTile('Profit', _money(snapshot.profit)),
                    const SizedBox(height: 12),
                    _heroStatTile(
                      'Margin',
                      '${(snapshot.margin * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business analysis page',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revenue, profit, product health, and marketing actions for ${DateFormat.yMMMd().format(snapshot.startDate)} - ${DateFormat.yMMMd().format(snapshot.endDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _heroChip('Revenue ${_money(snapshot.revenue)}'),
                    _heroChip('Profit ${_money(snapshot.profit)}'),
                    _heroChip(
                      'Margin ${(snapshot.margin * 100).toStringAsFixed(1)}%',
                    ),
                    _heroChip('Unsold ${snapshot.unsoldProductsCount}'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroStatTile(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isWide) {
    return _buildFilterPanel(context, isWide);
  }

  Widget _buildFilterPanel(BuildContext context, bool isWide) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
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
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.applyFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh insights'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPeriodDropdown(),
                  const SizedBox(height: 12),
                  Obx(
                    () => controller.selectedPeriod.value == ReportPeriod.custom
                        ? _buildCustomDateRange(context)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _buildShopDropdown(),
                  const SizedBox(height: 12),
                  _buildGroupByDropdown(),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.applyFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh insights'),
                  ),
                ],
              ),
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
            (shop) => DropdownMenuItem(value: shop, child: Text(shop.name)),
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
        final width = constraints.maxWidth;
        final cardWidth = width >= 1200
            ? (width - 50) / 3
            : width >= 760
            ? (width - 24) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard(
              'Revenue',
              _money(snapshot.revenue),
              Icons.payments_outlined,
              Colors.teal,
              cardWidth,
            ),
            _metricCard(
              'Profit',
              _money(snapshot.profit),
              Icons.auto_graph,
              Colors.green,
              cardWidth,
            ),
            _metricCard(
              'Margin',
              '${(snapshot.margin * 100).toStringAsFixed(1)}%',
              Icons.percent,
              Colors.indigo,
              cardWidth,
            ),
            _metricCard(
              'Average order',
              _money(snapshot.averageOrderValue),
              Icons.receipt_long_outlined,
              Colors.blue,
              cardWidth,
            ),
            _metricCard(
              'Active products',
              snapshot.activeProducts.toString(),
              Icons.inventory_2_outlined,
              Colors.orange,
              cardWidth,
            ),
            _metricCard(
              'Low stock risk',
              snapshot.lowStockProductsCount.toString(),
              Icons.warning_amber_outlined,
              Colors.red,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
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

  Widget _buildTrendAndMarketing(
    BusinessAnalysisSnapshot snapshot,
    bool isWide,
  ) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTrendPanel(snapshot)),
          const SizedBox(width: 16),
          Expanded(child: _buildMarketingPanel(snapshot)),
        ],
      );
    }

    return Column(
      children: [
        _buildTrendPanel(snapshot),
        const SizedBox(height: 16),
        _buildMarketingPanel(snapshot),
      ],
    );
  }

  Widget _buildTrendPanel(BusinessAnalysisSnapshot snapshot) {
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
            const SizedBox(height: 12),
            Text(
              '${snapshot.trendGroupingLabel} trend for ${DateFormat.yMMMd().format(snapshot.startDate)} - ${DateFormat.yMMMd().format(snapshot.endDate)}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: snapshot.trendPoints.isEmpty
                  ? const Center(child: Text('No trend data available.'))
                  : LineChart(
                      _trendChart(
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

  LineChartData _trendChart(List<TrendPoint> points, String groupingLabel) {
    final maxY = points.fold<double>(
      0,
      (value, point) => max(value, max(point.revenue, point.profit)),
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
                padding: const EdgeInsets.only(top: 8),
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
          spots: points
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenue))
              .toList(),
          isCurved: true,
          color: Colors.teal,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: points
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.profit))
              .toList(),
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

  Widget _buildMarketingPanel(BusinessAnalysisSnapshot snapshot) {
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
              'Marketing board',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...snapshot.recommendations.map(
              (recommendation) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.merchant.shade100,
                  child: Icon(recommendation.icon, color: AppColors.merchant),
                ),
                title: Text(recommendation.title),
                subtitle: Text(recommendation.detail),
              ),
            ),
            if (snapshot.recommendations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No marketing actions were generated for this range.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPanels(BusinessAnalysisSnapshot snapshot, bool isWide) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildProductTable('Best sellers', snapshot.topProducts),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildProductTable(
              'Slow movers',
              snapshot.slowMovingProducts,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildProductTable('Best sellers', snapshot.topProducts),
        const SizedBox(height: 16),
        _buildProductTable('Slow movers', snapshot.slowMovingProducts),
      ],
    );
  }

  Widget _buildProductTable(String title, List<ProductPerformance> items) {
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
            ResponsiveDataTable<ProductPerformance>(
              items: items,
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
              buildCells: (item) => [
                DataCell(Text(item.name)),
                DataCell(Text(item.unitsSold.toString())),
                DataCell(Text(_money(item.profit))),
                DataCell(Text(item.currentStock.toString())),
              ],
              buildMobileCard: (item) => DataRowCard(
                leading: CircleAvatar(
                  backgroundColor: AppColors.merchant.shade100,
                  child: Icon(
                    Icons.inventory_2,
                    color: AppColors.merchant,
                    size: 20,
                  ),
                ),
                title: item.name,
                subtitle:
                    'Units: ${item.unitsSold} • Stock: ${item.currentStock}',
                details: [
                  DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Revenue',
                    value: _money(item.revenue),
                  ),
                  DetailRow(
                    icon: Icons.trending_up,
                    label: 'Profit',
                    value: _money(item.profit),
                  ),
                  DetailRow(
                    icon: Icons.schedule,
                    label: 'Age',
                    value: '${item.ageDays} days',
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

  Widget _buildActionBoard(BusinessAnalysisSnapshot snapshot) {
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
              'Execution board',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth >= 1200
                    ? (constraints.maxWidth - 36) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _actionTile(
                      'Restock priority',
                      '${snapshot.lowStockProductsCount} items need replenishment',
                      Icons.inventory_outlined,
                      tileWidth,
                    ),
                    _actionTile(
                      'Promotion candidates',
                      '${snapshot.unsoldProductsCount} unsold items can be bundled or discounted',
                      Icons.campaign_outlined,
                      tileWidth,
                    ),
                    _actionTile(
                      'Margin focus',
                      '${(snapshot.margin * 100).toStringAsFixed(1)}% margin across the range',
                      Icons.price_change_outlined,
                      tileWidth,
                    ),
                    _actionTile(
                      'Inventory aging',
                      'Focus on items older than 30 days with low movement',
                      Icons.history_outlined,
                      tileWidth,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    String title,
    String description,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.merchant.shade50,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.merchant.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) => formatCurrency(value);

  String _compactMoney(double value) =>
      '$currencySymbol ${NumberFormat.compact().format(value)}';
}
