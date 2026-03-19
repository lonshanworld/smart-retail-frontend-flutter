// lib/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class AdminAddEditMerchantView extends GetView<AdminAddEditMerchantController> {
  const AdminAddEditMerchantView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.admin,
        foregroundColor: Colors.white,
        title: Obx(
          () => Text(
            controller.pageTitle.value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Save Merchant',
                onPressed: controller.isLoading.value
                    ? null
                    : controller.saveMerchant,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.admin.shade50.withValues(alpha:0.3), Colors.white],
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
                          color: AppColors.merchant.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(
                              () => Icon(
                            controller.isEditMode.value
                                ? Icons.edit_outlined
                                : Icons.store_mall_directory_outlined,
                            color: AppColors.merchant,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                                  () => Text(
                                controller.isEditMode.value
                                    ? 'Update Merchant Information'
                                    : 'Create New Merchant Account',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage merchant details and shop information',
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

                // Merchant Information Section
                _buildSectionHeader(
                  icon: Icons.person_outline,
                  title: 'Merchant Information',
                  subtitle: 'Personal and contact details',
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: controller.nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          hintText: "e.g., John Doe",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppColors.merchant,
                          ),
                        ),
                        validator: controller.validateName,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: controller.emailController,
                        decoration: InputDecoration(
                          labelText: "Contact Email",
                          hintText: "merchant.contact@example.com",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: AppColors.merchant,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: controller.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: controller.phoneController,
                        decoration: InputDecoration(
                          labelText: "Contact Phone (Optional)",
                          hintText: "e.g., +1234567890",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.merchant,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: controller.validatePhone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Shop Information Section
                _buildSectionHeader(
                  icon: Icons.store_outlined,
                  title: 'Shop Information',
                  subtitle: 'Primary shop details',
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Column(
                    children: [
                      // Shop Name
                      TextFormField(
                        controller: controller.shopNameController,
                        decoration: InputDecoration(
                          labelText: "Shop Name",
                          hintText: "e.g., John's Gadgets",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.merchant,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          prefixIcon: Icon(
                            Icons.store_outlined,
                            color: AppColors.merchant,
                          ),
                        ),
                        validator: controller.validateShopName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security Section (Password - only for new merchants)
                Obx(
                      () => !controller.isEditMode.value
                      ? Column(
                    children: [
                      _buildSectionHeader(
                        icon: Icons.lock_outline,
                        title: 'Security',
                        subtitle: 'Set up account credentials',
                      ),
                      const SizedBox(height: 12),
                      ModernCard(
                        child: Column(
                          children: [
                            // Password
                            TextFormField(
                              controller: controller.passwordController,
                              decoration: InputDecoration(
                                labelText: "Password",
                                hintText: "Enter a strong password",
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.merchant,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.merchant,
                                ),
                              ),
                              obscureText: true,
                              validator: controller.validatePassword,
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            TextFormField(
                              controller:
                              controller.confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                hintText: "Re-enter the password",
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.merchant,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.password_outlined,
                                  color: AppColors.merchant,
                                ),
                              ),
                              obscureText: true,
                              validator:
                              controller.validateConfirmPassword,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),

                // Account Status Section
                _buildSectionHeader(
                  icon: Icons.toggle_on_outlined,
                  title: 'Account Status',
                  subtitle: 'Enable or disable merchant access',
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Obx(
                        () => SwitchListTile(
                      title: const Text(
                        'Merchant Active Status',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        controller.isActive.value
                            ? "Merchant user account will be operational"
                            : "Merchant user account will be suspended",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      value: controller.isActive.value,
                      onChanged: (val) => controller.isActive.value = val,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: controller.isActive.value
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          controller.isActive.value
                              ? Icons.check_circle_outline
                              : Icons.highlight_off_outlined,
                          color: controller.isActive.value
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                      activeThumbColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                Obx(
                      () => SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: controller.isLoading.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        controller.isLoading.value
                            ? 'Saving...'
                            : controller.isEditMode.value
                            ? 'Update Merchant'
                            : 'Create Merchant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.saveMerchant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.merchant,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.merchant.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.merchant, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
