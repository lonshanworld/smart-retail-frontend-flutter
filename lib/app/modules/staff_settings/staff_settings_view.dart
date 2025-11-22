import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/cards/data_sync_card.dart';
import './staff_settings_controller.dart';

class StaffSettingsView extends GetView<StaffSettingsController> {
  const StaffSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'Data & Sync'),
          const SizedBox(height: 8),
          const DataSyncCard(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Hardware'),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Printer Settings'),
            subtitle: const Text('Configure receipt and order printers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.toNamed(Routes.STAFF_PRINTER_SETTINGS),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}
