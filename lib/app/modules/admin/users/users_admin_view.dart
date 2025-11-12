import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/modules/admin/users/users_admin_controller.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class UsersAdminView extends GetView<UsersAdminController> {
  const UsersAdminView({super.key});

  // --- HELPER FOR ACTIONS POPUP MENU ---
  Widget _buildActionsMenu(BuildContext context, User user, UsersAdminController controller) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (String value) {
        switch (value) {
          case 'view':
            controller.goToUserDetailsPage(user);
            break;
          case 'edit':
            controller.goToEditUserPage(user);
            break;
          case 'delete':
            controller.deleteUser(user.id, user.name);
            break;
          case 'toggle_status':
            controller.toggleUserStatus(user);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'view',
          child: ListTile(leading: Icon(Icons.visibility_outlined), title: Text('View Detail')),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
        ),
        PopupMenuItem<String>(
          value: 'toggle_status',
          child: ListTile(
            leading: Icon(user.isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined),
            title: Text(user.isActive ? 'Deactivate' : 'Activate'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Manage Users',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddUserPage,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add User"),
        backgroundColor: AppColors.admin,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchUsers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  )
                ],
              ),
            ),
          );
        }

        if (controller.users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No users found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add First User'),
                  onPressed: controller.goToAddUserPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: AppColors.admin,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchUsers(),
          child: ResponsiveDataTable<User>(
            items: controller.users,
            columns: [
              DataColumn(
                label: const Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            buildCells: (user) {
              final isActive = user.isActive;
              final roleColor = _getRoleColor(user.role);
              
              return [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: roleColor.shade100,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: roleColor.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user.roleAsEnum == UserRole.staff && user.merchantName != null)
                              Text(
                                user.merchantName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => controller.goToUserDetailsPage(user),
                ),
                DataCell(
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => controller.goToUserDetailsPage(user),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleColor.shade300),
                    ),
                    child: Text(
                      user.roleDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: roleColor.shade700,
                      ),
                    ),
                  ),
                  onTap: () => controller.goToUserDetailsPage(user),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? AppColors.success.shade50 
                          : AppColors.error.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive 
                            ? AppColors.success.shade300 
                            : AppColors.error.shade300,
                      ),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive 
                            ? AppColors.success.shade700 
                            : AppColors.error.shade700,
                      ),
                    ),
                  ),
                  onTap: () => controller.goToUserDetailsPage(user),
                ),
                DataCell(
                  controller.isUpdatingStatus.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : _buildActionsMenu(context, user, controller),
                ),
              ];
            },
            buildMobileCard: (user) {
              final isActive = user.isActive;
              final roleColor = _getRoleColor(user.role);
              
              return DataRowCard(
                leading: CircleAvatar(
                  backgroundColor: roleColor.shade100,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: roleColor.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: user.name,
                subtitle: user.email,
                statusColor: isActive ? AppColors.success : AppColors.error,
                statusText: isActive ? 'Active' : 'Inactive',
                details: [
                  DetailRow(
                    icon: Icons.badge,
                    label: 'Role',
                    value: user.roleDisplay,
                    valueColor: roleColor.shade700,
                    valueFontWeight: FontWeight.w600,
                  ),
                  if (user.roleAsEnum == UserRole.staff && user.merchantName != null)
                    DetailRow(
                      icon: Icons.business,
                      label: 'Merchant',
                      value: user.merchantName!,
                    ),
                ],
                trailing: controller.isUpdatingStatus.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : _buildActionsMenu(context, user, controller),
                onTap: () => controller.goToUserDetailsPage(user),
              );
            },
            headingRowColor: AppColors.admin.shade50,
          ),
        );
      }),
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
}
