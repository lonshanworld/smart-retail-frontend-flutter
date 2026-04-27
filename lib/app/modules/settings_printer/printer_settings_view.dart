import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'package:smart_retail/app/modules/settings_printer/printer_settings_controller.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class PrinterSettingsView extends GetView<PrinterSettingsController> {
  const PrinterSettingsView({super.key});

  bool get _isDev => dotenv.env['APP_ENV'] == 'dev';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        backgroundColor: AppColors.shop,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Builder(
        builder: (scaffoldContext) => Scrollbar(
          controller: controller.pageScrollController,
          child: SingleChildScrollView(
            controller: controller.pageScrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildPrintOptionsCard(),
                const SizedBox(height: 20),
                _buildConnectionCard(),
                const SizedBox(height: 20),
                _buildDevicesSection(),
                const SizedBox(height: 20),
                _buildDebugLogCard(scaffoldContext),
                if (_isDev) ...[const SizedBox(height: 20), _buildTestButton()],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.shop.shade700, AppColors.shop.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.print_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bluetooth Printer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isDev
                      ? 'Development mode with mock helpers'
                      : 'Production mode using real Bluetooth devices',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintOptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Print Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Font size',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(controller.fontScale.value * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.shop.shade700,
                  ),
                ),
              ],
            ),
            Slider(
              min: 0.8,
              max: 1.8,
              divisions: 10,
              value: controller.fontScale.value,
              label: '${(controller.fontScale.value * 100).round()}%',
              activeColor: AppColors.shop,
              onChanged: (value) {
                controller.setFontScale(value);
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paper width',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${controller.paperWidthMm.value} mm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.shop.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PaperWidthChip(
                  label: '58 mm',
                  selected: controller.paperWidthMm.value == 58,
                  onTap: () => controller.setPaperWidth(58),
                ),
                _PaperWidthChip(
                  label: '80 mm',
                  selected: controller.paperWidthMm.value == 80,
                  onTap: () => controller.setPaperWidth(80),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Printer transport',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('Classic Bluetooth'),
                          selected: !controller.isBleMode,
                          onSelected: (_) =>
                              controller.setTransportMode('classic'),
                          selectedColor: AppColors.shop.shade100,
                          labelStyle: TextStyle(
                            color: !controller.isBleMode
                                ? AppColors.shop.shade900
                                : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: !controller.isBleMode
                                ? AppColors.shop
                                : Colors.grey.shade300,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('BLE only'),
                          selected: controller.isBleMode,
                          onSelected: (_) => controller.setTransportMode('ble'),
                          selectedColor: AppColors.shop.shade100,
                          labelStyle: TextStyle(
                            color: controller.isBleMode
                                ? AppColors.shop.shade900
                                : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: controller.isBleMode
                                ? AppColors.shop
                                : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    if (controller.isBleMode) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller.bleServiceUuidController,
                        decoration: const InputDecoration(
                          labelText: 'BLE Service UUID',
                          hintText: '0000ffff-0000-1000-8000-00805f9b34fb',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller.bleCharacteristicUuidController,
                        decoration: const InputDecoration(
                          labelText: 'BLE Characteristic UUID',
                          hintText: '0000ff01-0000-1000-8000-00805f9b34fb',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the UUIDs from the printer manual or vendor app. BLE printers usually need a writable characteristic.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.square_rounded, color: Colors.black87, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Black & white only. The printer output is rasterized as a monochrome image.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Obx(() {
      final device = controller.selectedDevice.value;
      final connected = device != null;
      final transportLabel = controller.connectedTransport.value == 'ble'
          ? 'BLE only'
          : 'Classic Bluetooth';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: connected ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: connected ? Colors.green : Colors.orange),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  connected ? Icons.check_circle : Icons.info,
                  color: connected
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected
                            ? 'Current connected device'
                            : 'No printer connected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: connected
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connected
                            ? 'The printer below is the one currently selected for printing.'
                            : 'Scan and select a paired thermal printer',
                        style: TextStyle(
                          fontSize: 12,
                          color: connected
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (connected)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current device',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        device.name ?? 'Unknown device',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(
                            icon: Icons.bluetooth_rounded,
                            label: transportLabel,
                          ),
                          _StatusChip(
                            icon: Icons.link_rounded,
                            label: 'Ready to print',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: controller.disconnect,
                          icon: const Icon(Icons.link_off_rounded),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _StatusChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.green.shade800),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${controller.devices.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Obx(
                    () => controller.isScanning.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bluetooth_searching),
                  ),
                  label: Obx(
                    () => Text(
                      controller.isScanning.value
                          ? 'Scanning...'
                          : controller.isBleMode
                          ? 'Scan BLE devices'
                          : 'Scan for devices',
                    ),
                  ),
                  onPressed: controller.isScanning.value
                      ? null
                      : controller.scan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shop,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, _) {
              final maxListHeight = (MediaQuery.sizeOf(context).height * 0.32)
                  .clamp(180.0, 320.0)
                  .toDouble();

              return Obx(() {
                if (controller.devices.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No devices found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.isBleMode
                              ? 'Turn on the BLE printer, make sure it is advertising, then scan again.'
                              : 'Turn on the thermal printer, pair it from Bluetooth settings, then scan again.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: Scrollbar(
                    controller: controller.devicesScrollController,
                    thumbVisibility: controller.devices.length > 3,
                    child: ListView.separated(
                      controller: controller.devicesScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: controller.devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(controller.devices[index]);
                      },
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    return Obx(() {
      final isSelected = controller.selectedDevice.value == device;
      return Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.shop.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.shop : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.shop : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name ?? 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.shop,
                    size: 24,
                  ),
                )
              else
                SizedBox(
                  width: 92,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.connect(device);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shop.shade100,
                      foregroundColor: AppColors.shop,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Connect'),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDebugLogCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.shop.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bug_report_rounded,
                    color: AppColors.shop.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printer debug log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Open the full printer log in a bottom sheet.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${controller.debugLogs.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDebugLogBottomSheet(context),
                    icon: const Icon(Icons.subject_rounded),
                    label: const Text('Open log sheet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.shop,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.debugLogs.isEmpty
                        ? null
                        : controller.clearDebugLogs,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Clear log'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.shop.shade700,
                      side: BorderSide(color: AppColors.shop.shade200),
                      disabledForegroundColor: Colors.black38,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              controller.debugLogs.isEmpty
                  ? 'No printer events yet. Scan or connect a printer, then open the sheet.'
                  : 'The sheet includes scan, connection, permission, and print output entries.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugLogBottomSheet(BuildContext context) {
    Scaffold.of(context).showBottomSheet(
      (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Obx(() {
                final logs = controller.debugLogs.toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.shop.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.print_rounded,
                            color: AppColors.shop.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Printer log history',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Scroll vertically to read every printer event in order.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${logs.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.info.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: logs.isEmpty
                                ? null
                                : () async {
                                    final text = logs.join('\n');
                                    await Clipboard.setData(
                                      ClipboardData(text: text),
                                    );
                                    Get.snackbar(
                                      'Copied',
                                      'Printer debug log copied to clipboard.',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy all'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.shop.shade700,
                              side: BorderSide(color: AppColors.shop.shade200),
                              disabledForegroundColor: Colors.black38,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: logs.isEmpty
                                ? null
                                : controller.clearDebugLogs,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.red.shade200,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: logs.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No printer events yet.\n\nScan, connect, or print something to populate this sheet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              )
                            : Scrollbar(
                                controller: controller.debugLogScrollController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  controller:
                                      controller.debugLogScrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: logs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (sheetContext, index) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: SelectableText(
                                        logs[index],
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
      backgroundColor: Colors.white,
      elevation: 18,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.print_rounded),
        label: const Text('Test Print'),
        onPressed: _showTestPrintDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showTestPrintDialog() {
    DialogUtils.showCustomDialog(
      dialog: AlertDialog(
        title: const Text('Test Print'),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current print setup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Device: ${controller.selectedDevice.value?.name ?? 'No device selected'}',
                    ),
                    Text('Paper width: ${controller.paperWidthMm.value} mm'),
                    Text(
                      'Font size: ${(controller.fontScale.value * 100).round()}%',
                    ),
                    const Text('Color mode: Black & white only'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This sends a sample raster receipt to the connected printer.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              controller.logPrinterEvent(
                '[PRINTER SETTINGS] Sending mock print...',
              );
              Get.back();
              DialogUtils.showInfo('Test print triggered.');
            },
            child: const Text('Send Print'),
          ),
        ],
      ),
    );
  }
}

class _PaperWidthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaperWidthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.shop.shade100,
      labelStyle: TextStyle(
        color: selected ? AppColors.shop.shade900 : Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? AppColors.shop : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
