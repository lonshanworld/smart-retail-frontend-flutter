import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/stocks/merchant_stocks_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class MerchantStocksView extends GetView<MerchantStocksController> {
  const MerchantStocksView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Master Inventory (Stocks)',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddItemPage,
        label: const Text('Add New Item'),
        icon: const Icon(Icons.add),
      ),
      body: Obx(() {
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
        if (controller.inventoryItems.isEmpty) {
          return const Center(child: Text('No master inventory items found.'));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchInventoryItems,
          child: ResponsiveDataTable(
            items: controller.inventoryItems,
            columns: const [
              DataColumn(
                label: Text(
                  'Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'SKU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sell Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Original Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            buildCells: (item) => [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.merchant.shade100,
                      child: Icon(
                        Icons.inventory_2,
                        color: AppColors.merchant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  final result = await Get.toNamed(
                    Routes.MERCHANT_INVENTORY_EDIT,
                    arguments: item,
                  );
                  if (result == true) {
                    controller.fetchInventoryItems();
                  }
                },
              ),
              DataCell(
                Text(item.sku ?? 'No SKU'),
                onTap: () async {
                  final result = await Get.toNamed(
                    Routes.MERCHANT_INVENTORY_EDIT,
                    arguments: item,
                  );
                  if (result == true) {
                    controller.fetchInventoryItems();
                  }
                },
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
                    item.category ?? 'Uncategorized',
                    style: TextStyle(
                      color: AppColors.merchant.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onTap: () async {
                  final result = await Get.toNamed(
                    Routes.MERCHANT_INVENTORY_EDIT,
                    arguments: item,
                  );
                  if (result == true) {
                    controller.fetchInventoryItems();
                  }
                },
              ),
              DataCell(
                Text(
                  '\$${item.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () async {
                  final result = await Get.toNamed(
                    Routes.MERCHANT_INVENTORY_EDIT,
                    arguments: item,
                  );
                  if (result == true) {
                    controller.fetchInventoryItems();
                  }
                },
              ),
              DataCell(
                Text(
                  '\$${item.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                onTap: () async {
                  final result = await Get.toNamed(
                    Routes.MERCHANT_INVENTORY_EDIT,
                    arguments: item,
                  );
                  if (result == true) {
                    controller.fetchInventoryItems();
                  }
                },
              ),
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
              subtitle: item.sku ?? 'No SKU',
              details: [
                DetailRow(
                  icon: Icons.category,
                  label: 'Category',
                  value: item.category ?? 'Uncategorized',
                ),
                DetailRow(
                  icon: Icons.subject,
                  label: 'SubCategory',
                  value: item.subcategoryObj?.name ?? 'Uncategorized',
                ),
                DetailRow(
                  icon: Icons.branding_watermark, 
                  label: 'Brand',
                  value: item.brandObj?.name ?? 'No Brand',
                ),
                DetailRow(
                  icon: Icons.attach_money,
                  label: 'Sell Price',
                  value: '\$${item.sellingPrice.toStringAsFixed(2)}',
                ),
                DetailRow(
                  icon: Icons.money_off,
                  label: 'Original Price',
                  value: '\$${item.originalPrice.toStringAsFixed(2)}',
                ),
              ],
              onTap: () async {
                final result = await Get.toNamed(
                  Routes.MERCHANT_INVENTORY_EDIT,
                  arguments: item,
                );
                if (result == true) {
                  controller.fetchInventoryItems();
                }
              },
            ),
            headingRowColor: AppColors.merchant.shade50,
          ),
        );
      }),
    );
  }
}
