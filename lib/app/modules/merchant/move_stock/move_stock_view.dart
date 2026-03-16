import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import './move_stock_controller.dart';

class MoveStockView extends GetView<MoveStockController> {
  const MoveStockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Move Stock Between Shops'),
        elevation: 2,
      ),
      body: Obx(() {
        if (controller.isLoadingData.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.onInit(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Transfer inventory items between your shops',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Select Item
                _buildSectionTitle('1. Select Item'),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<InventoryItem>(
                    initialValue: controller.selectedItem.value,
                    decoration: InputDecoration(
                      labelText: 'Inventory Item',
                      prefixIcon: const Icon(Icons.inventory_2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                    ),
                    isExpanded: true,
                    hint: const Text('Choose an item to move'),
                    items: controller.inventoryItems.map((item) {
                      return DropdownMenuItem<InventoryItem>(
                        value: item,
                        child: Text(
                          '${item.name} ${item.sku != null ? "(${item.sku})" : ""}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: controller.selectInventoryItem,
                    validator: (value) =>
                        value == null ? 'Please select an item' : null,
                  ),
                ),
                const SizedBox(height: 24),

                // From Shop
                _buildSectionTitle('2. From Shop (Source)'),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<Shop>(
                    initialValue: controller.fromShop.value,
                    decoration: InputDecoration(
                      labelText: 'Source Shop',
                      prefixIcon: const Icon(Icons.store_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                    ),
                    isExpanded: true,
                    hint: const Text('Select source shop'),
                    items: controller.getAvailableFromShops().map((shop) {
                      // Find stock for this shop
                      final stockInfo = controller.selectedItem.value?.stockInfo
                          ?.firstWhereOrNull(
                            (stock) => stock.shopId == shop.id,
                          );
                      final qty = stockInfo?.quantity ?? 0;

                      return DropdownMenuItem<Shop>(
                        value: shop,
                        child: Text(
                          '${shop.name} (Stock: $qty)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: controller.selectedItem.value == null
                        ? null
                        : controller.selectFromShop,
                    validator: (value) =>
                        value == null ? 'Please select source shop' : null,
                  ),
                ),

                // Show available stock
                Obx(() {
                  if (controller.fromShop.value != null &&
                      controller.availableStock.value > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12),
                      child: Text(
                        'Available: ${controller.availableStock.value} units',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 24),

                // To Shop
                _buildSectionTitle('3. To Shop (Destination)'),
                const SizedBox(height: 8),
                Obx(
                  () => DropdownButtonFormField<Shop>(
                    initialValue: controller.toShop.value,
                    decoration: InputDecoration(
                      labelText: 'Destination Shop',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                    ),
                    isExpanded: true,
                    hint: const Text('Select destination shop'),
                    items: controller.getAvailableToShops().map((shop) {
                      return DropdownMenuItem<Shop>(
                        value: shop,
                        child: Text(shop.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: controller.fromShop.value == null
                        ? null
                        : controller.selectToShop,
                    validator: (value) =>
                        value == null ? 'Please select destination shop' : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Quantity
                _buildSectionTitle('4. Quantity to Move'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: const Icon(Icons.production_quantity_limits),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    helperText: 'Enter the number of units to transfer',
                  ),
                  keyboardType: TextInputType.number,
                  validator: controller.validateQuantity,
                ),
                const SizedBox(height: 32),

                // Move Stock Button
                Obx(
                  () => ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.moveStock,
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.swap_horiz),
                    label: Text(
                      controller.isLoading.value
                          ? 'Moving Stock...'
                          : 'Move Stock',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
