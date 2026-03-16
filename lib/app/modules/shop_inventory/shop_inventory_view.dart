import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import './shop_inventory_controller.dart';

class ShopInventoryView extends GetView<ShopInventoryController> {
  const ShopInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();
    final bool isMerchant = authService.user.value?.role == 'merchant';

    return ShopMainScaffold(
      title: 'Shop Inventory',
      floatingActionButton: isMerchant
          ? FloatingActionButton.extended(
              onPressed: controller.goToAddItemToStockPage,
              label: const Text('Add Item to Stock'),
              icon: const Icon(Icons.add),
            )
          : null,
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
          return const Center(
            child: Text('No inventory items found for this shop.'),
          );
        }

        return ResponsiveDataTable(
          items: controller.inventoryItems,
          columns: [
            DataColumn(
              label: const Text(
                'Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'SKU',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'Quantity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          buildCells: (item) {
            return [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.shop.shade100,
                      child: Icon(
                        Icons.inventory_2,
                        color: AppColors.shop.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  item.sku ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: item.sku == null ? FontStyle.italic : null,
                    color: item.sku == null ? Colors.grey : null,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: item.quantity > 10
                        ? AppColors.success.shade50
                        : AppColors.error.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.quantity > 10
                          ? AppColors.success.shade700
                          : AppColors.error.shade700,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '\$${item.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ];
          },
          buildMobileCard: (item) {
            return DataRowCard(
              leading: CircleAvatar(
                backgroundColor: AppColors.shop.shade100,
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.shop.shade700,
                  size: 20,
                ),
              ),
              title: item.name,
              subtitle: item.sku ?? 'No SKU',
              details: [
                DetailRow(
                  icon: Icons.inventory,
                  label: 'Quantity',
                  value: '${item.quantity}',
                  valueColor: item.quantity > 10
                      ? AppColors.success
                      : AppColors.error,
                  valueFontWeight: FontWeight.w600,
                ),
                DetailRow(
                  icon: Icons.attach_money,
                  label: 'Price',
                  value: '\$${item.sellingPrice.toStringAsFixed(2)}',
                ),
              ],
            );
          },
          headingRowColor: AppColors.shop.shade50,
        );
      }),
    );
  }
}
