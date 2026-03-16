import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class SalesAnalysisView extends GetView<SalesAnalysisController> {
  const SalesAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Reports', // CORRECTED: Changed String to Text Widget
      body: Column(
        children: [
          _buildFilterBar(context),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Text('Error: ${controller.errorMessage.value}'),
                );
              }
              if (controller.sales.isEmpty) {
                return const Center(
                  child: Text('No sales data found for the selected period.'),
                );
              }
              return _buildSalesDataTable();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8.0),
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

  Widget _buildSalesDataTable() {
    return ResponsiveDataTable<Sale>(
      items: controller.sales,
      columns: const [
        DataColumn(
          label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      buildCells: (sale) => [
        DataCell(
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.merchant.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(DateFormat.yMd().add_jm().format(sale.createdAt)),
              ),
            ],
          ),
          onTap: () => controller.goToSaleDetail(sale),
        ),
        DataCell(
          Text(sale.shopId),
          onTap: () => controller.goToSaleDetail(sale),
        ),
        DataCell(
          Tooltip(
            message: sale.items.map((e) => e.itemName).join(', '),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.merchant.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${sale.items.length} item${sale.items.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: AppColors.merchant.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          onTap: () => controller.goToSaleDetail(sale),
        ),
        DataCell(
          Text(
            '\$${sale.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => controller.goToSaleDetail(sale),
        ),
        DataCell(
          Text(
            '\$${sale.totalProfit.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => controller.goToSaleDetail(sale),
        ),
      ],
      buildMobileCard: (sale) => DataRowCard(
        leading: CircleAvatar(
          backgroundColor: AppColors.merchant.shade100,
          child: Icon(Icons.receipt_long, color: AppColors.merchant, size: 20),
        ),
        title: DateFormat.yMd().add_jm().format(sale.createdAt),
        subtitle: sale.shopId,
        details: [
          DetailRow(
            icon: Icons.shopping_cart,
            label: 'Items',
            value: sale.items.map((e) => e.itemName).join(', '),
          ),
          DetailRow(
            icon: Icons.attach_money,
            label: 'Total',
            value: '\$${sale.totalAmount.toStringAsFixed(2)}',
          ),
          DetailRow(
            icon: Icons.trending_up,
            label: 'Profit',
            value: '\$${sale.totalProfit.toStringAsFixed(2)}',
          ),
        ],
        onTap: () => controller.goToSaleDetail(sale),
      ),
      headingRowColor: AppColors.merchant.shade50,
    );
  }
}
