import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

class ShopDrawer extends StatelessWidget {
  const ShopDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.store,
                  size: 50,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Staff Menu', // Corrected Title
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: Get.currentRoute == Routes.SHOP_DASHBOARD,
            onTap: () => _navigateTo(Routes.SHOP_DASHBOARD),
          ),
          // CORRECTED: Used the correct staff-specific routes
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            selected: Get.currentRoute == Routes.STAFF_PROFILE,
            onTap: () => _navigateTo(Routes.STAFF_PROFILE),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title: const Text('Salary'),
            selected: Get.currentRoute == Routes.STAFF_SALARY,
            onTap: () => _navigateTo(Routes.STAFF_SALARY),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    // Close the drawer first
    Get.back();
    // Use offAndToNamed to prevent building up a stack of dashboard pages
    if (Get.currentRoute != route) {
      Get.offAndToNamed(route);
    }
  }

  Future<void> _handleLogout() async {
    final AuthService authService = Get.find<AuthService>();
    await authService.logout();
    Get.offAllNamed(Routes.SHOP_LOGIN);
  }
}
