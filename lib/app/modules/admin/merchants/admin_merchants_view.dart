// lib/app/modules/admin/merchants/admin_merchants_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/merchant_model.dart';
import 'package:smart_retail/app/modules/admin/merchants/admin_merchants_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/shared/widgets/centered_message.dart';
import 'package:smart_retail/app/shared/widgets/loading_indicator.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class AdminMerchantsView extends GetView<AdminMerchantsController> {
  const AdminMerchantsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Manage Merchant Users',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddMerchantPage,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add Merchant User"),
        backgroundColor: AppColors.admin,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterSection(),
          const SizedBox(height: 16),
          Expanded(child: _buildMerchantList()),
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
          Text(
            "Filters",
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.nameFilterController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    hintText: "Filter by name...",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onFieldSubmitted: (_) => controller.applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller.emailFilterController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "Filter by email...",
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) => controller.applyFilters(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => DropdownButtonFormField<bool?>(
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              initialValue: controller.isActiveFilter.value,
              hint: const Text("Any Status"),
              items: const [
                DropdownMenuItem(value: null, child: Text("Any Status")),
                DropdownMenuItem(value: true, child: Text("Active")),
                DropdownMenuItem(value: false, child: Text("Inactive")),
              ],
              onChanged: controller.applyIsActiveFilter,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text("Clear"),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: controller.applyFilters,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantList() {
    return Obx(() {
      if (controller.isLoading.value &&
          controller.merchants.isEmpty &&
          controller.currentPage.value == 1) {
        return const LoadingIndicator(message: 'Fetching merchant users...');
      }
      if (controller.errorMessage.value != null &&
          controller.merchants.isEmpty) {
        return CenteredMessage(
          message: controller.errorMessage.value!,
          icon: Icons.error_outline,
          onRetry: controller.applyFilters,
        );
      }
      if (controller.merchants.isEmpty && !controller.isLoading.value) {
        return CenteredMessage(
          message: "No merchant users found matching your criteria.",
          icon: Icons.people_outline,
          onRetry: controller.clearFilters,
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchMerchants(resetPage: true),
        child: ResponsiveDataTable<Merchant>(
          items: controller.merchants,
          columns: [
            DataColumn(
              label: const Text(
                'Merchant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (columnIndex, ascending) {},
            ),
            DataColumn(
              label: const Text(
                'Shop',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: const Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          buildCells: (merchant) {
            final isActive = merchant.isActive;
            return [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isActive
                          ? AppColors.merchant.shade100
                          : Colors.grey.shade200,
                      child: Text(
                        merchant.initial,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.merchant.shade700
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          merchant.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          merchant.id.substring(0, 8),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  merchant.shopName ?? '-',
                  style: TextStyle(
                    fontStyle: merchant.shopName == null
                        ? FontStyle.italic
                        : null,
                    color: merchant.shopName == null ? Colors.grey : null,
                  ),
                ),
              ),
              DataCell(
                Text(merchant.email, style: const TextStyle(fontSize: 13)),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
              ),
              DataCell(_buildActionsMenu(merchant)),
            ];
          },
          buildMobileCard: (merchant) {
            final isActive = merchant.isActive;
            return DataRowCard(
              leading: CircleAvatar(
                backgroundColor: isActive
                    ? AppColors.merchant.shade100
                    : Colors.grey.shade200,
                child: Text(
                  merchant.initial,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.merchant.shade700
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: merchant.name,
              subtitle: merchant.email,
              statusColor: isActive ? AppColors.success : AppColors.error,
              statusText: isActive ? 'Active' : 'Inactive',
              details: [
                if (merchant.shopName != null)
                  DetailRow(
                    icon: Icons.store,
                    label: 'Shop',
                    value: merchant.shopName!,
                  ),
                DetailRow(
                  icon: Icons.fingerprint,
                  label: 'ID',
                  value: '${merchant.id.substring(0, 13)}...',
                ),
              ],
              trailing: _buildActionsMenu(merchant),
            );
          },
          headingRowColor: AppColors.admin.shade50,
        ),
      );
    });
  }

  Widget _buildActionsMenu(Merchant merchant) {
    final isActive = merchant.isActive;
    return PopupMenuButton<String>(
      tooltip: "Actions",
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit') {
          controller.goToEditMerchantPage(merchant);
        } else if (value == 'delete') {
          controller.deleteMerchant(merchant.id, merchant.name);
        } else if (value == 'toggle_status') {
          controller.toggleMerchantStatus(merchant);
        } else if (value == 'details') {
          controller.goToMerchantDetailsPage(merchant);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('Edit User', style: TextStyle(fontSize: 14)),
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
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Colors.red,
              size: 20,
            ),
            title: Text(
              'Delete User',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Obx(() {
      if (controller.totalPages.value <= 1 && !controller.isLoading.value) {
        return const SizedBox.shrink();
      }
      if (controller.isLoading.value && controller.merchants.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Loading pagination..."),
          ),
        );
      }

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: controller.currentPage.value > 1
                    ? controller.previousPage
                    : null,
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
                onPressed:
                    controller.currentPage.value < controller.totalPages.value
                    ? controller.nextPage
                    : null,
                tooltip: "Next Page",
              ),
            ],
          ),
        ),
      );
    });
  }
}
