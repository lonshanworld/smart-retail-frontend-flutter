import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/shop_customers/shop_customers_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_data_table.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopCustomersView extends GetView<ShopCustomersController> {
  const ShopCustomersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Shop Customers',
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      controller.errorMessage.value!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (controller.filteredCustomers.isEmpty) {
                return const Center(
                  child: Text('No customers found for this shop.'),
                );
              }
              return _buildCustomerList();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(),
        label: const Text('Add Customer'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          labelText: 'Search by name, email, or phone',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    return ResponsiveDataTable(
      items: controller.filteredCustomers,
      columns: [
        DataColumn(
          label: const Text(
            'Customer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: const Text(
            'Phone',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: const Text(
            'Joined',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      buildCells: (customer) {
        return [
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.shop.shade100,
                  child: Icon(
                    Icons.person,
                    color: AppColors.shop.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          DataCell(
            Text(
              customer.email ?? '-',
              style: TextStyle(
                fontSize: 13,
                fontStyle: customer.email == null ? FontStyle.italic : null,
                color: customer.email == null ? Colors.grey : null,
              ),
            ),
          ),
          DataCell(
            customer.phone != null
                ? Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        customer.phone!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  )
                : Text(
                    '-',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
          ),
          DataCell(
            Text(
              DateFormat.yMMMd().format(customer.createdAt),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ];
      },
      buildMobileCard: (customer) {
        return DataRowCard(
          leading: CircleAvatar(
            backgroundColor: AppColors.shop.shade100,
            child: Icon(Icons.person, color: AppColors.shop.shade700, size: 20),
          ),
          title: customer.name,
          subtitle: customer.email,
          details: [
            if (customer.phone != null)
              DetailRow(
                icon: Icons.phone,
                label: 'Phone',
                value: customer.phone!,
              ),
            DetailRow(
              icon: Icons.calendar_today,
              label: 'Joined',
              value: DateFormat.yMMMd().format(customer.createdAt),
            ),
          ],
        );
      },
      headingRowColor: AppColors.shop.shade50,
    );
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: const Text('Add New Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !GetUtils.isEmail(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final customerData = {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                };
                Get.back(); // Close dialog
                controller.createNewCustomer(customerData);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
