import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/admins/admins_admin_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class AdminsAdminView extends GetView<AdminsAdminController> {
  const AdminsAdminView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Manage Admins',
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
                  Icon(Icons.error_outline, size: 64, color: AppColors.error.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading admins',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(controller.errorMessage.value!, textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.admins.length,
          itemBuilder: (context, index) {
            final admin = controller.admins[index];
            return ModernCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.admin.shade100,
                  child: Icon(Icons.admin_panel_settings, color: AppColors.admin),
                ),
                title: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(admin.email),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: admin.isActive ? AppColors.success.shade50 : AppColors.error.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    admin.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: admin.isActive ? AppColors.success.shade700 : AppColors.error.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
