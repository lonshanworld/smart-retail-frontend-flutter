import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/promotions/add_edit/promotion_add_edit_controller.dart';

class PromotionAddEditView extends GetView<PromotionAddEditController> {
  const PromotionAddEditView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditing.value ? 'Edit Promotion' : 'Add Promotion',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildShopSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Promotion Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildPromotionTypeSelector(),
              const SizedBox(height: 16),
              Obx(
                () => TextFormField(
                  controller: controller.valueController,
                  decoration: InputDecoration(
                    labelText:
                        controller.selectedPromotionType.value == 'percentage'
                        ? 'Discount Percentage *'
                        : 'Discount Amount *',
                    hintText:
                        controller.selectedPromotionType.value == 'percentage'
                        ? 'e.g., 10 (for 10% off)'
                        : 'e.g., 5 (for \$5 off)',
                    border: const OutlineInputBorder(),
                    prefixText:
                        controller.selectedPromotionType.value == 'percentage'
                        ? ''
                        : '\$',
                    suffixText:
                        controller.selectedPromotionType.value == 'percentage'
                        ? '%'
                        : '',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Value is required' : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.minSpendController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Spend (Optional)',
                  hintText:
                      'e.g., 50 (promotion applies only if cart total >= this)',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                  helperText: 'Leave empty for no minimum',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildApplicabilitySelector(),
              const SizedBox(height: 16),
              _buildDatePickers(context),
              const SizedBox(height: 24),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.savePromotion,
                  child: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save Promotion',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopSelector() {
    return Obx(() {
      if (controller.isLoadingShops.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return DropdownButtonFormField<Shop>(
        value: controller.selectedShop.value,
        hint: const Text('1. Select a Shop'),
        items: controller.shopList
            .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
            .toList(),
        onChanged: controller.onShopSelected,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.store_outlined),
        ),
        validator: (v) => v == null ? 'Please select a shop' : null,
      );
    });
  }

  Widget _buildPromotionTypeSelector() {
    return Obx(
      () => DropdownButtonFormField<String>(
        value: controller.selectedPromotionType.value,
        items: const [
          DropdownMenuItem(
            value: 'percentage',
            child: Text('Percentage Discount'),
          ),
          DropdownMenuItem(
            value: 'fixed_amount',
            child: Text('Fixed Amount Discount'),
          ),
          DropdownMenuItem(
            value: 'bogo',
            child: Text('Buy One Get One (BOGO)'),
          ),
        ],
        onChanged: (String? value) {
          if (value != null) {
            controller.selectedPromotionType.value = value;
          }
        },
        decoration: const InputDecoration(
          labelText: 'Promotion Type *',
          border: OutlineInputBorder(),
          helperText: 'Choose how the discount is calculated',
        ),
      ),
    );
  }

  Widget _buildApplicabilitySelector() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Promotion Applies To:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('All Products (Cart-wide)'),
            subtitle: const Text(
              'Discount applies to entire cart when minimum spend is met',
            ),
            value: 'all',
            groupValue: controller.promotionAppliesTo.value,
            onChanged: (value) => controller.promotionAppliesTo.value = value!,
          ),
          RadioListTile<String>(
            title: const Text('Specific Products Only'),
            subtitle: const Text(
              'Discount applies only when selected products are in cart',
            ),
            value: 'specific',
            groupValue: controller.promotionAppliesTo.value,
            onChanged: (value) {
              controller.promotionAppliesTo.value = value!;
              if (value == 'specific' &&
                  controller.selectedShop.value != null) {
                controller.fetchProductsForShop(
                  controller.selectedShop.value!.id!,
                );
              }
            },
          ),
          if (controller.promotionAppliesTo.value == 'specific') ...[
            const SizedBox(height: 8),
            if (controller.selectedShop.value == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Please select a shop first to choose products',
                ),
              )
            else
              _buildProductSelector(),
          ],
        ],
      );
    });
  }

  Widget _buildProductSelector() {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.productList.isEmpty &&
          !controller.isLoadingProducts.value) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('No products found in this shop.'),
        );
      }
      return DropdownButtonFormField<InventoryItem>(
        value: controller.selectedProduct.value,
        hint: const Text('Select Product(s)'),
        items: controller.productList
            .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
            .toList(),
        onChanged: controller.onProductSelected,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.inventory_2_outlined),
          helperText: 'Future: Multi-select will be supported',
        ),
      );
    });
  }

  Widget _buildDatePickers(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => controller.selectDate(context, isStartDate: true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
              ),
              child: Obx(
                () => Text(
                  controller.startDate.value == null
                      ? 'Select...'
                      : DateFormat.yMd().format(controller.startDate.value!),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => controller.selectDate(context, isStartDate: false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
              ),
              child: Obx(
                () => Text(
                  controller.endDate.value == null
                      ? 'Select...'
                      : DateFormat.yMd().format(controller.endDate.value!),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
