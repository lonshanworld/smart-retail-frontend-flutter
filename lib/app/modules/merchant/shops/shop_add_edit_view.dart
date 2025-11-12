import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import './shop_add_edit_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ShopAddEditView extends GetView<ShopAddEditController> {
  const ShopAddEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'Edit Shop' : 'Add New Shop')),
        backgroundColor: AppColors.merchant,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => controller.saveShop(),
            tooltip: 'Save Shop',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header Card
              ModernCard(
                gradient: LinearGradient(
                  colors: [AppColors.merchant.shade400, AppColors.merchant.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                            controller.isEditing.value ? 'Edit Shop Details' : 'Create New Shop',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage shop information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.merchant.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.info_outline, color: AppColors.merchant, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Shop Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.nameController,
                      decoration: InputDecoration(
                        labelText: 'Shop Name *',
                        hintText: 'e.g., Downtown Branch',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.merchant, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.storefront, color: AppColors.merchant),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the shop name';
                        }
                        if (value.length < 2) {
                          return 'Shop name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter shop address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.merchant, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.merchant),
                      ),
                      maxLines: 3,
                      minLines: 2,
                    ),
                  ],
                ),
              ),

              // Save Button
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: controller.isSaving.value 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save Shop',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: controller.isSaving.value ? null : () => controller.saveShop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchant,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
