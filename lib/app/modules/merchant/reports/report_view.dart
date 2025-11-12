import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/report_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import './report_controller.dart';

class ReportView extends GetView<ReportController> {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Forecast Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Obx(() => controller.isLoading.value
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.analytics_outlined)),
              label: const Text('Generate Report'),
              onPressed: controller.isLoading.value ? null : controller.generateReport,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.forecastResponse.value == null) {
                  return const Center(
                    child: Text(
                      'Select a shop and an item, then click \'Generate Report\' to see the forecast.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return _buildReportResult(controller.forecastResponse.value!);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Obx(() => Column(
      children: [
        DropdownButtonFormField<Shop>(
          decoration: const InputDecoration(labelText: 'Select Shop', border: OutlineInputBorder()),
          value: controller.selectedShop.value,
          hint: const Text('Select a shop'),
          isExpanded: true,
          items: controller.shops.map((Shop shop) {
            return DropdownMenuItem<Shop>(value: shop, child: Text(shop.name));
          }).toList(),
          onChanged: (Shop? newValue) {
            controller.selectedShop.value = newValue;
            controller.selectedItem.value = null; // Reset item selection
            controller.inventoryItems.clear();
            if (newValue != null) {
              controller.fetchInventoryItems(); // Fetch items for the new shop
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<InventoryItem>(
          decoration: const InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()),
          value: controller.selectedItem.value,
          hint: const Text('Select an item to forecast'),
          isExpanded: true,
          items: controller.inventoryItems.map((InventoryItem item) {
            return DropdownMenuItem<InventoryItem>(value: item, child: Text(item.name));
          }).toList(),
          onChanged: (InventoryItem? newValue) {
            controller.selectedItem.value = newValue;
          },
        ),
      ],
    ));
  }

  Widget _buildReportResult(SalesForecastResponse report) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(report.reportName, style: Get.textTheme.headlineSmall, textAlign: TextAlign.center),
          Text('For ${report.productName} at ${report.shopName}', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _buildForecastChart(report.dailyForecast),
          ),
          const SizedBox(height: 24),
          _buildAiAnalysisCard(report.aiAnalysis),
        ],
      ),
    );
  }

  Widget _buildForecastChart(List<DailyForecast> forecastData) {
    final spots = forecastData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.predictedQuantity.toDouble());
    }).toList();

    final dateFormat = DateFormat('E, MMM d');

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: forecastData.map((d) => d.predictedQuantity).reduce((a, b) => a > b ? a : b) * 1.2, // Add 20% padding to max Y
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData()), // Corrected: Removed tooltipBgColor
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < forecastData.length) {
                  final date = forecastData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: forecastData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.predictedQuantity.toDouble(),
                color: Colors.teal,
                width: 16,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiAnalysisCard(AiAnalysis analysis) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI-Powered Analysis', style: Get.textTheme.titleLarge),
            const Divider(height: 20),
            Text(analysis.summary, style: Get.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            if (analysis.positiveFactors.isNotEmpty)
              ...[
                const Text('\u{1F44D} Positive Factors', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                ...analysis.positiveFactors.map((factor) => ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: Text(factor, style: const TextStyle(fontSize: 14)))),
              ],
            if (analysis.negativeFactors.isNotEmpty)
              ...[
                const SizedBox(height: 16),
                const Text('\u{1F44E} Negative Factors', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                ...analysis.negativeFactors.map((factor) => ListTile(leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange), title: Text(factor, style: const TextStyle(fontSize: 14)))),
              ],
          ],
        ),
      ),
    );
  }
}
