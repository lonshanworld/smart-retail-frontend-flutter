import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/modules/merchant/shop_inventory/shop_inventory_controller.dart';
import 'package:smart_retail/app/widgets/app_drawer.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopInventoryView extends GetView<ShopInventoryController> {
  const ShopInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final shopName =
              controller.selectedShopDetails.value?.name ?? 'Shop Inventory';
          final viewTitle = controller.selectedItemForHistory.value != null
              ? 'History for ${controller.selectedItemForHistory.value!.name}'
              : shopName;
          return Text(viewTitle);
        }),
        actions: [
          Obx(() {
            if (controller.selectedItemForHistory.value != null) {
              return IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.selectedItemForHistory.value = null;
                  controller.stockMovements.clear();
                },
              );
            }
            return Container();
          }),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.selectedItemForHistory.value != null) {
          return _buildStockMovementsView();
        }
        return _buildInventoryListView();
      }),
    );
  }

  Widget _buildInventoryListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Search inventory items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: Obx(
                () => controller.searchTerm.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.onSearchChanged('');
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            onChanged: controller.onSearchChanged,
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingInventory.value &&
                controller.shopInventoryList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.shopInventoryList.isEmpty) {
              return Center(
                child: Text(
                  controller.searchTerm.value.isEmpty
                      ? 'No inventory items found for this shop.'
                      : 'No items match your search.',
                  style: Get.textTheme.titleMedium,
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => controller.fetchShopInventory(showLoading: true),
              child: ResponsiveDataTable<InventoryItem>(
                items: controller.shopInventoryList,
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
                      'Stock',
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
                    onTap: () => _showAdjustStockDialog(item),
                  ),
                  DataCell(
                    Text(item.sku ?? 'No SKU'),
                    onTap: () => _showAdjustStockDialog(item),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (item.stockInfo?.firstOrNull?.quantity ?? 0) > 10
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (item.stockInfo?.firstOrNull?.quantity ?? 0) > 10
                              ? Colors.green
                              : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${item.stockInfo?.firstOrNull?.quantity ?? 0}',
                        style: TextStyle(
                          color:
                              (item.stockInfo?.firstOrNull?.quantity ?? 0) > 10
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => _showAdjustStockDialog(item),
                  ),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'adjust') {
                          _showAdjustStockDialog(item);
                        } else if (value == 'history') {
                          controller.fetchStockMovementsForItem(item);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'adjust',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Adjust Stock'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'history',
                              child: Row(
                                children: [
                                  Icon(Icons.history, size: 20),
                                  SizedBox(width: 8),
                                  Text('View History'),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert),
                    ),
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
                      icon: Icons.inventory,
                      label: 'Stock',
                      value: '${item.stockInfo?.firstOrNull?.quantity ?? 0}',
                    ),
                  ],
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'adjust') {
                        _showAdjustStockDialog(item);
                      } else if (value == 'history') {
                        controller.fetchStockMovementsForItem(item);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'adjust',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Adjust Stock'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'history',
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 20),
                                SizedBox(width: 8),
                                Text('View History'),
                              ],
                            ),
                          ),
                        ],
                    icon: const Icon(Icons.more_vert),
                  ),
                  onTap: () => _showAdjustStockDialog(item),
                ),
                headingRowColor: AppColors.merchant.shade50,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStockMovementsView() {
    return Obx(() {
      if (controller.isLoadingStockMovements.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.stockMovements.isEmpty) {
        return Center(
          child: Text(
            'No stock movement history found for ${controller.selectedItemForHistory.value?.name ?? "this item"}.',
            textAlign: TextAlign.center,
            style: Get.textTheme.titleMedium,
          ),
        );
      }
      return ResponsiveDataTable(
        items: controller.stockMovements,
        columns: const [
          DataColumn(
            label: Text(
              'Movement Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Quantity Changed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'New Qty',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        buildCells: (movement) => [
          DataCell(
            Row(
              children: [
                Icon(
                  movement.quantityChanged > 0
                      ? Icons.add_circle_outline
                      : (movement.quantityChanged < 0
                            ? Icons.remove_circle_outline
                            : Icons.sync),
                  color: movement.quantityChanged > 0
                      ? Colors.green
                      : (movement.quantityChanged < 0
                            ? Colors.red
                            : Colors.grey),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movement.movementType,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: movement.quantityChanged > 0
                    ? Colors.green.shade50
                    : (movement.quantityChanged < 0
                          ? Colors.red.shade50
                          : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${movement.quantityChanged > 0 ? '+' : ''}${movement.quantityChanged}',
                style: TextStyle(
                  color: movement.quantityChanged > 0
                      ? Colors.green.shade700
                      : (movement.quantityChanged < 0
                            ? Colors.red.shade700
                            : Colors.grey.shade700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              '${movement.newQuantity}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(Text(movement.formattedMovementDate)),
          DataCell(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movement.reason != null && movement.reason!.isNotEmpty)
                  Text(
                    movement.reason!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (movement.notes != null && movement.notes!.isNotEmpty)
                  Text(
                    movement.notes!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
        buildMobileCard: (movement) => DataRowCard(
          leading: CircleAvatar(
            backgroundColor: movement.quantityChanged > 0
                ? Colors.green.shade100
                : (movement.quantityChanged < 0
                      ? Colors.red.shade100
                      : Colors.grey.shade100),
            child: Icon(
              movement.quantityChanged > 0
                  ? Icons.add_circle_outline
                  : (movement.quantityChanged < 0
                        ? Icons.remove_circle_outline
                        : Icons.sync),
              color: movement.quantityChanged > 0
                  ? Colors.green
                  : (movement.quantityChanged < 0 ? Colors.red : Colors.grey),
              size: 20,
            ),
          ),
          title: movement.movementType,
          subtitle: movement.formattedMovementDate,
          details: [
            DetailRow(
              icon: Icons.numbers,
              label: 'Change',
              value:
                  '${movement.quantityChanged > 0 ? '+' : ''}${movement.quantityChanged}',
            ),
            DetailRow(
              icon: Icons.inventory,
              label: 'New Qty',
              value: '${movement.newQuantity}',
            ),
            if (movement.reason != null && movement.reason!.isNotEmpty)
              DetailRow(
                icon: Icons.info_outline,
                label: 'Reason',
                value: movement.reason!,
              ),
            if (movement.notes != null && movement.notes!.isNotEmpty)
              DetailRow(
                icon: Icons.note,
                label: 'Notes',
                value: movement.notes!,
              ),
            DetailRow(
              icon: Icons.person,
              label: 'By User',
              value: movement.userId,
            ),
          ],
        ),
        headingRowColor: AppColors.merchant.shade50,
      );
    });
  }

  void _showAdjustStockDialog(InventoryItem item) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    String movementType = 'adjustment';
    final RxInt quantityChange = 0.obs;

    final Map<String, String> movementTypes = {
      'stock_in': 'Stock in',
      'adjustment': 'Stock adjustment',
      'return': 'Return',
    };

    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: Text('Adjust Stock for ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Current Quantity: ${item.stockInfo?.firstOrNull?.quantity ?? 0}',
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: movementType,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Type',
                  border: OutlineInputBorder(),
                ),
                items: movementTypes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    movementType = newValue;
                  }
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity Change (+/-)',
                  hintText: 'e.g., +10 or -5',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  quantityChange.value = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 15),
              Obx(
                () => Text(
                  'New Quantity will be: ${(item.stockInfo?.firstOrNull?.quantity ?? 0) + quantityChange.value}',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          ElevatedButton(
            child: const Text('Adjust'),
            onPressed: () {
              final int qtyChanged = int.tryParse(quantityController.text) ?? 0;
              if (qtyChanged == 0) {
                DialogUtils.showError(
                  'Quantity change cannot be zero.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }
              if (((item.stockInfo?.firstOrNull?.quantity ?? 0) + qtyChanged) <
                      0 &&
                  movementType == 'stock_in') {
                DialogUtils.showError(
                  'Stock quantity cannot go below zero for this adjustment type.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();
              controller.adjustStock(
                item,
                qtyChanged,
                movementType,
                reasonController.text,
              );
            },
          ),
        ],
      ),
    );
  }
}
