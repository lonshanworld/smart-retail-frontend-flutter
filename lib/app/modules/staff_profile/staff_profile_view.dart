import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import './staff_profile_controller.dart';

class StaffProfileView extends GetView<StaffProfileController> {
  const StaffProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'My Profile',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchUserProfile(),
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }
        final user = controller.userProfile.value;
        if (user == null) {
          return const Center(child: Text('No profile data found.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Details', style: Get.textTheme.headlineSmall),
                  const Divider(),
                  const SizedBox(height: 16),
                  ListTile(title: const Text('Name'), subtitle: Text(user.name)),
                  ListTile(title: const Text('Email'), subtitle: Text(user.email)),
                  ListTile(title: const Text('Role'), subtitle: Text(user.role.capitalizeFirst ?? user.role)),
                  ListTile(title: const Text('Phone Number'), subtitle: Text(user.phone ?? 'Not provided')),
                  ListTile(title: const Text('Assigned Shop ID'), subtitle: Text(user.assignedShopId ?? 'None')),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
