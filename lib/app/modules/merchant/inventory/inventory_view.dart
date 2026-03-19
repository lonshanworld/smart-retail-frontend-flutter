import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import './inventory_controller.dart';
import "package:flutter/material.dart";
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class InventoryView extends GetView<InventoryController> {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Master Inventory',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Add Item'),
        onPressed: () => Get.toNamed(Routes.MERCHANT_INVENTORY_ADD),
        backgroundColor: AppColors.merchant,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.merchant.shade50.withValues(alpha: 0.3),
              Colors.white,
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value && controller.inventoryItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value != null &&
              controller.inventoryItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${controller.errorMessage.value}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry / Refresh'),
                      onPressed: () => controller.initializeInventory(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (controller.inventoryItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No inventory items found.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Add Your First Item'),
                    onPressed: () => Get.toNamed(Routes.MERCHANT_INVENTORY_ADD),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_outlined, size: 18),
                    label: const Text('Tap to Refresh'),
                    onPressed: () => controller.initializeInventory(),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (controller.isSyncing.value) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue:
                              controller.selectedCategoryFilterId.value,
                          decoration: const InputDecoration(
                            labelText: 'Category filter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All categories'),
                            ),
                            ...controller.categories.map(
                              (category) => DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            ),
                          ],
                          onChanged: controller.setCategoryFilter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue:
                              controller.selectedSubcategoryFilterId.value,
                          decoration: const InputDecoration(
                            labelText: 'Subcategory filter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All subcategories'),
                            ),
                            ...controller.filteredSubcategoriesForFilter.map(
                              (subcategory) => DropdownMenuItem<String>(
                                value: subcategory.id,
                                child: Text(subcategory.name),
                              ),
                            ),
                          ],
                          onChanged:
                              controller.filteredSubcategoriesForFilter.isEmpty
                              ? null
                              : controller.setSubcategoryFilter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: controller.selectedBrandFilterId.value,
                          decoration: const InputDecoration(
                            labelText: 'Brand filter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All brands'),
                            ),
                            ...controller.brands.map(
                              (brand) => DropdownMenuItem<String>(
                                value: brand.id,
                                child: Text(brand.name),
                              ),
                            ),
                          ],
                          onChanged: controller.setBrandFilter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.initializeInventory(),
                  child: ResponsiveDataTable<InventoryItem>(
                    items: controller.visibleInventoryItems,
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
                          'Status',
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
                              backgroundColor: item.isArchived
                                  ? Colors.grey
                                  : (item.needsCreate || item.needsUpdate
                                        ? Colors.orange.shade100
                                        : AppColors.merchant.shade100),
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: item.isArchived
                                      ? Colors.white
                                      : AppColors.merchant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: item.isArchived
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => Get.toNamed(
                          Routes.MERCHANT_INVENTORY_EDIT,
                          arguments: item,
                        ),
                      ),
                      DataCell(
                        Text(item.sku ?? 'N/A'),
                        onTap: () => Get.toNamed(
                          Routes.MERCHANT_INVENTORY_EDIT,
                          arguments: item,
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$${item.sellingPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () => Get.toNamed(
                          Routes.MERCHANT_INVENTORY_EDIT,
                          arguments: item,
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: !item.isSynced
                                ? Colors.orange.shade50
                                : (item.isArchived
                                      ? Colors.grey.shade200
                                      : Colors.green.shade50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            !item.isSynced
                                ? (item.needsCreate ? 'New' : 'Modified')
                                : (item.isArchived ? 'Archived' : 'Synced'),
                            style: TextStyle(
                              color: !item.isSynced
                                  ? Colors.orange.shade700
                                  : (item.isArchived
                                        ? Colors.grey.shade700
                                        : Colors.green.shade700),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () => Get.toNamed(
                          Routes.MERCHANT_INVENTORY_EDIT,
                          arguments: item,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.isArchived)
                              IconButton(
                                icon: const Icon(
                                  Icons.unarchive_outlined,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                tooltip: 'Unarchive',
                                onPressed: () =>
                                    controller.unarchiveInventoryItem(item.id!),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.archive_outlined,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                tooltip: 'Archive',
                                onPressed: () =>
                                    controller.archiveInventoryItem(item.id!),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: AppColors.merchant,
                                size: 20,
                              ),
                              tooltip: 'Edit',
                              onPressed: () => Get.toNamed(
                                Routes.MERCHANT_INVENTORY_EDIT,
                                arguments: item,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  controller.checkAndDeleteItemFromList(item),
                            ),
                          ],
                        ),
                      ),
                    ],
                    buildMobileCard: (item) => DataRowCard(
                      leading: CircleAvatar(
                        backgroundColor: item.isArchived
                            ? Colors.grey
                            : (item.needsCreate || item.needsUpdate
                                  ? Colors.orange.shade100
                                  : AppColors.merchant.shade100),
                        child: Text(
                          item.name.isNotEmpty
                              ? item.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: item.isArchived
                                ? Colors.white
                                : AppColors.merchant,
                          ),
                        ),
                      ),
                      title: item.name,
                      subtitle: item.sku ?? 'N/A',
                      details: [
                        DetailRow(
                          icon: Icons.attach_money,
                          label: 'Price',
                          value: '\$${item.sellingPrice.toStringAsFixed(2)}',
                        ),
                        DetailRow(
                          icon: Icons.sync,
                          label: 'Status',
                          value: !item.isSynced
                              ? (item.needsCreate
                                    ? 'New (Local)'
                                    : 'Modified (Local)')
                              : (item.isArchived ? 'Archived' : 'Synced'),
                        ),
                      ],
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.isArchived)
                            IconButton(
                              icon: const Icon(
                                Icons.unarchive_outlined,
                                color: Colors.green,
                                size: 24,
                              ),
                              onPressed: () =>
                                  controller.unarchiveInventoryItem(item.id!),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.archive_outlined,
                                color: Colors.orange,
                                size: 24,
                              ),
                              onPressed: () =>
                                  controller.archiveInventoryItem(item.id!),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppColors.merchant,
                              size: 24,
                            ),
                            onPressed: () => Get.toNamed(
                              Routes.MERCHANT_INVENTORY_EDIT,
                              arguments: item,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                            onPressed: () =>
                                controller.checkAndDeleteItemFromList(item),
                          ),
                        ],
                      ),
                      onTap: () => Get.toNamed(
                        Routes.MERCHANT_INVENTORY_EDIT,
                        arguments: item,
                      ),
                    ),
                    headingRowColor: AppColors.merchant.shade50,
                  ),
                ),
              ),
              if (controller.isFetchingPage.value)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              _buildPaginationControls(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Obx(() {
      if (controller.totalPagesFromApi.value <= 1 &&
          !controller.isFetchingPage.value) {
        return const SizedBox.shrink(); // No controls if only one page or less
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page_outlined),
              onPressed: controller.currentPage.value > 1
                  ? () => controller.jumpToPage(1)
                  : null,
              tooltip: 'First Page',
            ),
            IconButton(
              icon: const Icon(Icons.navigate_before_outlined),
              onPressed: controller.currentPage.value > 1
                  ? controller.goToPreviousPage
                  : null,
              tooltip: 'Previous Page',
            ),
            Flexible(
              child: Text(
                'Page ${controller.currentPage.value} of ${controller.totalPagesFromApi.value}',
                style: Get.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next_outlined),
              onPressed:
                  controller.currentPage.value <
                      controller.totalPagesFromApi.value
                  ? controller.goToNextPage
                  : null,
              tooltip: 'Next Page',
            ),
            IconButton(
              icon: const Icon(Icons.last_page_outlined),
              onPressed:
                  controller.currentPage.value <
                      controller.totalPagesFromApi.value
                  ? () => controller.jumpToPage(
                      controller.totalPagesFromApi.value,
                    )
                  : null,
              tooltip: 'Last Page',
            ),
          ],
        ),
      );
    });
  }
}
