import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/modules/shop_settings/shop_settings_controller.dart';
import 'package:smart_retail/app/widgets/cards/data_sync_card.dart';

class ShopSettingsView extends GetView<ShopSettingsController> {
  const ShopSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // _buildSectionTitle(context, 'Appearance'),
          // const SizedBox(height: 8),
          // _buildThemeSettings(),
          // const Divider(height: 32),
          _buildSectionTitle(context, 'Data & Sync'),
          const SizedBox(height: 8),
          const DataSyncCard(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Hardware'),
          const SizedBox(height: 8),
          _buildPrinterSettings(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  // Widget _buildThemeSettings() {
  //   return Obx(() => SwitchListTile(
  //         title: const Text('Dark Mode'),
  //         subtitle: const Text('Enable or disable the dark theme.'),
  //         value: controller.isDarkMode.value,
  //         onChanged: (value) {
  //           controller.toggleTheme(value);
  //         },
  //       ));
  // }

  Widget _buildPrinterSettings() {
    return ListTile(
      title: const Text('Printer Settings'),
      subtitle: const Text('Manage Bluetooth receipt printers'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed(Routes.SHOP_PRINTER_SETTINGS),
    );
  }
}
