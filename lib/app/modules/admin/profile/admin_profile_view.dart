import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/profile/admin_profile_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';

class AdminProfileView extends GetView<AdminProfileController> {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'My Profile',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value != null) {
          return Center(
            child: Text(
              'Error: ${controller.errorMessage.value}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (controller.userProfile.value == null) {
          return const Center(child: Text('Could not load profile.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Email: ${controller.userProfile.value!.email}',
                      style: Get.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${controller.userProfile.value!.role.capitalizeFirst}',
                      style: Get.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                        ), // <<< CORRECTED ICON
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (controller.passwordController.text.isNotEmpty &&
                            value != controller.passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      if (controller.formError.value != null) {
                        return Text(
                          controller.formError.value!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Obx(
                        () => controller.isSaving.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_alt_outlined),
                      ),
                      label: Obx(
                        () => Text(
                          controller.isSaving.value
                              ? 'Saving...'
                              : 'Update Profile',
                        ),
                      ),
                      onPressed: controller.isSaving.value
                          ? null
                          : () => controller.updateProfile(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
