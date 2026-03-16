// lib/app/modules/admin/shops/detail/admin_shop_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/modules/admin/shops/detail/admin_shop_detail_controller.dart';
import 'package:smart_retail/app/shared/widgets/centered_message.dart';
import 'package:smart_retail/app/shared/widgets/loading_indicator.dart';

class AdminShopDetailView extends GetView<AdminShopDetailController> {
  const AdminShopDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateTimeFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.shop.value?.name ?? 'Shop Details')),
        actions: [
          Obx(() {
            if (controller.shop.value != null) {
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: "Edit Shop",
                onPressed: controller.navigateToEditShop,
              );
            }
            return const SizedBox.shrink();
          }),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: "Refresh Details",
            onPressed: controller.refreshShopDetails,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.admin.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const LoadingIndicator(message: 'Loading shop details...');
          }
          if (controller.errorMessage.value != null) {
            return CenteredMessage(
              message: controller.errorMessage.value!,
              icon: Icons.error_outline,
              onRetry: controller.refreshShopDetails,
            );
          }
          final shop = controller.shop.value;
          if (shop == null) {
            return const CenteredMessage(
              message: 'Shop data not available.',
              icon: Icons.store_mall_directory_outlined,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header Card with Shop Icon
                ModernCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.admin.shade100,
                        child: Icon(
                          Icons.store_outlined,
                          size: 40,
                          color: AppColors.admin,
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (shop.isActive ?? false)
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (shop.isActive ?? false)
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (shop.isActive ?? false)
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: (shop.isActive ?? false)
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (shop.isActive ?? false)
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      color: (shop.isActive ?? false)
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Shop Information Section
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.info_outline,
                        title: 'Shop Information',
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.fingerprint_outlined,
                        label: 'Shop ID',
                        value: shop.id ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        icon: Icons.business_center_outlined,
                        label: 'Merchant ID',
                        value: shop.merchantId,
                      ),
                      if (shop.address != null && shop.address!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: shop.address!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timestamps Section
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.schedule_outlined,
                        title: 'Timestamps',
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created At',
                        value: dateTimeFormatter.format(
                          shop.createdAt.toLocal(),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        icon: Icons.update_outlined,
                        label: 'Last Updated At',
                        value: dateTimeFormatter.format(
                          shop.updatedAt.toLocal(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            color: AppColors.admin.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.admin, size: 20),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
