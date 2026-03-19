import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import './edit_inventory_item_controller.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class EditInventoryItemView extends GetView<EditInventoryItemController> {
  const EditInventoryItemView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inventory Item'),
        actions: [
          Obx(() {
            if (controller.itemToEdit.value == null)
              return const SizedBox.shrink();
            return IconButton(
              icon: controller.isCheckingDelete.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete Item',
              onPressed: controller.isCheckingDelete.value
                  ? null
                  : () async {
                      final item = controller.itemToEdit.value;
                      if (item == null) return;
                      final proceed = await DialogUtils.showConfirmDialog(
                        title: 'Delete Item',
                        message:
                            'Are you sure you want to delete "${item.name}"? This will check for references and delete if allowed.',
                        confirmText: 'Proceed',
                        cancelText: 'Cancel',
                        isDanger: true,
                      );
                      if (proceed == true) {
                        await controller.checkAndDeleteItem(
                          skipFinalConfirm: true,
                        );
                      }
                    },
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.originalPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Original Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selling price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategoryId.value,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: controller.setSelectedCategory,
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedSubcategoryId.value,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.filteredSubcategories
                      .map(
                        (subcategory) => DropdownMenuItem(
                          value: subcategory.id,
                          child: Text(subcategory.name),
                        ),
                      )
                      .toList(),
                  onChanged: controller.filteredSubcategories.isEmpty
                      ? null
                      : controller.setSelectedSubcategory,
                ),
              ),
              const SizedBox(height: 16),
              Autocomplete<BrandRef>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return controller.brands;
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return controller.brands.where(
                    (brand) => brand.name.toLowerCase().contains(query),
                  );
                },
                displayStringForOption: (brand) => brand.name,
                onSelected: (brand) {
                  controller.selectedBrandId.value = brand.id;
                  controller.brandController.text = brand.name;
                },
                fieldViewBuilder:
                    (context, textController, focusNode, onSubmitted) {
                      textController.text = controller.brandController.text;
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textController.text.length),
                      );
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Brand (optional)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: controller.selectBrandByName,
                      );
                    },
              ),
              const SizedBox(height: 32),
              Obx(
                () => ElevatedButton.icon(
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    controller.isLoading.value ? 'Saving...' : 'Update Item',
                  ),
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.updateInventoryItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
