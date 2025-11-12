import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/modules/merchant/staff/list/merchant_staff_list_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';

class MerchantStaffListView extends GetView<MerchantStaffListController> {
  const MerchantStaffListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Manage Staff',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.merchant.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage.value != null) {
            return Center(child: Text('Error: ${controller.errorMessage.value}'));
          }
          return _buildStaffList();
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
        onPressed: () => controller.goToAddStaff(),
        backgroundColor: AppColors.merchant,
      ),
    );
  }

  Widget _buildStaffList() {
    return ResponsiveDataTable<User>(
      items: controller.staffList,
      columns: [
        DataColumn(label: const Text('Staff', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: const Text('Shop', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      buildCells: (staff) {
        return [
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.staff.shade100,
                  child: Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                    style: TextStyle(color: AppColors.staff.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            onTap: () => controller.goToStaffDetails(staff),
          ),
          DataCell(
            Text(staff.email, style: const TextStyle(fontSize: 13)),
            onTap: () => controller.goToStaffDetails(staff),
          ),
          DataCell(
            staff.shopName != null
                ? Row(
                    children: [
                      Icon(Icons.storefront, size: 16, color: AppColors.shop.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          staff.shopName!,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text('-', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            onTap: () => controller.goToStaffDetails(staff),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: staff.isActive ? AppColors.success.shade50 : AppColors.error.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: staff.isActive ? AppColors.success.shade300 : AppColors.error.shade300,
                ),
              ),
              child: Text(
                staff.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: staff.isActive ? AppColors.success.shade700 : AppColors.error.shade700,
                ),
              ),
            ),
            onTap: () => controller.goToStaffDetails(staff),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  onPressed: () => controller.goToEditStaff(staff),
                  color: AppColors.merchant,
                ),
                // Delete button hidden due to foreign key constraints with stock_movements
              ],
            ),
          ),
        ];
      },
      buildMobileCard: (staff) {
        return DataRowCard(
          leading: CircleAvatar(
            backgroundColor: AppColors.staff.shade100,
            child: Text(
              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
              style: TextStyle(color: AppColors.staff.shade700, fontWeight: FontWeight.bold),
            ),
          ),
          title: staff.name,
          subtitle: staff.email,
          statusColor: staff.isActive ? AppColors.success : AppColors.error,
          statusText: staff.isActive ? 'Active' : 'Inactive',
          details: [
            if (staff.shopName != null)
              DetailRow(
                icon: Icons.storefront,
                label: 'Assigned Shop',
                value: staff.shopName!,
              ),
          ],
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') controller.goToEditStaff(staff);
              if (value == 'view') controller.goToStaffDetails(staff);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.visibility), title: Text('View'), contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
              // Delete option removed due to foreign key constraints with stock_movements
            ],
          ),
          onTap: () => controller.goToStaffDetails(staff),
        );
      },
      headingRowColor: AppColors.merchant.shade50,
    );
  }
}
