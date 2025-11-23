import 'package:flutter/material.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';

class SettingsAdminView extends StatelessWidget {
  const SettingsAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Admin Settings',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No settings available at this time',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
