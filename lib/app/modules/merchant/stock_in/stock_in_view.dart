import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import './stock_in_controller.dart';

class StockInView extends GetView<StockInController> {
  const StockInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item to Shop Stock')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Info Card
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
                          'Add existing inventory items to this shop',
                          style: TextStyle(color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<InventoryItem>(
                initialValue: controller.selectedItem.value,
                hint: const Text('Select an item'),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Inventory Item',
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
                items: controller.masterItems.map((InventoryItem item) {
                  return DropdownMenuItem<InventoryItem>(
                    value: item,
                    child: Text(
                      '${item.name} ${item.sku != null ? "(${item.sku})" : ""}',
                    ),
                  );
                }).toList(),
                onChanged: controller.selectItem,
                validator: (value) => value == null ? 'Item is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: const Icon(Icons.production_quantity_limits),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.addStockToShop,
                  icon: controller.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    controller.isSaving.value ? 'Adding Stock...' : 'Add Stock',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
