import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/printer_preferences_storage.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class PrinterSettingsController extends GetxController {
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  final RxDouble fontScale = 1.0.obs;
  final RxInt paperWidthMm = 80.obs;

  late bool _isDev;

  RxList<BluetoothDevice> get devices => _printerService.devices;
  RxBool get isScanning => _printerService.isScanning;
  Rxn<BluetoothDevice> get selectedDevice => _printerService.selectedDevice;
  RxList<String> get debugLogs => _printerService.debugLogs;

  @override
  void onInit() {
    super.onInit();
    _isDev = dotenv.env['APP_ENV'] == 'dev';
    getLogger('app').info(
      '[PRINTER SETTINGS CONTROLLER] Initialized - Mode: ${_isDev ? "DEV (Mock)" : "PROD (Real)"}',
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPreferences();
    await scan();
  }

  Future<void> _loadPreferences() async {
    final preferences = await PrinterPreferencesStorage.load();
    fontScale.value = preferences.fontScale;
    paperWidthMm.value = preferences.paperWidthMm;
  }

  Future<void> _savePreferences() async {
    await PrinterPreferencesStorage.save(
      PrinterPreferences(
        paperWidthMm: paperWidthMm.value,
        fontScale: fontScale.value,
      ),
    );
  }

  Future<void> setFontScale(double value) async {
    fontScale.value = value;
    await _savePreferences();
  }

  Future<void> setPaperWidth(int value) async {
    paperWidthMm.value = value;
    await _savePreferences();
  }

  Future<void> scan() async {
    getLogger('app').info(
      '[PRINTER SETTINGS CONTROLLER] Starting device scan (${_isDev ? "Mock" : "Real"})',
    );
    await _printerService.scanForDevices();
    if (_isDev) {
      getLogger('app').info(
        '[PRINTER SETTINGS CONTROLLER] Mock devices will be returned for testing',
      );
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    getLogger('app').info(
      '[PRINTER SETTINGS CONTROLLER] Connecting to device: ${device.name} (${_isDev ? "Mock" : "Real"})',
    );
    await _printerService.connectToDevice(device);
    if (_isDev) {
      getLogger('app').info(
        '[PRINTER SETTINGS CONTROLLER] Mock connection simulated for: ${device.name}',
      );
    }
  }

  Future<void> disconnect() async {
    final deviceName = selectedDevice.value?.name ?? 'Unknown';
    getLogger(
      'app',
    ).info('[PRINTER SETTINGS CONTROLLER] Disconnecting from: $deviceName');
    await _printerService.disconnect();
    getLogger(
      'app',
    ).info('[PRINTER SETTINGS CONTROLLER] Disconnected successfully');
  }

  void clearDebugLogs() {
    _printerService.clearDebugLogs();
  }
}
