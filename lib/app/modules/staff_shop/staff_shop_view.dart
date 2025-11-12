import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import './staff_shop_controller.dart';

class StaffShopView extends GetView<StaffShopController> {
  const StaffShopView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'Assigned Shop',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          // While loading, show a circular progress indicator.
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // If there's an error message, display it with a retry button.
          if (controller.errorMessage.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.fetchAssignedShop(),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          // If shop data is null after loading, show a friendly message.
          final shop = controller.shop.value;
          if (shop == null) {
            return const Center(child: Text('No shop has been assigned to your account.'));
          }

          // If data is successfully loaded, display the shop details in a card.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.location_on_outlined, 'Address', shop.address ?? 'Not available'),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.phone_outlined, 'Phone', shop.phone ?? 'Not available'),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.business_outlined, 'Merchant ID', shop.merchantId),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Created On',
                        shop.createdAt != null ? DateFormat.yMMMd().format(shop.createdAt!) : 'N/A',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Helper widget to create a consistent row for displaying shop details.
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Get.theme.colorScheme.primary, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: Get.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
