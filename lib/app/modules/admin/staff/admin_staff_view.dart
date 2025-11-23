import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/staff/admin_staff_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class AdminStaffView extends GetView<AdminStaffController> {
  const AdminStaffView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Manage All Staff',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(
            child: ModernCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading staff',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.errorMessage.value!,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.staff.isNotEmpty) {
          return ListView.builder(
            itemCount: controller.staff.length,
            itemBuilder: (context, index) {
              final staffMember = controller.staff[index];
              return ModernCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.staff.shade100,
                    child: Icon(Icons.badge, color: AppColors.staff),
                  ),
                  title: Text(
                    staffMember.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${staffMember.email}\n${staffMember.merchantName ?? 'No Merchant'}',
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: staffMember.isActive
                          ? AppColors.success.shade50
                          : AppColors.error.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      staffMember.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: staffMember.isActive
                            ? AppColors.success.shade700
                            : AppColors.error.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return Center(
          child: ModernCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No staff members found.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
