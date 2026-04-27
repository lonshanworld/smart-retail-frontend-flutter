import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_retail/app/services/licensing/license_model.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class LicenseBlockedView extends StatelessWidget {
  final LicenseValidationResult result;

  const LicenseBlockedView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A21),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'License blocked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.isTamperSuspected
                            ? 'This installation was stopped because the environment looks unsafe.'
                            : 'This device is not authorized to run the app with the current license.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _InfoTile(
                        title: 'Reason',
                        value: result.message,
                      ),
                      const SizedBox(height: 12),
                      _InfoTile(
                        title: 'Current device fingerprint',
                        value: result.currentDeviceFingerprint ?? 'Unavailable',
                      ),
                      if (result.license != null) ...[
                        const SizedBox(height: 12),
                        _InfoTile(
                          title: 'Licensed user',
                          value: result.license!.user,
                        ),
                        const SizedBox(height: 12),
                        _InfoTile(
                          title: 'License expiry',
                          value: _formatDate(result.license!.expiry),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final report = _buildReport();
                                await Clipboard.setData(ClipboardData(text: report));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('License report copied.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Copy report'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => SystemNavigator.pop(),
                              icon: const Icon(Icons.exit_to_app_rounded),
                              label: const Text('Exit app'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.shop,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Contact support with the screenshot or copied report to reissue the license for this device.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildReport() {
    final buffer = StringBuffer()
      ..writeln('Nanonux Business Central license blocked')
      ..writeln('Reason: ${result.message}')
      ..writeln('Tamper suspected: ${result.isTamperSuspected}')
      ..writeln('Device fingerprint: ${result.currentDeviceFingerprint ?? 'Unavailable'}');

    final license = result.license;
    if (license != null) {
      buffer
        ..writeln('Licensed user: ${license.user}')
        ..writeln('License device: ${license.device}')
        ..writeln('License expiry: ${_formatDate(license.expiry)}');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}