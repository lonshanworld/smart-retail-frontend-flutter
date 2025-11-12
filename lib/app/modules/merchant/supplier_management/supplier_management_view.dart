import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/supplier_management/supplier_management_controller.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';

class SupplierManagementView extends GetView<SupplierManagementController> {
  const SupplierManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Manage Suppliers',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add New Supplier', style: Get.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildSupplierForm(),
            const SizedBox(height: 24),
            Text('Existing Suppliers', style: Get.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(child: _buildSupplierList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierForm() {
    return Form(
      key: controller.formKey,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          TextFormField(
            controller: controller.nameController,
            decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder()),
            validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
          ),
          TextFormField(
            controller: controller.contactNameController,
            decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder()),
          ),
          TextFormField(
            controller: controller.contactEmailController,
            decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          TextFormField(
            controller: controller.contactPhoneController,
            decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          TextFormField(
            controller: controller.addressController,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
          ),
          TextFormField(
            controller: controller.notesController,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          Obx(() => ElevatedButton.icon(
                icon: controller.isSaving.value
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: Text(controller.isSaving.value ? 'Saving...' : 'Add Supplier'),
                onPressed: controller.isSaving.value ? null : () => controller.createSupplier(),
              )),
        ],
      ),
    );
  }

  Widget _buildSupplierList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.value != null) {
        return Center(
          child: ModernCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text('Error: ${controller.errorMessage.value}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      }
      if (controller.suppliers.isEmpty) {
        return Center(
          child: ModernCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No suppliers found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Add your first supplier using the form above.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      }
      return ResponsiveDataTable(
        items: controller.suppliers,
        columns: [
          DataColumn(label: const Text('Supplier Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: const Text('Contact Person', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        buildCells: (supplier) {
          return [
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.merchant.shade100,
                    child: Icon(Icons.local_shipping, color: AppColors.merchant.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                supplier.contactName ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: supplier.contactName == null ? FontStyle.italic : null,
                  color: supplier.contactName == null ? Colors.grey : null,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  if (supplier.contactPhone != null) ...[
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      supplier.contactPhone ?? '-',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: supplier.contactPhone == null ? FontStyle.italic : null,
                        color: supplier.contactPhone == null ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                supplier.contactEmail ?? '-',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: supplier.contactEmail == null ? FontStyle.italic : null,
                  color: supplier.contactEmail == null ? Colors.grey : null,
                ),
              ),
            ),
          ];
        },
        buildMobileCard: (supplier) {
          return DataRowCard(
            leading: CircleAvatar(
              backgroundColor: AppColors.merchant.shade100,
              child: Icon(Icons.local_shipping, color: AppColors.merchant.shade700, size: 20),
            ),
            title: supplier.name,
            subtitle: supplier.contactName,
            details: [
              if (supplier.contactPhone != null)
                DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: supplier.contactPhone!,
                ),
              if (supplier.contactEmail != null)
                DetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: supplier.contactEmail!,
                ),
            ],
          );
        },
        headingRowColor: AppColors.merchant.shade50,
      );
    });
  }
}
