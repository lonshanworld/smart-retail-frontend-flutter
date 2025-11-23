import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import 'package:smart_retail/app/modules/staff_inventory/staff_inventory_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class StaffInventoryView extends GetView<StaffInventoryController> {
  const StaffInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'Shop Inventory',
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clearSearch,
                ),
              ),
            ),
          ),

          // Inventory List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (controller.filteredItems.isEmpty) {
                return const Center(child: Text('No inventory items found.'));
              }

              return ResponsiveDataTable(
                items: controller.filteredItems,
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
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                buildCells: (item) => [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.staff.shade100,
                          child: Icon(
                            Icons.inventory_2,
                            color: AppColors.staff,
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
                  ),
                  DataCell(Text(item.sku ?? 'N/A')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.quantity > 10
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.quantity > 10
                              ? Colors.green
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          color: item.quantity > 10
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text('Rs ${item.sellingPrice.toStringAsFixed(2)}')),
                ],
                buildMobileCard: (item) => DataRowCard(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.staff.shade100,
                    child: Icon(
                      Icons.inventory_2,
                      color: AppColors.staff,
                      size: 20,
                    ),
                  ),
                  title: item.name,
                  subtitle: item.sku ?? 'N/A',
                  details: [
                    DetailRow(
                      icon: Icons.inventory,
                      label: 'Quantity',
                      value: '${item.quantity}',
                    ),
                    DetailRow(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: 'Rs ${item.sellingPrice.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                headingRowColor: AppColors.staff.shade50,
              );
            }),
          ),
        ],
      ),
    );
  }
}
