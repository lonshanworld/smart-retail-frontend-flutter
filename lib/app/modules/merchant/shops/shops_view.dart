import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/shops/shops_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopsView extends GetView<MerchantShopsController> {
  const ShopsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'My Shops',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.goToAddShop(),
        label: const Text('Create Shop'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.merchant,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.merchant.shade50.withOpacity(0.3), Colors.white],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value != null) {
            return Center(
              child: Text('Error: ${controller.errorMessage.value}'),
            );
          }
          return _buildShopList();
        }),
      ),
    );
  }

  Widget _buildShopList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400.0, // Max width of each grid item
        childAspectRatio: 3 / 2, // Aspect ratio of items
        crossAxisSpacing: 16.0, // Horizontal space between items
        mainAxisSpacing: 16.0, // Vertical space between items
      ),
      itemCount: controller.shopList.length,
      itemBuilder: (context, index) {
        final Shop shop = controller.shopList[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: () =>
                Get.toNamed(Routes.MERCHANT_SHOP_INVENTORY, arguments: shop.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.store_mall_directory_outlined,
                      size: 50,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: Get.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ID: ${shop.id}',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: shop.id ?? ''),
                                );
                                DialogUtils.showInfo('Shop ID copied to clipboard');
                              },
                              tooltip: 'Copy Shop ID',
                            ),
                          ],
                        ),
                        Text(
                          shop.address ?? 'No address',
                          style: Get.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
