library bluetooth_print;

import 'dart:async';
import 'bluetooth_print_model.dart';

class BluetoothPrint {
  BluetoothPrint._internal();
  static final BluetoothPrint instance = BluetoothPrint._internal();

  final StreamController<List<BluetoothDevice>> _scanController = StreamController.broadcast();
  Stream<List<BluetoothDevice>> get scanResults => _scanController.stream;

  final StreamController<int> _stateController = StreamController.broadcast();
  Stream<int> get state => _stateController.stream;

  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    // No-op stub: emit empty list after timeout
    await Future.delayed(timeout);
    _scanController.add([]);
  }

  Future<void> stopScan() async {
    // no-op
  }

  Future<void> connect(BluetoothDevice device) async {
    // no-op: pretend connected
    _stateController.add(1);
  }

  Future<void> disconnect() async {
    _stateController.add(0);
  }

  Future<void> printReceipt(Map<String, dynamic> options, List<LineText> data) async {
    // no-op: in a real plugin this would send receipt data to device
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
