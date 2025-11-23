import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_stock_model.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import './shop_stock_controller.dart';

class ShopStockView extends GetView<ShopStockController> {
  const ShopStockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.shopName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight - 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Obx(
                  () => controller.searchText.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => controller.clearSearch(),
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withAlpha(200),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        Widget childWidget;
        if (controller.isLoading.value &&
            controller.filteredShopStockItems.isEmpty &&
            controller.searchText.value.isEmpty &&
            controller.shopStockItems.isEmpty) {
          childWidget = const Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage.value != null &&
            controller.shopStockItems.isEmpty) {
          childWidget = Center(
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
                    onPressed: () => controller.fetchShopStock(),
                  ),
                ],
              ),
            ),
          );
        } else if (controller.shopStockItems.isEmpty &&
            !controller.isLoading.value) {
          childWidget = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shelves, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'This shop has no inventory items yet.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stock in items to see them here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        } else if (controller.filteredShopStockItems.isEmpty &&
            controller.searchText.value.isNotEmpty) {
          childWidget = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No items match "${controller.searchText.value}".',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try a different search term or clear the search.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          childWidget = ResponsiveDataTable<ShopStockItem>(
            items: controller.filteredShopStockItems,
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
                  'Price',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
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
                        Icons.inventory_2_outlined,
                        color: AppColors.merchant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(item.itemSku ?? 'N/A')),
              DataCell(
                Text(
                  '\$${item.itemUnitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: item.quantity > 10
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.quantity > 10 ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: TextStyle(
                      color: item.quantity > 10
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.tune_outlined, size: 16),
                      label: const Text(
                        'Adjust',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => controller.goToAdjustStock(item),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text(
                        'Stock In',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => controller.goToAddStock(item),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        backgroundColor: AppColors.merchant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            buildMobileCard: (item) => DataRowCard(
              leading: CircleAvatar(
                backgroundColor: AppColors.merchant.shade100,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.merchant,
                  size: 20,
                ),
              ),
              title: item.itemName,
              subtitle: item.itemSku ?? 'N/A',
              details: [
                DetailRow(
                  icon: Icons.attach_money,
                  label: 'Price',
                  value: '\$${item.itemUnitPrice.toStringAsFixed(2)}',
                ),
                DetailRow(
                  icon: Icons.inventory,
                  label: 'Quantity',
                  value: '${item.quantity}',
                ),
              ],
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune_outlined, size: 16),
                    label: const Text('Adjust', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.goToAdjustStock(item),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[300]!),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text(
                      'Stock In',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => controller.goToAddStock(item),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      backgroundColor: AppColors.merchant,
                    ),
                  ),
                ],
              ),
            ),
            headingRowColor: AppColors.merchant.shade50,
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchShopStock(),
          child: childWidget,
        );
      }),
    );
  }
}
