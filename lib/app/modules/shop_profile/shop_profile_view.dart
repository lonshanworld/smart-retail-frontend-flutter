import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/modules/shop_profile/shop_profile_controller.dart';

class ShopProfileView extends GetView<ShopProfileController> {
  const ShopProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'My Profile',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.user.value == null) {
          return const Center(child: Text('Could not load profile.'));
        }

        final user = controller.user.value!;
        final shop = controller.shop.value;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: Get.textTheme.headlineLarge),
                ),
                const SizedBox(height: 24),
                _buildProfileCard(user, shop),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard(User user, Shop? shop) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (shop != null) ...[
              _buildInfoRow(Icons.store, 'Shop Name', shop.name),
              _buildInfoRow(Icons.location_on, 'Shop Address', shop.address ?? 'N/A'),
              const Divider(),
            ],
            _buildInfoRow(Icons.person, 'Name', user.name),
            _buildInfoRow(Icons.email, 'Email', user.email),
            _buildInfoRow(Icons.work, 'Role', user.role.capitalizeFirst ?? user.role),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Get.theme.colorScheme.secondary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: Get.textTheme.bodyLarge),
    );
  }
}
