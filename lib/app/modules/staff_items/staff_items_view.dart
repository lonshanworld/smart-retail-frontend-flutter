import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import 'package:smart_retail/app/modules/staff_items/staff_items_controller.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class StaffItemsView extends GetView<StaffItemsController> {
  const StaffItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return StaffMainScaffold(
      title: 'Shop Products',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterDialog(context),
        child: const Icon(Icons.filter_alt_outlined),
      ),
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

          // Product List
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
                return const Center(child: Text('No products found.'));
              }

              return ResponsiveDataTable(
                items: controller.filteredItems,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Qty',
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
                            Icons.sell_outlined,
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
                  DataCell(
                    Builder(
                      builder: (context) {
                        try {
                          final auth = Get.find<AuthService>();
                          final shopId = auth.shopId.value;
                          int? qty;
                          if (item.stockInfo != null &&
                              item.stockInfo!.isNotEmpty) {
                            final match = item.stockInfo!.firstWhere(
                              (s) => s.shopId == shopId,
                              orElse: () => item.stockInfo!.first,
                            );
                            qty = match.quantity;
                          }
                          return qty != null
                              ? Text(qty.toString())
                              : const Text('-');
                        } catch (e) {
                          return const Text('-');
                        }
                      },
                    ),
                  ),
                  DataCell(Text(item.sku ?? 'N/A')),
                  DataCell(Text(item.category ?? 'Uncategorized')),
                  DataCell(
                    Text(
                      currencyFormatter.format(item.sellingPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.staff,
                      ),
                    ),
                  ),
                ],
                buildMobileCard: (item) => DataRowCard(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.staff.shade100,
                    child: Icon(
                      Icons.sell_outlined,
                      color: AppColors.staff,
                      size: 20,
                    ),
                  ),
                  title: item.name,
                  subtitle: item.sku ?? 'N/A',
                  details: [
                    DetailRow(
                      icon: Icons.inventory_2,
                      label: 'Qty',
                      value: () {
                        try {
                          final auth = Get.find<AuthService>();
                          final shopId = auth.shopId.value;
                          if (item.stockInfo != null &&
                              item.stockInfo!.isNotEmpty) {
                            final match = item.stockInfo!.firstWhere(
                              (s) => s.shopId == shopId,
                              orElse: () => item.stockInfo!.first,
                            );
                            return match.quantity.toString();
                          }
                          return '-';
                        } catch (e) {
                          return '-';
                        }
                      }(),
                    ),
                    DetailRow(
                      icon: Icons.category,
                      label: 'Category',
                      value: item.category ?? 'Uncategorized',
                    ),
                    DetailRow(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: currencyFormatter.format(item.sellingPrice),
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Filter Items'),
          content: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategoryId.value,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: controller.categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: controller.setCategory,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedSubcategoryId.value,
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                  items: controller.subcategories
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      controller.selectedSubcategoryId.value = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: controller.selectedBrandId.value,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  items: controller.brands
                      .map(
                        (b) => DropdownMenuItem<String>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => controller.selectedBrandId.value = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clearFilters();
                Navigator.of(ctx).pop();
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.fetchItems();
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
