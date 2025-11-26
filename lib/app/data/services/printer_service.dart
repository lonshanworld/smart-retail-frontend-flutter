import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:smart_retail/app/data/services/printer_storage.dart';

class PrinterDevice {
  final String name;
  final String id;
  PrinterDevice({required this.name, required this.id});
}

class PrinterService extends GetxService {
  final BluetoothPrint _bp = BluetoothPrint.instance;
  final RxList<PrinterDevice> devices = <PrinterDevice>[].obs;
  StreamSubscription<List<BluetoothDevice>>? _scanSub;
  StreamSubscription<int>? _stateSub;
  bool _connected = false;
  // BLE client
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _bleScanSub;
  final RxList<PrinterDevice> bleDevices = <PrinterDevice>[].obs;
  StreamSubscription<ConnectionStateUpdate>? _bleConnectionSub;
  String? _connectedBleDeviceId;

  Future<void> init() async {
    // subscribe to scanResults and state
    _scanSub = _bp.scanResults.listen((List<BluetoothDevice> list) {
      devices.clear();
      for (var d in list) {
        // plugin's BluetoothDevice exposes `address` and `name`
        devices.add(PrinterDevice(name: d.name ?? 'Unknown', id: d.address ?? ''));
      }
    });

    _stateSub = _bp.state.listen((int state) {
      // state changes: you can map this to UI if needed
      // values: BluetoothPrint.CONNECTED (1) or DISCONNECTED (0)
    });

    // load last selection from storage
    try {
      final sel = await PrinterStorage.loadSelection();
      if (sel != null) {
        // set some defaults or keep somewhere for the UI to read
        // We'll not auto-connect here, but store values for the test UI
        // Expose via public fields if needed (kept simple)
        // If you want auto-connect on init, implement connect logic here.
      }
    } catch (_) {}
  }

  /// Return the saved printer selection from local storage (if any).
  Future<PrinterSelection?> getSavedSelection() async {
    try {
      return await PrinterStorage.loadSelection();
    } catch (e) {
      print('getSavedSelection error: $e');
      return null;
    }
  }

  /// Attempt to connect to the saved selection. Returns true on successful connect.
  Future<bool> quickConnectSaved() async {
    try {
      final sel = await PrinterStorage.loadSelection();
      if (sel == null) return false;
      final dev = PrinterDevice(name: sel.deviceName, id: sel.deviceId);
      if (sel.transport == 'ble') {
        if (sel.serviceUuid == null || sel.charUuid == null) return false;
        // try to connect to BLE device (do not perform a print here)
        return await connectBle(dev);
      } else {
        return await connect(dev);
      }
    } catch (e) {
      print('quickConnectSaved error: $e');
      return false;
    }
  }

  /// Clear any saved selection from local storage.
  Future<void> clearSavedSelection() async {
    try {
      await PrinterStorage.clearSelection();
    } catch (e) {
      print('clearSavedSelection error: $e');
    }
  }

  Future<void> disposeService() async {
    await _scanSub?.cancel();
    await _stateSub?.cancel();
    await _bleScanSub?.cancel();
    await _bleConnectionSub?.cancel();
  }

  Future<void> ensurePermissions() async {
    if (Platform.isAndroid) {
      await Permission.locationWhenInUse.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    } else if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
  }

  /// Scan for Bluetooth printers for [timeout]. Returns the discovered devices.
  Future<List<PrinterDevice>> scan({Duration timeout = const Duration(seconds: 4)}) async {
    await ensurePermissions();
    devices.clear();
    try {
      await _bp.startScan(timeout: timeout);
      // wait for results to accumulate
      await Future.delayed(timeout + const Duration(milliseconds: 200));
      await _bp.stopScan();
    } catch (e) {
      // ignore scan errors here
    }
    return devices;
  }

  /// BLE scan using flutter_reactive_ble. Returns discovered BLE devices.
  Future<List<PrinterDevice>> scanBle({Duration timeout = const Duration(seconds: 4)}) async {
    await ensurePermissions();
    bleDevices.clear();
    final results = <PrinterDevice>[];
    try {
      final stream = _ble.scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency);
      _bleScanSub = stream.listen((d) {
        final pd = PrinterDevice(name: d.name.isEmpty ? 'Unknown' : d.name, id: d.id);
        // avoid duplicates
        if (!bleDevices.any((e) => e.id == pd.id)) {
          bleDevices.add(pd);
          results.add(pd);
        }
      });
      await Future.delayed(timeout + const Duration(milliseconds: 200));
      await _bleScanSub?.cancel();
    } catch (e) {
      // ignore
    }
    return results;
  }

  /// Connect to a device by id (address or identifier)
  Future<bool> connect(PrinterDevice device, {Duration wait = const Duration(seconds: 3)}) async {
    try {
      // bluetooth_print expects a BluetoothDevice object from its model
      final bd = BluetoothDevice();
      bd.address = device.id;
      bd.name = device.name;
      await _bp.connect(bd);
      // give the plugin a moment to establish connection
      await Future.delayed(wait);
      _connected = true;
      return true;
    } catch (e) {
      _connected = false;
      return false;
    }
  }

  /// Connect to BLE device by id and maintain connection subscription.
  Future<bool> connectBle(PrinterDevice device) async {
    try {
      await _bleScanSub?.cancel();
      _bleConnectionSub?.cancel();
      _bleConnectionSub = _ble.connectToDevice(id: device.id).listen((event) {
        // handle state changes if needed
        if (event.connectionState == DeviceConnectionState.connected) {
          _connectedBleDeviceId = device.id;
        } else if (event.connectionState == DeviceConnectionState.disconnected) {
          if (_connectedBleDeviceId == device.id) _connectedBleDeviceId = null;
        }
      }, onError: (e) {
        _connectedBleDeviceId = null;
      });
      // wait a bit for connection
      await Future.delayed(const Duration(seconds: 2));
      return _connectedBleDeviceId == device.id;
    } catch (e) {
      _connectedBleDeviceId = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bp.disconnect();
    } catch (_) {}
    _connected = false;
  }

  Future<void> disconnectBle() async {
    try {
      await _bleConnectionSub?.cancel();
      // The current flutter_reactive_ble API may not expose a direct
      // disconnectDevice(...) method on the client in all versions.
      // Cancelling the connection subscription is sufficient to close
      // the connection for our usage here.
    } catch (_) {}
    _connectedBleDeviceId = null;
  }

  /// Print a simple text-based receipt using the plugin's high-level API.
  /// This avoids raw ESC/POS bytes and should work across many printers for testing.
  Future<bool> printTestReceipt() async {
    if (!_connected) {
      print('Printer not connected');
      return false;
    }

    // Build LineText objects as expected by bluetooth_print.printReceipt
    final List<LineText> data = [];
    data.add(LineText(type: LineText.TYPE_TEXT, content: '*** Test Receipt ***', align: LineText.ALIGN_CENTER, weight: 1, linefeed: 1));
    data.add(LineText(type: LineText.TYPE_TEXT, content: 'Timestamp: ${DateTime.now()}', align: LineText.ALIGN_LEFT, linefeed: 1));
    data.add(LineText(type: LineText.TYPE_TEXT, content: 'Thank you for testing', align: LineText.ALIGN_LEFT, linefeed: 1));
    // empty lines to feed
    data.add(LineText(type: LineText.TYPE_TEXT, content: '\n\n', linefeed: 1));

    try {
      await _bp.printReceipt(<String, dynamic>{}, data);
      return true;
    } catch (e) {
      print('printTestReceipt error: $e');
      return false;
    }
  }

  /// Print arbitrary ESC/POS bytes. Consumer is responsible to build proper ESC/POS bytes
  /// (for example with `flutter_esc_pos_utils` Generator) and then convert to text chunks
  /// or raw payloads depending on the plugin capabilities. Here we attempt to send as 'raw' base64.
  Future<bool> printBytes(Uint8List bytes) async {
    if (!_connected) {
      print('Printer not connected');
      return false;
    }
    try {
      // bluetooth_print does not expose a raw-bytes API; attempt to send as text
      final String text = utf8.decode(bytes, allowMalformed: true);
      final List<LineText> data = [LineText(type: LineText.TYPE_TEXT, content: text, linefeed: 1)];
      await _bp.printReceipt(<String, dynamic>{}, data);
      return true;
    } catch (e) {
      print('printBytes error: $e');
      return false;
    }
  }

  /// BLE: print a simple text message as bytes to a writable characteristic.
  /// This is a basic fallback — for robust ESC-POS printing supply the correct
  /// service/characteristic UUIDs and chunk ESC-POS bytes appropriately.
  Future<bool> blePrintTest({required PrinterDevice device, required Uuid serviceId, required Uuid charId}) async {
    if (_connectedBleDeviceId != device.id) {
      final ok = await connectBle(device);
      if (!ok) return false;
    }
    try {
      // As a simple, broadly-compatible fallback, send a UTF-8 text receipt
      // over the writable characteristic. For production ESC/POS printing you
      // should generate proper ESC/POS bytes and ensure the printer's GATT
      // characteristic accepts raw bytes.
      final text = StringBuffer();
      text.writeln('*** Test Receipt ***');
      text.writeln('Timestamp: ${DateTime.now()}');
      text.writeln('Thank you for testing');
      text.writeln();
      final bytes = utf8.encode(text.toString());

      const chunkSize = 180;
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = (offset + chunkSize) > bytes.length ? bytes.length : offset + chunkSize;
        final chunk = bytes.sublist(offset, end);
        await _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
          serviceId: serviceId,
          characteristicId: charId,
          deviceId: device.id,
        ), value: chunk);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return true;
    } catch (e) {
      print('blePrintTest error: $e');
      return false;
    }
  }

  /// Save the last used selection to local storage so user doesn't need to reselect.
  Future<void> saveLastSelection({required String transport, required PrinterDevice device, String? serviceUuid, String? charUuid}) async {
    try {
      final sel = PrinterSelection(transport: transport, deviceId: device.id, deviceName: device.name, serviceUuid: serviceUuid, charUuid: charUuid);
      await PrinterStorage.saveSelection(sel);
    } catch (e) {
      print('saveLastSelection error: $e');
    }
  }
}
