import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/pos/pos_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class PosView extends GetView<PosController> {
  const PosView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Point of Sale (POS)',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.merchant.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return _buildMobileView();
            } else {
              return _buildTabletView();
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabletView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildShopSelector(),
              _buildSearchField(),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileView() {
    return Scaffold(
      body: Column(
        children: [
          _buildShopSelector(),
          _buildSearchField(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.bottomSheet(_buildCartPanel(), isScrollControlled: true, backgroundColor: Get.theme.cardColor),
        label: const Text('View Cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }

  Widget _buildShopSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Obx(() {
        if (controller.isLoadingShops.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.shopList.isEmpty) {
          return const Text('No shops found. Please add a shop first.');
        }
        return DropdownButtonFormField<Shop>(
          value: controller.selectedShop.value,
          items: controller.shopList.map((shop) {
            return DropdownMenuItem<Shop>(
              value: shop,
              child: Text(shop.name),
            );
          }).toList(),
          onChanged: (shop) => controller.onShopSelected(shop),
          decoration: const InputDecoration(
            labelText: 'Select a Shop',
            border: OutlineInputBorder(),
          ),
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: controller.searchController,
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (controller.isSearching.value && controller.searchResults.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.searchResults.isEmpty) {
        return const Center(child: Text('No products found.'));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final product = controller.searchResults[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => controller.addToCart(product),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(NumberFormat.currency(symbol: '\$').format(product.sellingPrice)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCartPanel() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return Container(
      color: Get.theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cart', style: Get.textTheme.headlineSmall),
          const Divider(),
          _buildPromotionSelector(),
          const SizedBox(height: 8),
          const Divider(),
          _buildCustomerNameField(),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (controller.cartItems.isEmpty) {
                return const Center(child: Text('Cart is empty'));
              }
              return ListView.builder(
                itemCount: controller.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = controller.cartItems[index];
                  return _buildCartItemTile(cartItem);
                },
              );
            }),
          ),
          const Divider(),
          _buildTotals(),
          const SizedBox(height: 16),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.isCheckingOut.value || controller.cartItems.isEmpty ? null : controller.handleCheckout,
                icon: controller.isCheckingOut.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)) : const Icon(Icons.payment),
                label: Text(controller.isCheckingOut.value ? 'Processing...' : 'Checkout (${currencyFormatter.format(controller.cartTotal)})'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.clearCart,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            label: const Text('Clear Cart', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem cartItem) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(cartItem.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(currencyFormatter.format(cartItem.product.sellingPrice)),
      trailing: Obx(() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => controller.decrementCartItem(cartItem)),
          Text(cartItem.quantity.value.toString(), style: Get.textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => controller.incrementCartItem(cartItem)),
        ],
      )),
    );
  }

  Widget _buildTotals() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return Obx(() => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Get.textTheme.bodyLarge),
                Text(currencyFormatter.format(controller.cartSubtotal), style: Get.textTheme.bodyLarge),
              ],
            ),
            if (controller.discountAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount', style: Get.textTheme.bodyLarge?.copyWith(color: Colors.green)),
                  Text('-${currencyFormatter.format(controller.discountAmount)}', style: Get.textTheme.bodyLarge?.copyWith(color: Colors.green)),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (5%)', style: Get.textTheme.bodyLarge),
                Text(currencyFormatter.format(controller.taxAmount), style: Get.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: Get.textTheme.headlineSmall),
                Text(currencyFormatter.format(controller.cartTotal), style: Get.textTheme.headlineSmall?.copyWith(color: Get.theme.colorScheme.primary)),
              ],
            ),
          ],
        ));
  }

  Widget _buildPromotionSelector() {
    return Obx(() {
      if (controller.isLoadingPromotions.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      
      if (controller.availablePromotions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apply Promotion', style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: controller.selectedPromotion.value?.id,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.local_offer),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select a promotion',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No promotion'),
              ),
              ...controller.availablePromotions.map((promo) {
                final promoText = promo.type == 'percentage'
                    ? '${promo.name} (${promo.value.toStringAsFixed(0)}% off)'
                    : '${promo.name} (\$${promo.value.toStringAsFixed(2)} off)';
                final minSpendText = promo.minSpend > 0 ? ' - Min: \$${promo.minSpend.toStringAsFixed(2)}' : '';
                
                return DropdownMenuItem<String?>(
                  value: promo.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(promoText, style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (minSpendText.isNotEmpty)
                        Text(minSpendText, style: Get.textTheme.bodySmall),
                    ],
                  ),
                );
              }).toList(),
            ],
            onChanged: (promoId) {
              if (promoId == null) {
                controller.selectPromotion(null);
              } else {
                final promo = controller.availablePromotions.firstWhere((p) => p.id == promoId);
                controller.selectPromotion(promo);
              }
            },
          ),
          if (controller.selectedPromotion.value != null && controller.cartSubtotal < controller.selectedPromotion.value!.minSpend) ...[
            const SizedBox(height: 4),
            Text(
              'Minimum spend of \$${controller.selectedPromotion.value!.minSpend.toStringAsFixed(2)} required',
              style: Get.textTheme.bodySmall?.copyWith(color: Colors.orange),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildCustomerNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Customer Name (Optional)', style: Get.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller.customerNameController,
          decoration: const InputDecoration(
            hintText: 'Enter customer name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
      ],
    );
  }
}
