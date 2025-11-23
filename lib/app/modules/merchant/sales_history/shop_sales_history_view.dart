import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:smart_retail/app/routes/app_pages.dart'; // New
import './shop_sales_history_controller.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class ShopSalesHistoryView extends GetView<ShopSalesHistoryController> {
  const ShopSalesHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();

    // Listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent -
                  200 && // Load a bit before reaching the absolute end
          !controller.isLoadingMore.value &&
          controller.currentPage.value < controller.totalPages.value) {
        controller.loadMoreSales();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales: ${controller.shopName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshSalesHistory(),
            tooltip: 'Refresh Sales',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.sales.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null && controller.sales.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${controller.errorMessage.value}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () => controller.refreshSalesHistory(),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.sales.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No sales recorded for this shop yet.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshSalesHistory(),
          child: Column(
            children: [
              Expanded(
                child: ResponsiveDataTable<Sale>(
                  items: controller.sales,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Sale ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Items',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Payment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  buildCells: (sale) => [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.merchant.shade100,
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.merchant,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sale.id.substring(0, 8),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: sale.id,
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMd().format(sale.saleDate.toLocal()),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat.jm().format(sale.saleDate.toLocal()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: sale.id,
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.merchant.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${sale.items.length}',
                          style: TextStyle(
                            color: AppColors.merchant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: sale.id,
                      ),
                    ),
                    DataCell(
                      Text(sale.paymentType),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: sale.id,
                      ),
                    ),
                    DataCell(
                      Text(
                        '\$${sale.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: sale.id,
                      ),
                    ),
                  ],
                  buildMobileCard: (sale) => DataRowCard(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.merchant.shade100,
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.merchant,
                        size: 20,
                      ),
                    ),
                    title: 'Sale ${sale.id.substring(0, 8)}',
                    subtitle: DateFormat.yMMMd().add_jm().format(
                      sale.saleDate.toLocal(),
                    ),
                    details: [
                      DetailRow(
                        icon: Icons.shopping_cart,
                        label: 'Items',
                        value: '${sale.items.length}',
                      ),
                      DetailRow(
                        icon: Icons.payment,
                        label: 'Payment',
                        value: sale.paymentType,
                      ),
                      if (sale.notes != null && sale.notes!.isNotEmpty)
                        DetailRow(
                          icon: Icons.note,
                          label: 'Notes',
                          value: sale.notes!,
                        ),
                    ],
                    trailing: Text(
                      '\$${sale.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onTap: () => Get.toNamed(
                      Routes.MERCHANT_SALE_DETAIL,
                      arguments: sale.id,
                    ),
                  ),
                  headingRowColor: AppColors.merchant.shade50,
                ),
              ),
              if (controller.isLoadingMore.value)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      }),
    );
  }
}
