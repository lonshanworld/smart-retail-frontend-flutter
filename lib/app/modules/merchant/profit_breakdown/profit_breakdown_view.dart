import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/modules/merchant/profit_breakdown/profit_breakdown_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ProfitBreakdownView extends GetView<ProfitBreakdownController> {
  const ProfitBreakdownView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Profit breakdown',
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

        if (controller.sales.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No sales found for the selected period.'),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            final contentWidth = constraints.maxWidth > 1400
                ? 1320.0
                : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroCard(isWide),
                      const SizedBox(height: 16),
                      _buildFilterPanel(context, isWide),
                      const SizedBox(height: 16),
                      _buildSummaryCards(),
                      const SizedBox(height: 16),
                      ...controller.sales.asMap().entries.map((entry) {
                        final sale = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == controller.sales.length - 1
                                ? 0
                                : 12,
                          ),
                          child: _buildOrderCard(context, sale, isWide),
                        );
                      }),
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

  Widget _buildHeroCard(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.merchant.shade900,
            AppColors.merchant.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profit breakdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Review every sale with revenue, cost, margin, and item-level profit in one place.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _heroMetricCard(
                  'Sales loaded',
                  controller.sales.length.toString(),
                  Icons.receipt_long_outlined,
                ),
                const SizedBox(width: 12),
                _heroMetricCard(
                  'Gross profit',
                  controller.formatMoney(controller.totalGrossProfit),
                  Icons.trending_up_outlined,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profit breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review every sale with revenue, cost, margin, and item-level profit in one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _heroMetricCard(
                        'Sales loaded',
                        controller.sales.length.toString(),
                        Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _heroMetricCard(
                        'Gross profit',
                        controller.formatMoney(controller.totalGrossProfit),
                        Icons.trending_up_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _heroMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
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
                  _periodDropdownCard(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Profit shown here is gross item profit. Tax is not stored in the sale data and delivery is shown separately.',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _periodDropdownCard(),
                  const SizedBox(height: 12),
                  Text(
                    'Profit shown here is gross item profit. Tax is not stored in the sale data and delivery is shown separately.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _periodDropdownCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.merchant.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Obx(
        () => DropdownButton<ProfitPeriod>(
          value: controller.selectedPeriod.value,
          onChanged: controller.onPeriodChanged,
          underline: const SizedBox.shrink(),
          items: ProfitPeriod.values
              .map(
                (period) => DropdownMenuItem(
                  value: period,
                  child: Text('Last ${controller.periodLabel(period)}'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1200
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 760
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard(
              'Orders',
              controller.sales.length.toString(),
              Icons.receipt_long_outlined,
              Colors.blue,
              cardWidth,
            ),
            _summaryCard(
              'Revenue',
              controller.formatMoney(controller.totalRevenue),
              Icons.payments_outlined,
              Colors.teal,
              cardWidth,
            ),
            _summaryCard(
              'Gross profit',
              controller.formatMoney(controller.totalGrossProfit),
              Icons.trending_up_outlined,
              Colors.green,
              cardWidth,
            ),
            _summaryCard(
              'Delivery charges',
              controller.formatMoney(controller.totalDeliveryCharges),
              Icons.local_shipping_outlined,
              Colors.orange,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
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
        borderRadius: BorderRadius.circular(18),
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
            width: 46,
            height: 46,
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

  Widget _buildOrderCard(BuildContext context, Sale sale, bool isWide) {
    final grossProfit = controller.orderGrossProfit(sale);
    final margin = sale.totalAmount <= 0 ? 0.0 : grossProfit / sale.totalAmount;
    final orderTitle =
        'Sale ${sale.id.substring(0, sale.id.length > 8 ? 8 : sale.id.length)}';
    final dateLabel = DateFormat.yMMMd().add_jm().format(
      sale.saleDate.toLocal(),
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        key: PageStorageKey<String>(sale.id),
        initiallyExpanded: controller.focusSaleId == sale.id,
        leading: CircleAvatar(
          backgroundColor: AppColors.merchant.shade100,
          child: Icon(Icons.receipt_long_outlined, color: AppColors.merchant),
        ),
        title: Text(
          orderTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${controller.shopNameFor(sale)} • $dateLabel',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: isWide ? 140 : 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.formatMoney(grossProfit),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${(margin * 100).toStringAsFixed(1)}% margin',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildOrderSummary(sale, grossProfit),
          const SizedBox(height: 12),
          _buildItemBreakdown(sale),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  Get.toNamed(Routes.MERCHANT_SALE_DETAIL, arguments: sale.id),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open sale details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Sale sale, double grossProfit) {
    final itemRevenue = sale.items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _detailChip(
          'Final total',
          controller.formatMoney(sale.totalAmount),
          Colors.teal,
        ),
        _detailChip(
          'Item subtotal',
          controller.formatMoney(itemRevenue),
          Colors.blue,
        ),
        _detailChip(
          'Discount',
          controller.formatMoney(sale.discountAmount ?? 0.0),
          Colors.green,
        ),
        _detailChip(
          'Delivery',
          controller.formatMoney(sale.deliveryCharge),
          Colors.orange,
        ),
        _detailChip(
          'Gross profit',
          controller.formatMoney(grossProfit),
          Colors.deepPurple,
        ),
        _detailChip(
          'Margin',
          '${(sale.totalAmount <= 0 ? 0.0 : (grossProfit / sale.totalAmount) * 100).toStringAsFixed(1)}%',
          Colors.red,
        ),
      ],
    );
  }

  Widget _detailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildItemBreakdown(Sale sale) {
    if (sale.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No items available for this sale.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item profit breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          key: PageStorageKey<String>('profit-breakdown-items-${sale.id}'),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(AppColors.merchant.shade50),
            columns: const [
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Revenue')),
              DataColumn(label: Text('Cost')),
              DataColumn(label: Text('Profit')),
              DataColumn(label: Text('Margin')),
            ],
            rows: sale.items.map((item) {
              final revenue = controller.lineRevenue(item);
              final cost = controller.lineCost(item);
              final profit = controller.lineProfit(item);
              final margin = controller.lineMargin(item) * 100;
              return DataRow(
                cells: [
                  DataCell(Text(item.itemName ?? item.inventoryItemId)),
                  DataCell(Text(item.quantitySold.toString())),
                  DataCell(Text(controller.formatMoney(revenue))),
                  DataCell(Text(controller.formatMoney(cost))),
                  DataCell(Text(controller.formatMoney(profit))),
                  DataCell(Text('${margin.toStringAsFixed(1)}%')),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
