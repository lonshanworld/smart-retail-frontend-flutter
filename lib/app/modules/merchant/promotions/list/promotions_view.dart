import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';

import 'promotions_controller.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class PromotionsView extends GetView<PromotionsController> {
  const PromotionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Promotions',
      body: Obx(() {
        if (controller.isLoading.value && controller.promotions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null && controller.promotions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${controller.error.value}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (controller.promotions.isEmpty) {
          return const Center(child: Text('No promotions found.'));
        }

        return RefreshIndicator(
          onRefresh: () async => controller.fetchPromotions(),
          child: ListView.builder(
            itemCount: controller.promotions.length,
            itemBuilder: (context, index) {
              final promotion = controller.promotions[index];

              // Format dates or show "Always Available"
              final String dateDisplay;
              if (promotion.startDate == null && promotion.endDate == null) {
                dateDisplay = 'Always Available';
              } else if (promotion.startDate != null &&
                  promotion.endDate != null) {
                final formattedStartDate = DateFormat.yMMMd().format(
                  promotion.startDate!,
                );
                final formattedEndDate = DateFormat.yMMMd().format(
                  promotion.endDate!,
                );
                dateDisplay = '$formattedStartDate - $formattedEndDate';
              } else if (promotion.startDate != null) {
                final formattedStartDate = DateFormat.yMMMd().format(
                  promotion.startDate!,
                );
                dateDisplay = 'From $formattedStartDate';
              } else {
                final formattedEndDate = DateFormat.yMMMd().format(
                  promotion.endDate!,
                );
                dateDisplay = 'Until $formattedEndDate';
              }

              return Dismissible(
                key: Key(promotion.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await DialogUtils.showCustomDialog<bool>(
                    dialog: AlertDialog(
                      title: const Text('Delete Promotion'),
                      content: Text(
                        'Are you sure you want to delete "${promotion.name}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  controller.deletePromotion(promotion, skipConfirmation: true);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      promotion.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          promotion.description.isNotEmpty
                              ? promotion.description
                              : 'No description',
                        ),
                        const SizedBox(height: 8),
                        Text('Dates: $dateDisplay'),
                        if (promotion.shopId != null) ...[
                          const SizedBox(height: 4),
                          Text('Shop ID: ${promotion.shopId}'),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: promotion.isActive,
                              onChanged: (value) =>
                                  controller.togglePromotionStatus(promotion),
                              activeThumbColor: Colors.green,
                            ),
                            Text(
                              promotion.isActive ? 'Active' : 'Inactive',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: promotion.isActive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              controller.deletePromotion(promotion),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    onTap: () => controller.goToEditPromotion(promotion),
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.goToAddPromotion(),
        tooltip: 'Add Promotion',
        child: const Icon(Icons.add),
      ),
    );
  }
}
