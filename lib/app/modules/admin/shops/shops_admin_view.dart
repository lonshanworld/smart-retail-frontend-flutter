import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/admin/shops/admin_shops_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/shared/widgets/centered_message.dart';
import 'package:smart_retail/app/shared/widgets/loading_indicator.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class ShopsAdminView extends GetView<AdminShopsController> {
  const ShopsAdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Admin Manage Shops',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddShopPage,
        icon: const Icon(Icons.add_business),
        label: const Text("Add Shop"),
        backgroundColor: AppColors.admin,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterSection(),
          const SizedBox(height: 16),
          Expanded(child: _buildShopList()),
          const SizedBox(height: 8),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Filters", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10), 
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.nameFilterController, 
                  decoration: InputDecoration(
                    labelText: "Shop Name",
                    hintText: "Filter by name...",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: Obx(() => (controller.nameFilter.value ?? '').isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20), 
                            onPressed: () => controller.onNameSubmittedOrCleared(null), 
                            tooltip: "Clear Name Filter",
                          )
                        : const SizedBox.shrink()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller.merchantIdFilterController, 
                  decoration: InputDecoration(
                    labelText: "Merchant ID",
                    hintText: "Filter by Merchant ID...",
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: Obx(() => (controller.merchantIdFilter.value ?? '').isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20), 
                            onPressed: () => controller.onMerchantIdSubmittedOrCleared(null), 
                            tooltip: "Clear Merchant ID Filter",
                          )
                        : const SizedBox.shrink()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => DropdownButtonFormField<bool?>(
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      value: controller.isActiveFilter.value,
                      hint: const Text("Any Status"),
                      items: const [
                        DropdownMenuItem(value: null, child: Text("Any Status")),
                        DropdownMenuItem(value: true, child: Text("Active")),
                        DropdownMenuItem(value: false, child: Text("Inactive")),
                      ],
                      onChanged: controller.applyIsActiveFilter,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Tooltip(
                  message: "Clear all filters",
                  child: ElevatedButton.icon(
                    onPressed: controller.clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text("Clear"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Get.theme.colorScheme.secondaryContainer, 
                      foregroundColor: Get.theme.colorScheme.onSecondaryContainer, 
                    )
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopList() {
    return Obx(() {
      if (controller.isLoading.value && controller.shops.isEmpty && controller.currentPage.value == 1) {
        return const LoadingIndicator(message: 'Fetching shops...');
      }
      if (controller.errorMessage.value != null && controller.shops.isEmpty) {
        return CenteredMessage(
          message: controller.errorMessage.value!,
          icon: Icons.error_outline,
          onRetry: () => controller.fetchShops(resetPage: true),
        );
      }
      if (controller.shops.isEmpty && !controller.isLoading.value) { 
        return CenteredMessage(
          message: "No shops found matching your criteria.",
          icon: Icons.storefront_outlined,
          onRetry: () => controller.fetchShops(resetPage: true),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchShops(resetPage: true),
        child: ResponsiveDataTable<Shop>(
          items: controller.shops,
          columns: [
            DataColumn(
              label: const Text('Shop', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: const Text('Merchant ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          buildCells: (shop) {
            final isActive = shop.isActive ?? false;
            return [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isActive 
                          ? AppColors.shop.shade100 
                          : Colors.grey.shade200,
                      child: Icon(
                        isActive ? Icons.storefront : Icons.store_mall_directory_outlined,
                        color: isActive 
                            ? AppColors.shop.shade700 
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            shop.id?.substring(0, 8) ?? 'N/A',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () => controller.goToShopDetailsPage(shop),
              ),
              DataCell(
                Text(
                  shop.merchantId.substring(0, 13) + '...',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => controller.goToShopDetailsPage(shop),
              ),
              DataCell(
                Text(
                  shop.address ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: shop.address == null ? FontStyle.italic : null,
                    color: shop.address == null ? Colors.grey : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                onTap: () => controller.goToShopDetailsPage(shop),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.success.shade50 
                        : AppColors.error.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive 
                          ? AppColors.success.shade300 
                          : AppColors.error.shade300,
                    ),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive 
                          ? AppColors.success.shade700 
                          : AppColors.error.shade700,
                    ),
                  ),
                ),
                onTap: () => controller.goToShopDetailsPage(shop),
              ),
              DataCell(_buildActionsMenu(shop)),
            ];
          },
          buildMobileCard: (shop) {
            final isActive = shop.isActive ?? false;
            return DataRowCard(
              leading: CircleAvatar(
                backgroundColor: isActive 
                    ? AppColors.shop.shade100 
                    : Colors.grey.shade200,
                child: Icon(
                  isActive ? Icons.storefront : Icons.store_mall_directory_outlined,
                  color: isActive 
                      ? AppColors.shop.shade700 
                      : Colors.grey.shade600,
                  size: 20,
                ),
              ),
              title: shop.name,
              subtitle: shop.merchantId.substring(0, 20) + '...',
              statusColor: isActive ? AppColors.success : AppColors.error,
              statusText: isActive ? 'Active' : 'Inactive',
              details: [
                if (shop.address != null && shop.address!.isNotEmpty)
                  DetailRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: shop.address!,
                  ),
                DetailRow(
                  icon: Icons.fingerprint,
                  label: 'Shop ID',
                  value: shop.id?.substring(0, 13) ?? 'N/A',
                ),
              ],
              trailing: _buildActionsMenu(shop),
              onTap: () => controller.goToShopDetailsPage(shop),
            );
          },
          headingRowColor: AppColors.admin.shade50,
        ),
      );
    });
  }

  Widget _buildActionsMenu(Shop shop) {
    final isActive = shop.isActive ?? false;
    return PopupMenuButton<String>(
      tooltip: "Actions",
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          controller.goToEditShopPage(shop);
        } else if (value == 'delete') {
          controller.deleteShop(shop.id!, shop.name);
        } else if (value == 'toggle_status') {
          controller.toggleShopStatus(shop);
        } else if (value == 'details') {
          controller.goToShopDetailsPage(shop);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('Edit', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_status',
          child: ListTile(
            leading: Icon(
              isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
              size: 20,
            ),
            title: Text(
              isActive ? 'Deactivate' : 'Activate',
              style: const TextStyle(fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.visibility_outlined, size: 20),
            title: Text('View Details', style: TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red, size: 20),
            title: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Obx(() {
      if (controller.totalPages.value <= 1) return const SizedBox.shrink();
      if (controller.isLoading.value && controller.shops.isEmpty) return const SizedBox.shrink();

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: controller.currentPage.value > 1 ? controller.previousPage : null,
                tooltip: "Previous Page",
              ),
              Flexible(
                child: Text(
                  "Page ${controller.currentPage.value} of ${controller.totalPages.value} (Total: ${controller.totalItems.value})",
                  style: Get.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: controller.currentPage.value < controller.totalPages.value ? controller.nextPage : null,
                tooltip: "Next Page",
              ),
            ],
          ),
        ),
      );
    });
  }
}
