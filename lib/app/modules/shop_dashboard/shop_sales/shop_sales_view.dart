import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_sales/shop_sales_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_sales/shop_sales_detail_view.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class ShopSalesView extends GetView<ShopSalesController> {
  const ShopSalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Sales & Transactions',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${controller.errorMessage.value}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (controller.sales.isEmpty) {
                return const Center(
                  child: Text('No sales found for this shop.'),
                );
              }
              return _buildSalesTable();
            }),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSalesTable() {
    return ResponsiveDataTable(
      items: controller.sales,
      columns: _buildColumns(),
      buildCells: (sale) => _buildCells(sale),
      buildMobileCard: (sale) => _buildMobileCard(sale),
      onRowTap: (sale) => _showSaleDetails(sale),
      headingRowColor: AppColors.shop.shade50,
    );
  }

  List<DataColumn> _buildColumns() {
    final isMerchant = controller.isMerchant;

    return [
      DataColumn(
        label: const Text(
          'Date',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: const Text(
          'Items',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: const Text(
          'Sell Price',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      if (isMerchant)
        DataColumn(
          label: const Text(
            'Org Price',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      if (isMerchant)
        DataColumn(
          label: const Text(
            'Profit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      DataColumn(
        label: const Text(
          'Discount',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: const Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  List<DataCell> _buildCells(Sale sale) {
    final isMerchant = controller.isMerchant;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Calculate total selling price
    double totalSellingPrice = sale.items.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );

    // Calculate total original price
    double totalOriginalPrice = sale.items.fold(
      0,
      (sum, item) =>
          sum + ((item.originalPriceAtSale ?? 0.0) * item.quantitySold),
    );

    // Calculate total profit
    double totalProfit = sale.items.fold(0, (sum, item) => sum + item.profit);

    List<DataCell> cells = [
      // Date
      DataCell(
        Text(
          DateFormat.yMd().add_jm().format(sale.saleDate),
          style: const TextStyle(fontSize: 13),
        ),
      ),
      // Items count
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.info.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${sale.items.length} items',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.info.shade700,
            ),
          ),
        ),
      ),
      // Sell Price
      DataCell(
        Text(
          currencyFormat.format(totalSellingPrice),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    ];

    // Add Org Price for merchants only
    if (isMerchant) {
      cells.add(
        DataCell(
          Text(
            currencyFormat.format(totalOriginalPrice),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    // Add Profit for merchants only
    if (isMerchant) {
      cells.add(
        DataCell(
          Text(
            currencyFormat.format(totalProfit),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: totalProfit >= 0
                  ? AppColors.success.shade700
                  : AppColors.error.shade700,
            ),
          ),
        ),
      );
    }

    // Discount
    cells.add(
      DataCell(
        Text(
          sale.discountAmount != null && sale.discountAmount! > 0
              ? currencyFormat.format(sale.discountAmount)
              : '-',
          style: TextStyle(
            fontSize: 13,
            color: (sale.discountAmount != null && sale.discountAmount! > 0)
                ? AppColors.warning.shade700
                : Colors.grey,
          ),
        ),
      ),
    );

    // Total
    cells.add(
      DataCell(
        Text(
          currencyFormat.format(sale.totalAmount),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );

    // Payment Status
    cells.add(
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sale.paymentStatus == 'succeeded'
                ? AppColors.success.shade100
                : AppColors.warning.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            sale.paymentStatus.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: sale.paymentStatus == 'succeeded'
                  ? AppColors.success.shade700
                  : AppColors.warning.shade700,
            ),
          ),
        ),
      ),
    );

    return cells;
  }

  Widget _buildMobileCard(Sale sale) {
    final isMerchant = controller.isMerchant;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Calculate totals
    double totalSellingPrice = sale.items.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );
    double totalOriginalPrice = sale.items.fold(
      0,
      (sum, item) =>
          sum + ((item.originalPriceAtSale ?? 0.0) * item.quantitySold),
    );
    double totalProfit = sale.items.fold(0, (sum, item) => sum + item.profit);

    return DataRowCard(
      leading: CircleAvatar(
        backgroundColor: AppColors.shop.shade100,
        child: Icon(Icons.receipt, color: AppColors.shop.shade700, size: 20),
      ),
      title: 'Sale ${sale.id.substring(0, 8)}',
      subtitle: DateFormat.yMd().add_jm().format(sale.saleDate),
      details: [
        DetailRow(
          icon: Icons.shopping_cart,
          label: 'Items',
          value: '${sale.items.length}',
        ),
        DetailRow(
          icon: Icons.attach_money,
          label: 'Sell Price',
          value: currencyFormat.format(totalSellingPrice),
        ),
        if (isMerchant)
          DetailRow(
            icon: Icons.price_change,
            label: 'Original Price',
            value: currencyFormat.format(totalOriginalPrice),
          ),
        if (isMerchant)
          DetailRow(
            icon: Icons.trending_up,
            label: 'Profit',
            value: currencyFormat.format(totalProfit),
            valueColor: totalProfit >= 0 ? AppColors.success : AppColors.error,
          ),
        if (sale.discountAmount != null && sale.discountAmount! > 0)
          DetailRow(
            icon: Icons.local_offer,
            label: 'Discount',
            value: currencyFormat.format(sale.discountAmount),
            valueColor: AppColors.warning,
          ),
        DetailRow(
          icon: Icons.money,
          label: 'Total',
          value: currencyFormat.format(sale.totalAmount),
          valueFontWeight: FontWeight.bold,
        ),
        DetailRow(
          icon: Icons.check_circle,
          label: 'Payment',
          value: sale.paymentStatus.toUpperCase(),
          valueColor: sale.paymentStatus == 'succeeded'
              ? AppColors.success
              : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Obx(() {
      if (controller.totalPages.value <= 1) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.currentPage.value > 1
                  ? controller.previousPage
                  : null,
            ),
            Text(
              'Page ${controller.currentPage.value} of ${controller.totalPages.value}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  controller.currentPage.value < controller.totalPages.value
                  ? controller.nextPage
                  : null,
            ),
          ],
        ),
      );
    });
  }

  void _showSaleDetails(Sale sale) {
    print(
      '📄 [SHOP SALES VIEW] Navigating to sale details for sale ID: ${sale.id}',
    );
    Get.to(
      () => ShopSalesDetailView(sale: sale),
      transition: Transition.rightToLeft,
    );
  }
}
