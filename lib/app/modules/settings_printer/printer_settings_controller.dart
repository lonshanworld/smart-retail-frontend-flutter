import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/printer_preferences_storage.dart';
import 'package:smart_retail/app/data/services/printer_storage.dart';

class PrinterSettingsController extends GetxController {
  final BluetoothPrinterService _printerService =
      Get.find<BluetoothPrinterService>();

  final ScrollController pageScrollController = ScrollController();
  final ScrollController devicesScrollController = ScrollController();
  final ScrollController debugLogScrollController = ScrollController();

  final RxDouble fontScale = 1.0.obs;
  final RxInt paperWidthMm = 80.obs;
  final RxInt printContentWidthPercent = 92.obs;
  final RxString transportMode = 'classic'.obs;
  final RxString voucherHeaderShopName = ''.obs;
  final RxString voucherHeaderAddress = ''.obs;
  final RxString voucherHeaderContact = ''.obs;
  final TextEditingController bleServiceUuidController =
      TextEditingController();
  final TextEditingController bleCharacteristicUuidController =
      TextEditingController();
  final TextEditingController voucherHeaderShopNameController =
      TextEditingController();
  final TextEditingController voucherHeaderAddressController =
      TextEditingController();
  final TextEditingController voucherHeaderContactController =
      TextEditingController();

  late bool _isDev;

  RxList<BluetoothDevice> get devices => _printerService.devices;
  RxBool get isScanning => _printerService.isScanning;
  Rxn<BluetoothDevice> get selectedDevice => _printerService.selectedDevice;
  RxString get connectedTransport => _printerService.selectedTransport;
  RxList<String> get debugLogs => _printerService.debugLogs;

  bool get isBleMode => transportMode.value == 'ble';

  void logPrinterEvent(String message) {
    _printerService.logDebug(message);
  }

  Future<void> setTransportMode(String value) async {
    transportMode.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    _isDev = dotenv.env['APP_ENV'] == 'dev';
    logPrinterEvent(
      '[PRINTER SETTINGS CONTROLLER] Initialized - Mode: ${_isDev ? "DEV (Mock)" : "PROD (Real)"}',
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPreferences();
    await _loadPrinterSelection();
    await scan();
  }

  Future<void> _loadPreferences() async {
    final preferences = await PrinterPreferencesStorage.load();
    fontScale.value = preferences.fontScale;
    paperWidthMm.value = preferences.paperWidthMm;
    printContentWidthPercent.value = preferences.printContentWidthPercent;
    voucherHeaderShopName.value = preferences.voucherHeaderShopName;
    voucherHeaderAddress.value = preferences.voucherHeaderAddress;
    voucherHeaderContact.value = preferences.voucherHeaderContact;
    voucherHeaderShopNameController.text = preferences.voucherHeaderShopName;
    voucherHeaderAddressController.text = preferences.voucherHeaderAddress;
    voucherHeaderContactController.text = preferences.voucherHeaderContact;
  }

  Future<void> _savePreferences() async {
    await PrinterPreferencesStorage.save(
      PrinterPreferences(
        paperWidthMm: paperWidthMm.value,
        fontScale: fontScale.value,
        printContentWidthPercent: printContentWidthPercent.value,
        voucherHeaderShopName: voucherHeaderShopName.value,
        voucherHeaderAddress: voucherHeaderAddress.value,
        voucherHeaderContact: voucherHeaderContact.value,
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

  Future<void> setPrintContentWidthPercent(double value) async {
    printContentWidthPercent.value = value.round();
    await _savePreferences();
  }

  Future<void> setVoucherHeaderShopName(String value) async {
    voucherHeaderShopName.value = value.trim();
    await _savePreferences();
  }

  Future<void> setVoucherHeaderAddress(String value) async {
    voucherHeaderAddress.value = value.trim();
    await _savePreferences();
  }

  Future<void> setVoucherHeaderContact(String value) async {
    voucherHeaderContact.value = value.trim();
    await _savePreferences();
  }

  Future<void> saveVoucherHeaderFields() async {
    await setVoucherHeaderShopName(voucherHeaderShopNameController.text);
    await setVoucherHeaderAddress(voucherHeaderAddressController.text);
    await setVoucherHeaderContact(voucherHeaderContactController.text);
  }

  Future<void> _loadPrinterSelection() async {
    final selection = await PrinterStorage.loadSelection();
    if (selection == null) {
      return;
    }

    transportMode.value = selection.transport;
    bleServiceUuidController.text = selection.serviceUuid ?? '';
    bleCharacteristicUuidController.text = selection.charUuid ?? '';
  }

  Future<void> scan() async {
    final mode = transportMode.value;
    logPrinterEvent(
      '[PRINTER SETTINGS CONTROLLER] Starting ${mode.toUpperCase()} device scan (${_isDev ? "Mock" : "Real"})',
    );
    if (mode == 'ble') {
      await _printerService.scanBleForDevices();
    } else {
      await _printerService.scanForDevices();
    }
    if (_isDev) {
      logPrinterEvent(
        '[PRINTER SETTINGS CONTROLLER] Mock devices will be returned for testing',
      );
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    final mode = transportMode.value;
    logPrinterEvent(
      '[PRINTER SETTINGS CONTROLLER] Connecting to device: ${device.name} (${mode.toUpperCase()}, ${_isDev ? "Mock" : "Real"})',
    );
    await _printerService.connectToDevice(
      device,
      transport: mode,
      bleServiceUuid: bleServiceUuidController.text.trim(),
      bleCharacteristicUuid: bleCharacteristicUuidController.text.trim(),
    );
    if (selectedDevice.value != null) {
      await PrinterStorage.saveSelection(
        PrinterSelection(
          transport: mode,
          deviceId: device.address ?? '',
          deviceName: device.name ?? 'Unknown Device',
          serviceUuid: mode == 'ble'
              ? bleServiceUuidController.text.trim()
              : null,
          charUuid: mode == 'ble'
              ? bleCharacteristicUuidController.text.trim()
              : null,
        ),
      );
    }
    if (_isDev) {
      logPrinterEvent(
        '[PRINTER SETTINGS CONTROLLER] Mock connection simulated for: ${device.name}',
      );
    }
  }

  Future<void> disconnect() async {
    final deviceName = selectedDevice.value?.name ?? 'Unknown';
    logPrinterEvent(
      '[PRINTER SETTINGS CONTROLLER] Disconnecting from: $deviceName',
    );
    await _printerService.disconnect();
    logPrinterEvent('[PRINTER SETTINGS CONTROLLER] Disconnected successfully');
  }

  void clearDebugLogs() {
    _printerService.clearDebugLogs();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    devicesScrollController.dispose();
    debugLogScrollController.dispose();
    bleServiceUuidController.dispose();
    bleCharacteristicUuidController.dispose();
    voucherHeaderShopNameController.dispose();
    voucherHeaderAddressController.dispose();
    voucherHeaderContactController.dispose();
    super.onClose();
  }
}
