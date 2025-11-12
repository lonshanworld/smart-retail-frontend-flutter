import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart';
import 'package:smart_retail/app/modules/admin/shops/add_edit_shop/admin_add_edit_shop_controller.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class AdminAddEditShopView extends GetView<AdminAddEditShopController> {
  const AdminAddEditShopView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.pageTitle.value)),
        backgroundColor: AppColors.admin,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => controller.saveShop(),
            tooltip: 'Save Shop',
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.admin.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header Card
                ModernCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.admin.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store_outlined,
                          color: AppColors.admin,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(
                              controller.isEditMode.value ? 'Edit Shop Details' : 'Create New Shop',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            const SizedBox(height: 4),
                            Text(
                              'Manage shop information',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Merchant Selection Section
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.person_outline,
                        title: 'Merchant Assignment',
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isFetchingMerchants.value) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        return DropdownButtonFormField<String>(
                          value: controller.selectedMerchantId.value,
                          decoration: InputDecoration(
                            labelText: 'Merchant *',
                            hintText: 'Select a merchant',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.admin, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: Icon(Icons.business, color: AppColors.admin),
                          ),
                          items: controller.merchants.map((UserSelectionItem merchant) {
                            return DropdownMenuItem<String>(
                              value: merchant.id,
                              child: Text(
                                merchant.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.selectedMerchantId.value = newValue;
                          },
                          validator: controller.validateMerchantId,
                        );
                      }),
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
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Shop Name *',
                          hintText: 'Enter shop name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.admin, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.storefront, color: AppColors.admin),
                        ),
                        validator: controller.validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.addressController,
                        decoration: InputDecoration(
                          labelText: 'Address (Optional)',
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
                            borderSide: BorderSide(color: AppColors.admin, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.admin),
                        ),
                        maxLines: 3,
                        validator: controller.validateAddress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status Section
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.toggle_on_outlined,
                        title: 'Status',
                      ),
                      const SizedBox(height: 16),
                      Obx(() => SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(
                          controller.isActive.value 
                              ? 'Shop is currently active' 
                              : 'Shop is currently inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        value: controller.isActive.value,
                        onChanged: (bool value) {
                          controller.isActive.value = value;
                        },
                        activeColor: AppColors.success,
                        contentPadding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                Obx(() => ElevatedButton.icon(
                      icon: controller.isLoading.value 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(controller.isLoading.value ? 'Saving...' : 'Save Shop'),
                      onPressed: controller.isLoading.value ? null : () => controller.saveShop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.admin,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    )),
              ],
            ),
          ),
        ),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
