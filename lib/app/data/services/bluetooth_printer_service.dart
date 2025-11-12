import 'package:get/get.dart';

// NOTE: You will need to add a Bluetooth printing package to your pubspec.yaml
// For example: blue_thermal_printer: ^1.1.5

class BluetoothPrinterService extends GetxService {
  // final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  var devices = [].obs;
  var isScanning = false.obs;
  var selectedDevice = Rxn();

  /// Scans for available Bluetooth devices.
  Future<void> scanForDevices() async {
    isScanning.value = true;
    try {
      // devices.value = await _bluetooth.getBondedDevices();
    } catch (e) {
      Get.snackbar('Error', 'Failed to get Bluetooth devices: $e');
    } finally {
      isScanning.value = false;
    }
  }

  /// Connects to a selected Bluetooth device.
  Future<void> connectToDevice(device) async {
    if (device == null) return;
    try {
      // await _bluetooth.connect(device);
      selectedDevice.value = device;
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect to device: $e');
    }
  }

  /// Disconnects from the currently connected device.
  Future<void> disconnect() async {
    try {
      // await _bluetooth.disconnect();
      selectedDevice.value = null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to disconnect: $e');
    }
  }

  /// Prints a sales voucher.
  /// 
  /// This method will format the voucher text and send it to the connected printer.
  /// The [fontSize] and [paperWidth] parameters will allow for customization.
  Future<void> printVoucher(String voucherText, {int fontSize = 1, int paperWidth = 58}) async {
    // if ((await _bluetooth.isConnected) ?? false) {
    //   _bluetooth.printCustom(voucherText, fontSize, paperWidth);
    // }
  }
}
