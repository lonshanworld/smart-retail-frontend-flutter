import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/staff/add_edit/staff_add_edit_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class StaffAddEditView extends GetView<StaffAddEditController> {
  const StaffAddEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEditMode.value ? 'Edit Staff' : 'Add New Staff',
          ),
        ),
        backgroundColor: AppColors.merchant,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            ModernCard(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.merchant.shade50, Colors.white],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.merchant.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 32,
                        color: AppColors.merchant.shade700,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => Text(
                              controller.isEditMode.value
                                  ? 'Update Staff Information'
                                  : 'Add New Staff Member',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.merchant.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details below',
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
            ),
            const SizedBox(height: 24),

            // Form Card
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Personal Information Section
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: AppColors.merchant,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter staff member\'s full name',
                          prefixIcon: Icon(
                            Icons.person,
                            color: AppColors.merchant.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: controller.emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'staff@example.com',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.merchant.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (GetUtils.isEmail(value ?? ''))
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 20),

                      // Password Field (only for new staff)
                      Obx(
                        () => controller.isEditMode.value
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  TextFormField(
                                    controller: controller.passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter secure password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: AppColors.merchant.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppColors.merchant,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    obscureText: true,
                                    validator: (value) =>
                                        (value?.isEmpty ?? true)
                                        ? 'Password is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                      ),

                      const Divider(height: 40),

                      // Shop Assignment Section
                      Row(
                        children: [
                          Icon(
                            Icons.store_outlined,
                            color: AppColors.shop,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Shop Assignment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Shop Dropdown
                      _buildShopDropdown(),

                      const Divider(height: 40),

                      // Status Section
                      Row(
                        children: [
                          Icon(
                            Icons.toggle_on_outlined,
                            color: AppColors.merchant.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Account Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Active Status Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enable or disable staff account access',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Obx(
                              () => Switch(
                                value: controller.isActive.value,
                                onChanged: (value) =>
                                    controller.isActive.value = value,
                                activeThumbColor: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Error Message
                      Obx(() {
                        if (controller.formError.value != null) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.formError.value!,
                                    style: TextStyle(
                                      color: AppColors.error.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Save Button
                      Obx(
                        () => SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            icon: controller.isSaving.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save, size: 24),
                            label: Text(
                              controller.isSaving.value
                                  ? 'Saving...'
                                  : controller.isEditMode.value
                                  ? 'Update Staff'
                                  : 'Add Staff',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: controller.isSaving.value
                                ? null
                                : () => controller.saveStaff(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.merchant,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor:
                                  AppColors.merchant.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopDropdown() {
    return Obx(() {
      if (controller.isLoadingShops.value) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading shops...'),
              ],
            ),
          ),
        );
      }
      if (controller.shopList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warning.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No shops available for assignment.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }
      return DropdownButtonFormField<String>(
        initialValue: controller.selectedShopId.value,
        hint: const Text('Select a shop (Optional)'),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('No Shop Assignment'),
          ),
          ...controller.shopList.map((Shop shop) {
            return DropdownMenuItem<String>(
              value: shop.id,
              child: Row(
                children: [
                  Icon(Icons.store, size: 18, color: AppColors.shop.shade600),
                  const SizedBox(width: 8),
                  Text(shop.name),
                ],
              ),
            );
          }),
        ],
        onChanged: (String? newValue) {
          controller.selectedShopId.value = newValue;
        },
        decoration: InputDecoration(
          labelText: 'Assigned Shop',
          prefixIcon: Icon(Icons.storefront, color: AppColors.shop.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.shop, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      );
    });
  }
}
