import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:smart_retail/app/data/services/printer_storage.dart';
import 'package:smart_retail/app/data/services/printer_service.dart';
import 'package:flutter/services.dart';

class PrinterTestView extends StatefulWidget {
  const PrinterTestView({super.key});

  @override
  State<PrinterTestView> createState() => _PrinterTestViewState();
}

class _PrinterTestViewState extends State<PrinterTestView> {
  final PrinterService _printer = Get.put(PrinterService());
  List<PrinterDevice> _devices = [];
  bool _scanning = false;
  // transport selection: 'classic' or 'ble'
  String _transport = 'classic';
  // BLE service/characteristic (user-entered for testing)
  final TextEditingController _bleServiceController = TextEditingController();
  final TextEditingController _bleCharController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _printer.init();
    // load saved selection to display
    _loadSavedSelection();
  }

  @override
  void dispose() {
    _bleServiceController.dispose();
    _bleCharController.dispose();
    super.dispose();
  }

  PrinterSelection? _saved;

  Future<void> _loadSavedSelection() async {
    final sel = await _printer.getSavedSelection();
    if (sel != null) {
      setState(() {
        _saved = sel;
        // prefill BLE UUID fields if present
        if (sel.serviceUuid != null) _bleServiceController.text = sel.serviceUuid!;
        if (sel.charUuid != null) _bleCharController.text = sel.charUuid!;
      });
    }
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final list = _transport == 'ble'
        ? await _printer.scanBle(timeout: const Duration(seconds: 4))
        : await _printer.scan(timeout: const Duration(seconds: 4));
    setState(() {
      _devices = list;
      _scanning = false;
    });
  }

  Future<void> _connectAndPrint(PrinterDevice d) async {
    bool ok = false;
    bool printed = false;
    if (_transport == 'ble') {
      ok = await _printer.connectBle(d);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect (BLE)')));
        return;
      }
      // parse UUIDs from text fields
      try {
        final service = Uuid.parse(_bleServiceController.text.trim());
        final char = Uuid.parse(_bleCharController.text.trim());
        printed = await _printer.blePrintTest(device: d, serviceId: service, charId: char);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid BLE UUIDs')));
        return;
      }
      await _printer.disconnectBle();
    } else {
      ok = await _printer.connect(d);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect')));
        return;
      }
      printed = await _printer.printTestReceipt();
      await _printer.disconnect();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(printed ? 'Printed' : 'Print failed')));
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer Test')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(children: [
              const Text('Transport: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _transport,
                items: const [
                  DropdownMenuItem(value: 'classic', child: Text('Classic Bluetooth (SPP)')),
                  DropdownMenuItem(value: 'ble', child: Text('BLE (GATT)')),
                ],
                onChanged: (v) => setState(() => _transport = v ?? 'classic'),
              ),
            ]),
            const SizedBox(height: 8),
            if (_saved != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saved Printer', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Transport: ${_saved!.transport}'),
                      Text('Name: ${_saved!.deviceName}'),
                      Text('ID: ${_saved!.deviceId}'),
                      if (_saved!.serviceUuid != null) Text('Service: ${_saved!.serviceUuid}'),
                      if (_saved!.charUuid != null) Text('Characteristic: ${_saved!.charUuid}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final ok = await _printer.quickConnectSaved();
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Connected' : 'Connect failed')));
                            },
                            child: const Text('Quick Connect'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            onPressed: () async {
                              await _printer.clearSavedSelection();
                              setState(() => _saved = null);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared saved printer')));
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            if (_transport == 'ble') ...[
              TextField(controller: _bleServiceController, decoration: const InputDecoration(labelText: 'Service UUID (required for BLE print)')),
              const SizedBox(height: 8),
              TextField(controller: _bleCharController, decoration: const InputDecoration(labelText: 'Characteristic UUID (required for BLE print)')),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                ElevatedButton(onPressed: _scanning ? null : _scan, child: Text(_scanning ? 'Scanning...' : 'Scan for printers')),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings_bluetooth),
                  label: const Text('Open Bluetooth Settings'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                  onPressed: () async {
                    const channel = MethodChannel('smart_retail/printer');
                    try {
                      await channel.invokeMethod('openBluetoothSettings');
                    } catch (e) {
                      // ignore — platform may not implement; nothing else to do here
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _devices.isEmpty
                  ? const Center(child: Text('No devices found'))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, i) {
                        final d = _devices[i];
                        return ListTile(
                          title: Text(d.name),
                          subtitle: Text(d.id),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                child: const Text('Print test'),
                                onPressed: () => _connectAndPrint(d),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Save selection',
                                icon: const Icon(Icons.save),
                                onPressed: () async {
                                  // Save selection to local storage for later reuse
                                  if (_transport == 'ble') {
                                    await _printer.saveLastSelection(
                                      transport: _transport,
                                      device: d,
                                      serviceUuid: _bleServiceController.text.trim(),
                                      charUuid: _bleCharController.text.trim(),
                                    );
                                  } else {
                                    await _printer.saveLastSelection(
                                      transport: _transport,
                                      device: d,
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved printer selection')));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
