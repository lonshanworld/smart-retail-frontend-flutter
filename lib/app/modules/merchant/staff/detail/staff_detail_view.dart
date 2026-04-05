import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/staff/detail/staff_detail_controller.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class StaffDetailView extends GetView<StaffDetailController> {
  const StaffDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Staff Details'),
        backgroundColor: AppColors.merchant,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() {
            if (controller.staff.value == null) return const SizedBox.shrink();
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Staff',
                  onPressed: () => controller.goToEditStaff(),
                ),
                IconButton(
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
                  tooltip: 'Delete Staff',
                  onPressed: controller.isCheckingDelete.value
                      ? null
                      : () => controller.checkAndDeleteStaff(),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.staff.value == null) {
          return Center(
            child: ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No staff member selected',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final staff = controller.staff.value!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Avatar
              ModernCard(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.merchant.shade700,
                    AppColors.merchant.shade900,
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            staff.name.isNotEmpty
                                ? staff.name[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.merchant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: staff.isActive
                                        ? AppColors.success.shade100
                                        : AppColors.error.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        staff.isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: staff.isActive
                                            ? AppColors.success.shade700
                                            : AppColors.error.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        staff.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: staff.isActive
                                              ? AppColors.success.shade700
                                              : AppColors.error.shade700,
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
                                    color: AppColors.staff.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.badge,
                                        size: 16,
                                        color: AppColors.staff.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Staff Member',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.staff.shade700,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Information Card
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.merchant,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildModernDetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: staff.email,
                        iconColor: AppColors.merchant,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDetailRow(
                        icon: Icons.fingerprint,
                        label: 'Staff ID',
                        value: staff.id,
                        iconColor: AppColors.merchant.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shop Assignment Card
              if (staff.shopName != null)
                ModernCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              color: AppColors.shop,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Shop Assignment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildModernDetailRow(
                          icon: Icons.store,
                          label: 'Assigned Shop',
                          value: staff.shopName!,
                          iconColor: AppColors.shop,
                        ),
                      ],
                    ),
                  ),
                ),
              if (staff.shopName != null) const SizedBox(height: 16),

              // Account Information Card
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppColors.merchant.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildModernDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Member Since',
                        value:
                            staff.createdAt?.toLocal().toString().split(
                              ' ',
                            )[0] ??
                            'N/A',
                        iconColor: AppColors.merchant.shade600,
                      ),
                      const SizedBox(height: 16),
                      _buildModernDetailRow(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value:
                            staff.updatedAt?.toLocal().toString().split(
                              ' ',
                            )[0] ??
                            'N/A',
                        iconColor: AppColors.merchant.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildModernDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
