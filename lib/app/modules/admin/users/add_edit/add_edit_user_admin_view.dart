import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/users/add_edit/add_edit_user_admin_controller.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class AddEditUserAdminView extends GetView<AddEditUserAdminController> {
  const AddEditUserAdminView({super.key});

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
            controller.isEditMode.value ? 'Edit User' : 'Add New User',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                tooltip: 'Save User',
                onPressed: controller.isSaving.value
                    ? null
                    : () => controller.saveUser(),
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
            colors: [AppColors.admin.shade50.withValues(alpha: 0.3), Colors.white],
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
                          color: AppColors.admin.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          controller.isEditMode.value
                              ? Icons.edit_outlined
                              : Icons.person_add_outlined,
                          color: AppColors.admin,
                          size: 32,
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
                                    ? 'Update User Information'
                                    : 'Create New User Account',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details below to manage user access',
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

                // Basic Information Section
                _buildSectionHeader(
                  icon: Icons.person_outline,
                  title: 'Basic Information',
                  subtitle: 'User identity and contact details',
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Column(
                    children: [
                      ModernCard(
                        child: Column(
                          children: [
                            // Name
                            TextFormField(
                              controller: controller.nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter user\'s full name',
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
                                    color: AppColors.admin,
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
                                  Icons.person_outline,
                                  color: AppColors.admin,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                if (value.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: controller.emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter user\'s email',
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
                                    color: AppColors.admin,
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
                                  Icons.email_outlined,
                                  color: AppColors.admin,
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Security Section (Password - only for new users)
                      Obx(
                            () => controller.isEditMode.value
                            ? const SizedBox.shrink()
                            : Column(
                          children: [
                            _buildSectionHeader(
                              icon: Icons.lock_outline,
                              title: 'Security',
                              subtitle: 'Set up account credentials',
                            ),
                            const SizedBox(height: 12),
                            ModernCard(
                              child: TextFormField(
                                controller: controller.passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter a strong password',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: BorderSide(
                                      color: AppColors.admin,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.admin,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordObscured.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () => controller
                                        .togglePasswordVisibility(),
                                  ),
                                ),
                                obscureText:
                                controller.isPasswordObscured.value,
                                validator: (value) {
                                  if (controller.isEditMode.value) {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Role & Permissions Section
                      _buildSectionHeader(
                        icon: Icons.shield_outlined,
                        title: 'Role & Permissions',
                        subtitle: 'Define user access level',
                      ),
                      const SizedBox(height: 12),
                      ModernCard(
                        child: Column(
                          children: [
                            // Role Dropdown
                            Obx(
                                  () => DropdownButtonFormField<UserRole>(
                                initialValue: controller.selectedRole.value,
                                decoration: InputDecoration(
                                  labelText: 'User Role',
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
                                      color: AppColors.admin,
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
                                    Icons.shield_outlined,
                                    color: AppColors.admin,
                                  ),
                                ),
                                items: UserRole.values
                                    .where((role) => role != UserRole.unknown)
                                    .map((UserRole role) {
                                  return DropdownMenuItem<UserRole>(
                                    value: role,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getRoleIcon(role),
                                          size: 20,
                                          color: _getRoleColor(role),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(role.toDisplayString()),
                                      ],
                                    ),
                                  );
                                })
                                    .toList(),
                                onChanged: (UserRole? newValue) {
                                  if (newValue != null) {
                                    controller.onRoleChanged(newValue);
                                  }
                                },
                                validator: (value) =>
                                value == null || value == UserRole.unknown
                                    ? 'Please select a role'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Associated Merchant (Visible if Role is Staff)
                      Obx(() {
                        if (controller.selectedRole.value == UserRole.staff) {
                          return Column(
                            children: [
                              _buildSectionHeader(
                                icon: Icons.supervisor_account_outlined,
                                title: 'Merchant Assignment',
                                subtitle: 'Link staff to their merchant',
                              ),
                              const SizedBox(height: 12),
                              ModernCard(
                                child: controller.isFetchingMerchants.value
                                    ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                                    : controller.merchantsForSelection.isEmpty
                                    ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No merchants available to assign. Please create a merchant user first.',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                    : DropdownButtonFormField<String>(
                                  initialValue:
                                  controller.selectedMerchantId.value,
                                  decoration: InputDecoration(
                                    labelText: 'Associated Merchant',
                                    hintText:
                                    'Select a merchant for this staff member',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.admin,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.supervisor_account_outlined,
                                      color: AppColors.admin,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: controller.merchantsForSelection
                                      .map((UserSelectionItem merchant) {
                                    return DropdownMenuItem<String>(
                                      value: merchant.id,
                                      child: Text(merchant.name),
                                    );
                                  })
                                      .toList(),
                                  onChanged: (String? newValue) {
                                    controller.selectedMerchantId.value =
                                        newValue;
                                  },
                                  validator: (value) {
                                    if (controller.selectedRole.value ==
                                        UserRole.staff &&
                                        (value == null ||
                                            value.isEmpty)) {
                                      return 'Please assign a merchant to this staff member';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Account Status (Edit mode only)
                      Obx(
                            () => controller.isEditMode.value
                            ? Column(
                          children: [
                            _buildSectionHeader(
                              icon: Icons.toggle_on_outlined,
                              title: 'Account Status',
                              subtitle: 'Enable or disable user access',
                            ),
                            const SizedBox(height: 12),
                            ModernCard(
                              child: SwitchListTile(
                                title: const Text(
                                  'Active Status',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  controller.isActive.value
                                      ? 'User can access the system'
                                      : 'User access is disabled',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                value: controller.isActive.value,
                                onChanged: (bool value) {
                                  controller.isActive.value = value;
                                },
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: controller.isActive.value
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
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
                            const SizedBox(height: 24),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),

                      // Error Message
                      Obx(() {
                        if (controller.formError.value != null) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.formError.value!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
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
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: controller.isSaving.value
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
                              controller.isSaving.value
                                  ? 'Saving...'
                                  : controller.isEditMode.value
                                  ? 'Update User'
                                  : 'Create User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: controller.isSaving.value
                                ? null
                                : () => controller.saveUser(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.admin,
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
            color: AppColors.admin.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.admin, size: 20),
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

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.merchant:
        return Icons.store_outlined;
      case UserRole.staff:
        return Icons.badge_outlined;

      default:
        return Icons.help_outline;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.admin;
      case UserRole.merchant:
        return AppColors.merchant;
      case UserRole.staff:
        return AppColors.staff;

      default:
        return Colors.grey;
    }
  }
}
