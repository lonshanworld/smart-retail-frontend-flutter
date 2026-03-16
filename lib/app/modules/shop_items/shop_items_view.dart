import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/shop_items/shop_items_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class ShopItemsView extends GetView<ShopItemsController> {
  const ShopItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Shop Items',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.inventoryItems.isEmpty) {
          return const Center(child: Text('No items in this shop.'));
        }
        return _buildItemsList();
      }),
    );
  }

  Widget _buildItemsList() {
    final authService = Get.find<AuthService>();
    final isMerchant = authService.user.value?.role == 'merchant';

    return ResponsiveDataTable(
      items: controller.inventoryItems,
      columns: const [
        DataColumn(
          label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      buildCells: (item) => [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.shop.shade100,
                child: Icon(Icons.inventory_2, color: AppColors.shop, size: 20),
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
          onTap: isMerchant
              ? () => controller.showStockAdjustmentDialog(item)
              : null,
        ),
        DataCell(
          Text(item.sku ?? 'No SKU'),
          onTap: isMerchant
              ? () => controller.showStockAdjustmentDialog(item)
              : null,
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          onTap: isMerchant
              ? () => controller.showStockAdjustmentDialog(item)
              : null,
        ),
        DataCell(
          Text('Rs ${item.sellingPrice.toStringAsFixed(2)}'),
          onTap: isMerchant
              ? () => controller.showStockAdjustmentDialog(item)
              : null,
        ),
      ],
      buildMobileCard: (item) => DataRowCard(
        leading: CircleAvatar(
          backgroundColor: AppColors.shop.shade100,
          child: Icon(Icons.inventory_2, color: AppColors.shop, size: 20),
        ),
        title: item.name,
        subtitle: item.sku ?? 'No SKU',
        details: [
          DetailRow(
            icon: Icons.inventory,
            label: 'Stock',
            value: '${item.quantity}',
          ),
          DetailRow(
            icon: Icons.attach_money,
            label: 'Price',
            value: 'Rs ${item.sellingPrice.toStringAsFixed(2)}',
          ),
        ],
        onTap: isMerchant
            ? () => controller.showStockAdjustmentDialog(item)
            : null,
      ),
      headingRowColor: AppColors.shop.shade50,
    );
  }
}
