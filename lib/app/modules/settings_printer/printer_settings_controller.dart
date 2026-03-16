import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PrinterSettingsController extends GetxController {
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  late bool _isDev;

  // Make service observables available to the view
  RxList<BluetoothDevice> get devices => _printerService.devices;
  RxBool get isScanning => _printerService.isScanning;
  Rxn<BluetoothDevice> get selectedDevice => _printerService.selectedDevice;

  @override
  void onInit() {
    super.onInit();
    _isDev = dotenv.env['APP_ENV'] == 'dev';
    print(
      '⚙️ [PRINTER SETTINGS CONTROLLER] Initialized - Mode: ${_isDev ? "DEV (Mock)" : "PROD (Real)"}',
    );
    // Automatically scan for devices when the page is opened
    scan();
  }

  /// Initiates a scan for Bluetooth devices.
  /// In DEV mode: Returns mock devices
  /// In PROD mode: Scans for real Bluetooth devices
  void scan() {
    print(
      '🔍 [PRINTER SETTINGS CONTROLLER] Starting device scan (${_isDev ? "Mock" : "Real"})',
    );
    _printerService.scanForDevices();
    if (_isDev) {
      print(
        '📱 [PRINTER SETTINGS CONTROLLER] Mock devices will be returned for testing',
      );
    }
  }

  /// Connects to the selected device.
  /// In DEV mode: Simulates connection
  /// In PROD mode: Establishes real Bluetooth connection
  void connect(device) {
    print(
      '🔗 [PRINTER SETTINGS CONTROLLER] Connecting to device: ${device.name} (${_isDev ? "Mock" : "Real"})',
    );
    _printerService.connectToDevice(device);
    if (_isDev) {
      print(
        '✅ [PRINTER SETTINGS CONTROLLER] Mock connection simulated for: ${device.name}',
      );
    }
  }

  /// Disconnects from the current device.
  void disconnect() {
    final deviceName = selectedDevice.value?.name ?? 'Unknown';
    print('❌ [PRINTER SETTINGS CONTROLLER] Disconnecting from: $deviceName');
    _printerService.disconnect();
    print('✅ [PRINTER SETTINGS CONTROLLER] Disconnected successfully');
  }
}
