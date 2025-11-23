import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/cart_item_model.dart';
import 'package:smart_retail/app/data/models/promotion_model.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import 'package:smart_retail/app/modules/staff_pos/staff_pos_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class StaffPosView extends GetView<StaffPosController> {
  const StaffPosView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'Point of Sale',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.staff.shade50.withOpacity(0.3), Colors.white],
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
              _buildSearchField(),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
        Expanded(flex: 1, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildMobileView() {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.bottomSheet(
          _buildCartPanel(),
          isScrollControlled: true,
          backgroundColor: Get.theme.cardColor,
        ),
        label: const Text('View Cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
      ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
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
                      child: const Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      NumberFormat.currency(
                        symbol: '\$',
                      ).format(product.sellingPrice),
                    ),
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
          _buildPromotionSelector(),
          const Divider(),
          _buildCustomerNameField(),
          const Divider(),
          _buildTotals(),
          const SizedBox(height: 16),
          Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isCheckingOut.value || controller.cartItems.isEmpty
                  ? null
                  : controller.handleCheckout,
              icon: controller.isCheckingOut.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                controller.isCheckingOut.value
                    ? 'Processing...'
                    : 'Checkout (${currencyFormatter.format(controller.cartTotal)})',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: controller.clearCart,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            label: const Text(
              'Clear Cart',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItem cartItem) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        cartItem.product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(currencyFormatter.format(cartItem.product.sellingPrice)),
      trailing: Obx(
        () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => controller.decrementCartItem(cartItem),
            ),
            Text(
              cartItem.quantity.value.toString(),
              style: Get.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => controller.incrementCartItem(cartItem),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotals() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return Obx(
      () => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: Get.textTheme.bodyLarge),
              Text(
                currencyFormatter.format(controller.cartSubtotal),
                style: Get.textTheme.bodyLarge,
              ),
            ],
          ),
          if (controller.discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount',
                  style: Get.textTheme.bodyLarge?.copyWith(color: Colors.green),
                ),
                Text(
                  '-${currencyFormatter.format(controller.discountAmount)}',
                  style: Get.textTheme.bodyLarge?.copyWith(color: Colors.green),
                ),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (5%)', style: Get.textTheme.bodyLarge),
              Text(
                currencyFormatter.format(controller.taxAmount),
                style: Get.textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Get.textTheme.headlineSmall),
              Text(
                currencyFormatter.format(controller.cartTotal),
                style: Get.textTheme.headlineSmall?.copyWith(
                  color: Get.theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Promotion', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<Promotion?>(
            value: controller.selectedPromotion.value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<Promotion?>(
                value: null,
                child: Text('No promotion'),
              ),
              ...controller.availablePromotions.map((promo) {
                return DropdownMenuItem<Promotion?>(
                  value: promo,
                  child: Text(promo.name),
                );
              }),
            ],
            onChanged: (promo) => controller.selectPromotion(promo),
          ),
          if (controller.selectedPromotion.value != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.selectedPromotion.value!.type == 'percentage'
                        ? '${controller.selectedPromotion.value!.value}% off'
                        : '\$${controller.selectedPromotion.value!.value.toStringAsFixed(2)} off',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Min. spend: \$${controller.selectedPromotion.value!.minSpend.toStringAsFixed(2)}',
                  ),
                  if (controller.cartSubtotal <
                      controller.selectedPromotion.value!.minSpend)
                    Text(
                      'Need \$${(controller.selectedPromotion.value!.minSpend - controller.cartSubtotal).toStringAsFixed(2)} more to apply',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
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
