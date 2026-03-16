import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/modules/admin/users/detail/user_detail_admin_controller.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class UserDetailAdminView extends GetView<UserDetailAdminController> {
  const UserDetailAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.admin,
        foregroundColor: Colors.white,
        title: const Text(
          'User Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(() {
            if (controller.user.value != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit User',
                  onPressed: () async {
                    final result = await Get.toNamed(
                      Routes.ADMIN_ADD_EDIT_USER,
                      arguments: controller.user.value,
                    );
                    if (result == true) {
                      controller.fetchUserDetails();
                    }
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),
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
        child: Obx(() {
          if (controller.isLoading.isTrue) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ModernCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => controller.fetchUserDetails(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.admin,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final User? user = controller.user.value;
          if (user == null) {
            return Center(
              child: ModernCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'User not found.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
          final roleColor = _getRoleColor(user.role);

          return RefreshIndicator(
            onRefresh: () => controller.fetchUserDetails(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header Card with Avatar
                  ModernCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: roleColor.shade100,
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: roleColor.shade700,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: roleColor.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getRoleIcon(user.roleAsEnum),
                                    size: 16,
                                    color: roleColor.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.roleDisplay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: roleColor.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? AppColors.success.shade50
                                    : AppColors.error.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: user.isActive
                                      ? AppColors.success.shade300
                                      : AppColors.error.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    user.isActive
                                        ? Icons.check_circle_outline
                                        : Icons.highlight_off_outlined,
                                    size: 16,
                                    color: user.isActive
                                        ? AppColors.success.shade700
                                        : AppColors.error.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: user.isActive
                                          ? AppColors.success.shade700
                                          : AppColors.error.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Basic Information
                  _buildSectionHeader(
                    icon: Icons.info_outline,
                    title: 'Basic Information',
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.fingerprint_outlined,
                          label: 'User ID',
                          value: user.id,
                        ),
                        if (user.roleAsEnum == UserRole.merchant &&
                            user.shopName != null &&
                            user.shopName!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.store_outlined,
                            label: 'Shop Name',
                            value: user.shopName!,
                          ),
                        if (user.roleAsEnum == UserRole.staff &&
                            user.merchantId != null)
                          _buildDetailRow(
                            icon: Icons.supervisor_account_outlined,
                            label: 'Merchant ID',
                            value: user.merchantId!,
                          ),
                        if (user.roleAsEnum == UserRole.staff &&
                            user.merchantName != null &&
                            user.merchantName!.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.business_outlined,
                            label: 'Associated Merchant',
                            value: user.merchantName!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timestamps
                  _buildSectionHeader(
                    icon: Icons.schedule_outlined,
                    title: 'Timestamps',
                  ),
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created At',
                          value: user.createdAt != null
                              ? dateFormat.format(user.createdAt!.toLocal())
                              : 'N/A',
                        ),
                        _buildDetailRow(
                          icon: Icons.update_outlined,
                          label: 'Last Updated',
                          value: user.updatedAt != null
                              ? dateFormat.format(user.updatedAt!.toLocal())
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  MaterialColor _getRoleColor(String roleString) {
    final role = roleString.toUserRole();
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
}

