import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

    return Drawer(
      child: Obx(() { // Use Obx to react to user changes
        final User? user = authService.user.value;
        final roleName = user?.role;

        return ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(context, user),
            if (roleName == UserRole.merchant.name)
              ..._buildMerchantMenuItems(),
            if (roleName == UserRole.staff.name)
              ..._buildStaffMenuItems(),
            if (roleName == UserRole.admin.name)
              ..._buildAdminMenuItems(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authService.logout();
                Get.offAllNamed(Routes.LOGIN); 
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, User? user) {
    if (user == null) {
      return const DrawerHeader(
        decoration: BoxDecoration(
          color: Colors.grey,
        ),
        child: Text(
          'Not Logged In',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      );
    }
    
    return UserAccountsDrawerHeader(
      accountName: Text(user.name),
      accountEmail: Text(user.email),
      currentAccountPicture: CircleAvatar(
        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
      ),
      otherAccountsPictures: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(user.role.capitalizeFirst ?? '', style: const TextStyle(color: Colors.white)),
        )
      ],
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  List<Widget> _buildMerchantMenuItems() {
    return [
      _buildDrawerItem(icon: Icons.dashboard_outlined, text: 'Dashboard', route: Routes.MERCHANT_DASHBOARD),
      _buildDrawerItem(icon: Icons.people_outline, text: 'Staffs', route: Routes.MERCHANT_STAFF),
      _buildDrawerItem(icon: Icons.store_outlined, text: 'Shops', route: Routes.MERCHANT_SHOPS),
      _buildDrawerItem(icon: Icons.inventory_2_outlined, text: 'Stocks', route: Routes.MERCHANT_INVENTORY),
      _buildDrawerItem(icon: Icons.local_shipping_outlined, text: 'Suppliers', route: Routes.MERCHANT_SUPPLIERS),
      _buildDrawerItem(icon: Icons.point_of_sale_outlined, text: 'POS', route: Routes.MERCHANT_POS),
    ];
  }

  List<Widget> _buildStaffMenuItems() {
    return [
      _buildDrawerItem(icon: Icons.dashboard_outlined, text: 'Dashboard', route: Routes.STAFF_DASHBOARD),
      _buildDrawerItem(icon: Icons.store_outlined, text: 'Shop', route: Routes.SHOP_DASHBOARD),
      _buildDrawerItem(icon: Icons.inventory_2_outlined, text: 'Inventory', route: Routes.SHOP_INVENTORY),
      _buildDrawerItem(icon: Icons.point_of_sale_outlined, text: 'POS', route: Routes.SHOP_POS),
      _buildDrawerItem(icon: Icons.person_outline, text: 'Profile', route: Routes.STAFF_PROFILE),
    ];
  }

  List<Widget> _buildAdminMenuItems() {
    return [
      _buildDrawerItem(icon: Icons.dashboard_outlined, text: 'Dashboard', route: Routes.ADMIN_DASHBOARD),
      _buildDrawerItem(icon: Icons.people_outlined, text: 'Users', route: Routes.ADMIN_USERS),
      _buildDrawerItem(icon: Icons.storefront_outlined, text: 'Merchants', route: Routes.ADMIN_MERCHANTS),
      _buildDrawerItem(icon: Icons.badge_outlined, text: 'Staff', route: Routes.ADMIN_STAFF),
      _buildDrawerItem(icon: Icons.store_mall_directory_outlined, text: 'Shops', route: Routes.ADMIN_SHOPS),
      _buildDrawerItem(icon: Icons.admin_panel_settings_outlined, text: 'Admins', route: Routes.ADMIN_ADMINS),
      _buildDrawerItem(icon: Icons.person_outline, text: 'Profile', route: Routes.ADMIN_PROFILE),
      _buildDrawerItem(icon: Icons.settings_outlined, text: 'Settings', route: Routes.ADMIN_SETTINGS),
    ];
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required String route}) {
    final bool isSelected = Get.currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Get.theme.colorScheme.primary : null),
      title: Text(text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onTap: () {
        Get.back();
        if (Get.currentRoute != route) {
          Get.offNamed(route);
        }
      },
    );
  }
}
