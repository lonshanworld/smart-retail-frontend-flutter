// lib/app/modules/admin/merchants/detail/admin_merchant_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/admin/merchants/detail/admin_merchant_detail_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class AdminMerchantDetailView extends GetView<AdminMerchantDetailController> {
  const AdminMerchantDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.admin,
        foregroundColor: Colors.white,
        title: Obx(
          () => Text(
            controller.merchant.value?.name ?? 'Merchant Details',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          Obx(() {
            if (controller.merchant.value != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: "Edit Merchant",
                  onPressed: controller.navigateToEditMerchant,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.admin.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ModernCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: controller.refreshMerchantDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.admin,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final merchant = controller.merchant.value;
          if (merchant == null) {
            return Center(
              child: ModernCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Merchant data not available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

          return RefreshIndicator(
            onRefresh: controller.refreshMerchantDetails,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header Card with Avatar
                  ModernCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.merchant.shade100,
                          child: Icon(
                            Icons.store_outlined,
                            size: 40,
                            color: AppColors.merchant.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          merchant.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          merchant.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.merchant.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.merchant.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 16,
                                    color: AppColors.merchant.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Merchant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.merchant.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: merchant.isActive
                                    ? AppColors.success.shade50
                                    : AppColors.error.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: merchant.isActive
                                      ? AppColors.success.shade300
                                      : AppColors.error.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    merchant.isActive
                                        ? Icons.check_circle_outline
                                        : Icons.highlight_off_outlined,
                                    size: 16,
                                    color: merchant.isActive
                                        ? AppColors.success.shade700
                                        : AppColors.error.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    merchant.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: merchant.isActive
                                          ? AppColors.success.shade700
                                          : AppColors.error.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Business Information
                  _buildSectionHeader(
                    icon: Icons.business_outlined,
                    title: 'Business Information',
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.fingerprint_outlined,
                          label: 'User ID',
                          value: merchant.id,
                        ),
                        if (merchant.phone != null &&
                            merchant.phone!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Contact Phone',
                            value: merchant.phone!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shops Section
                  _buildSectionHeader(
                    icon: Icons.store_outlined,
                    title: 'Shops (${merchant.shops.length})',
                  ),
                  const SizedBox(height: 12),
                  if (merchant.shops.isEmpty)
                    ModernCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.store_mall_directory_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No shops assigned to this merchant',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...merchant.shops.map(
                      (shop) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ModernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.merchant.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.store,
                                      color: AppColors.merchant,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      shop.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (shop.isPrimary ?? false)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        'PRIMARY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (shop.isActive ?? false)
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: (shop.isActive ?? false)
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      (shop.isActive ?? false)
                                          ? 'ACTIVE'
                                          : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: (shop.isActive ?? false)
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (shop.address != null &&
                                  shop.address!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          shop.address!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (shop.phone != null && shop.phone!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      shop.phone!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Timestamps
                  _buildSectionHeader(
                    icon: Icons.schedule_outlined,
                    title: 'Timestamps',
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created At',
                          value: dateFormat.format(
                            merchant.createdAt.toLocal(),
                          ),
                        ),
                        _buildDetailRow(
                          icon: Icons.update_outlined,
                          label: 'Last Updated',
                          value: dateFormat.format(
                            merchant.updatedAt.toLocal(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.merchant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.merchant, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
