import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/modules/merchant/shop_inventory/merchant_shop_inventory_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantShopInventoryView
    extends GetView<MerchantShopInventoryController> {
  const MerchantShopInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Obx(() {
          final shopName =
              controller.selectedShopDetails.value?.name ?? 'Shop Inventory';
          final viewTitle = controller.selectedItemForHistory.value != null
              ? 'History for ${controller.selectedItemForHistory.value!.name}'
              : shopName;
          return Text(viewTitle);
        }),
        backgroundColor: AppColors.merchant,
        foregroundColor: Colors.white,
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
            return const SizedBox.shrink();
          }),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedItemForHistory.value != null) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () => _showBulkStockInDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add wow Stock'),
          backgroundColor: AppColors.merchant,
        );
      }),
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
        // Shop Info Card
        Obx(() {
          final shop = controller.selectedShopDetails.value;
          if (shop == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.all(16),
            child: ModernCard(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (shop.address != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.address!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Search inventory items...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: AppColors.merchant, width: 2),
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
        const SizedBox(height: 16),

        // Inventory Table
        Expanded(
          child: Obx(() {
            if (controller.isLoadingInventory.value &&
                controller.shopInventoryList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.shopInventoryList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.searchTerm.value.isEmpty
                          ? 'No inventory items found for this shop.'
                          : 'No items match your search.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => controller.fetchShopInventory(showLoading: true),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        'Price',
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showItemDetailsDialog(item),
                    ),
                    DataCell(
                      Text(item.sku ?? 'No SKU'),
                      onTap: () => _showItemDetailsDialog(item),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (item.stockInfo?.firstOrNull?.quantity ?? 0) > 10
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                (item.stockInfo?.firstOrNull?.quantity ?? 0) >
                                    10
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${item.stockInfo?.firstOrNull?.quantity ?? 0}',
                          style: TextStyle(
                            color:
                                (item.stockInfo?.firstOrNull?.quantity ?? 0) >
                                    10
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _showItemDetailsDialog(item),
                    ),
                    DataCell(
                      Text(
                        '\$${item.sellingPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () => _showItemDetailsDialog(item),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'adjust') {
                            _showAdjustStockDialog(item);
                          } else if (value == 'history') {
                            controller.fetchStockMovementsForItem(item);
                          } else if (value == 'details') {
                            _showItemDetailsDialog(item);
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
                              const PopupMenuItem<String>(
                                value: 'details',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text('Details'),
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
                      DetailRow(
                        icon: Icons.attach_money,
                        label: 'Price',
                        value: '\$${item.sellingPrice.toStringAsFixed(2)}',
                      ),
                    ],
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'adjust') {
                          _showAdjustStockDialog(item);
                        } else if (value == 'history') {
                          controller.fetchStockMovementsForItem(item);
                        } else if (value == 'details') {
                          _showItemDetailsDialog(item);
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
                            const PopupMenuItem<String>(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Details'),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert),
                    ),
                    onTap: () => _showItemDetailsDialog(item),
                  ),
                  headingRowColor: AppColors.merchant.shade50,
                ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No stock movement history found for ${controller.selectedItemForHistory.value?.name ?? "this item"}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }
      return Container(
        margin: const EdgeInsets.all(16),
        child: ResponsiveDataTable(
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
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                      movement.movementType
                          .replaceAll('_', ' ')
                          .capitalizeFirst!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
            title: movement.movementType.replaceAll('_', ' ').capitalizeFirst!,
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
        ),
      );
    });
  }

  void _showItemDetailsDialog(InventoryItem item) {
    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: Text(item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.sku != null) ...[
                _buildDetailRow('SKU:', item.sku!),
                const SizedBox(height: 8),
              ],
              _buildDetailRow(
                'Current Stock:',
                '${item.stockInfo?.firstOrNull?.quantity ?? 0}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Selling Price:',
                '\$${item.sellingPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              if (item.originalPrice != null) ...[
                _buildDetailRow(
                  'Original Price:',
                  '\$${item.originalPrice!.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
              ],
              if (item.description != null && item.description!.isNotEmpty) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(item.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _showAdjustStockDialog(item);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Adjust Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchant,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showAdjustStockDialog(InventoryItem item) {
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();
    String movementType = 'inventory_correction';
    final RxInt quantityChange = 0.obs;

    final List<String> movementTypes = [
      'stock_in',
      'inventory_correction',
      'damaged_goods',
      'expired_goods',
      'theft_loss',
      'return_to_supplier',
    ];

    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: Text('Adjust Stock for ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.merchant.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.merchant.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Quantity:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.stockInfo?.firstOrNull?.quantity ?? 0}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.merchant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: movementType,
                decoration: const InputDecoration(
                  labelText: 'Adjustment Type',
                  border: OutlineInputBorder(),
                ),
                items: movementTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value.replaceAll('_', ' ').capitalizeFirst ?? value,
                    ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity Change (+/-)',
                  hintText: 'e.g., +10 or -5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_circle_outline),
                ),
                onChanged: (value) {
                  quantityChange.value = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 15),
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: quantityChange.value >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: quantityChange.value >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Quantity:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(item.stockInfo?.firstOrNull?.quantity ?? 0) + quantityChange.value}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: quantityChange.value >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchant,
              foregroundColor: Colors.white,
            ),
            child: const Text('Adjust'),
            onPressed: () {
              final int qtyChanged = int.tryParse(quantityController.text) ?? 0;
              if (qtyChanged == 0) {
                DialogUtils.showError('Quantity change cannot be zero.');
                return;
              }
              if (((item.stockInfo?.firstOrNull?.quantity ?? 0) + qtyChanged) <
                      0 &&
                  ![
                    'sale',
                    'damaged_goods',
                    'theft_loss',
                    'expired_goods',
                    'return_to_supplier',
                  ].contains(movementType)) {
                DialogUtils.showError('Stock quantity cannot go below zero for this adjustment type.');
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

  void _showBulkStockInDialog() {
    if (controller.selectedShopDetails.value == null) {
      // Recover gracefully when shop list is available but selection has not been bound yet.
      if (controller.shops.isNotEmpty) {
        controller.onShopSelected(controller.shops.first);
      }
      if (controller.selectedShopDetails.value == null) {
        DialogUtils.showError('Please select a shop first');
        return;
      }
    }

    // Fetch all merchant inventory items first
    controller.fetchAllMerchantInventory();

    // Map to track quantity changes for each item (can be positive or negative)
    final RxMap<String, int> quantityChanges = <String, int>{}.obs;
    final RxString searchQuery = ''.obs;
    final TextEditingController searchController = TextEditingController();

    DialogUtils.showCustomDialog(
      dialog: Dialog(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screen = MediaQuery.of(context).size;
            final dialogWidth = screen.width < 700 ? screen.width * 0.94 : 650.0;
            final dialogHeight = (screen.height * 0.88).clamp(480.0, 780.0).toDouble();

            return SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.merchant.shade400,
                      AppColors.merchant.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Shop Stock',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Add items or adjust quantities',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Shop Info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Icon(Icons.store, color: AppColors.merchant, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.selectedShopDetails.value!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: Obx(
                      () => searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                searchQuery.value = '';
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  onChanged: (value) => searchQuery.value = value,
                ),
              ),

              // Changes Summary
              Obx(() {
                final changes = quantityChanges.entries
                    .where((e) => e.value != 0)
                    .toList();
                if (changes.isEmpty) return const SizedBox.shrink();

                final increaseCount = changes.where((e) => e.value > 0).length;
                final decreaseCount = changes.where((e) => e.value < 0).length;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${changes.length} item(s) to update: ${increaseCount > 0 ? '+$increaseCount' : ''} ${decreaseCount > 0 ? '-$decreaseCount' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => quantityChanges.clear(),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Items List
              Expanded(
                child: Obx(() {
                  if (controller.allMerchantInventory.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allItems = controller.allMerchantInventory;
                  final shopItemIds = controller.shopInventoryList
                      .map((item) => item.id)
                      .toSet();

                  final filteredItems = allItems.where((item) {
                    if (searchQuery.value.isEmpty) return true;
                    final query = searchQuery.value.toLowerCase();
                    return item.name.toLowerCase().contains(query) ||
                        (item.sku?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isInShop = shopItemIds.contains(item.id);
                      final currentStock =
                          controller.shopInventoryList
                              .firstWhereOrNull((i) => i.id == item.id)
                              ?.stockInfo
                              ?.firstOrNull
                              ?.quantity ??
                          0;

                      return Obx(() {
                        final change = quantityChanges[item.id] ?? 0;
                        final newStock = currentStock + change;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: change != 0 ? 4 : 1,
                          color: change != 0
                              ? (change > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Item Icon
                                CircleAvatar(
                                  backgroundColor: isInShop
                                      ? AppColors.merchant.shade100
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    isInShop
                                        ? Icons.inventory_2
                                        : Icons.add_shopping_cart,
                                    color: isInShop
                                        ? AppColors.merchant
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (!isInShop)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.orange.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                'NEW',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (isInShop) ...[
                                            Text(
                                              'Stock: $currentStock',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (change != 0) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$newStock',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: change > 0
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ] else
                                            Text(
                                              'Not in shop',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          if (item.sku != null) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              'SKU: ${item.sku}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Quantity Controls
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Decrease button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          final current =
                                              quantityChanges[item.id] ?? 0;
                                          quantityChanges[item.id!] =
                                              current - 1;
                                        },
                                        color: Colors.red,
                                        tooltip: 'Decrease',
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                      ),

                                      // Quantity Display
                                      Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 50,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          change == 0
                                              ? '0'
                                              : (change > 0
                                                    ? '+$change'
                                                    : '$change'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: change == 0
                                                ? Colors.grey.shade700
                                                : (change > 0
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700),
                                          ),
                                        ),
                                      ),

                                      // Increase button
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        onPressed: () {
                                          final current =
                                              quantityChanges[item.id] ?? 0;
                                          quantityChanges[item.id!] =
                                              current + 1;
                                        },
                                        color: Colors.green,
                                        tooltip: 'Increase',
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  );
                }),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    Obx(() {
                      final changes = quantityChanges.entries
                          .where((e) => e.value != 0)
                          .toList();
                      return ElevatedButton.icon(
                        onPressed: changes.isEmpty
                            ? null
                            : () {
                                Get.back();
                                _processStockChanges(quantityChanges);
                              },
                        icon: const Icon(Icons.check),
                        label: Text('Apply Changes (${changes.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.merchant,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          // Avoid inherited infinite minimum width in unconstrained dialog measure passes.
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _processStockChanges(RxMap<String, int> quantityChanges) {
    final changes = quantityChanges.entries.where((e) => e.value != 0).toList();
    if (changes.isEmpty) return;

    // Find the items
    final itemsToProcess = <MapEntry<InventoryItem, int>>[];
    for (final change in changes) {
      final item = controller.allMerchantInventory.firstWhereOrNull(
        (i) => i.id == change.key,
      );
      if (item != null) {
        itemsToProcess.add(MapEntry(item, change.value));
      }
    }

    if (itemsToProcess.isEmpty) return;

    // Show confirmation dialog
    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: const Text('Confirm Stock Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to update stock for ${itemsToProcess.length} item(s):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  children: itemsToProcess.map((entry) {
                    final change = entry.value;
                    final item = entry.key;
                    final currentStock =
                        controller.shopInventoryList
                            .firstWhereOrNull((i) => i.id == item.id)
                            ?.stockInfo
                            ?.firstOrNull
                            ?.quantity ??
                        0;
                    final newStock = currentStock + change;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '$currentStock → $newStock ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: change > 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              change > 0 ? '+$change' : '$change',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: change > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Use the new bulk processing method that handles new items and existing items separately
              controller.processBulkStockChanges(itemsToProcess);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merchant,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
