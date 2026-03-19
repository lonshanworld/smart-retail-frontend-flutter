import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

// Bluetooth package for classic RFCOMM connections
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// ESC/POS byte generator (null-safe fork)
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

// PDF / Printing fallback
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPrinterService extends GetxService {
  final devices = <BluetoothDevice>[].obs;
  final isScanning = false.obs;
  final selectedDevice = Rxn<BluetoothDevice>();

  /// Start scanning for Bluetooth printers (no-op on web)
  Future<void> scanForDevices() async {
    if (kIsWeb) {
      devices.clear();
      return;
    }

    // Request necessary permissions before scanning
    try {
      if (!kIsWeb) {
        final perms = <Permission>[];
        if (defaultTargetPlatform == TargetPlatform.android) {
          perms.addAll([
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.locationWhenInUse,
          ]);
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
        }
        if (perms.isNotEmpty) {
          final statuses = await perms.request();
          final denied = statuses.values.any(
            (s) => s.isDenied || s.isPermanentlyDenied,
          );
          if (denied) {
            DialogUtils.showError(
              'Bluetooth permission denied. Please enable permissions in settings.',
            );
            return;
          }
        }
      }
    } catch (e) {
      print('[BluetoothPrinter] Permission request failed: $e');
    }

    try {
      isScanning.value = true;
      devices.clear();

      // Add already bonded (paired) devices first
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      devices.assignAll(bonded);

      // Start discovery and collect results for a short period
      final stream = FlutterBluetoothSerial.instance.startDiscovery();
      stream.listen((result) {
        final dev = result.device;
        if (!devices.any((d) => d.address == dev.address)) {
          devices.add(dev);
        }
      });

      await Future.delayed(const Duration(seconds: 4));
    } catch (e) {
      print('[BluetoothPrinter] Scan error: $e');
      DialogUtils.showError('Failed to scan for printers: $e');
    } finally {
      isScanning.value = false;
    }
  }

  /// Selects a printer (no-op on web)
  Future<void> connectToDevice(BluetoothDevice? device) async {
    if (kIsWeb) {
      DialogUtils.showInfo('Bluetooth not supported on web');
      return;
    }
    if (device == null) return;
    try {
      // Ensure connect permission (Android 12+ / iOS) is granted
      try {
        if (!kIsWeb) {
          if (defaultTargetPlatform == TargetPlatform.android) {
            final status = await Permission.bluetoothConnect.request();
            if (status.isDenied || status.isPermanentlyDenied) {
              DialogUtils.showError('Bluetooth connect permission required');
              return;
            }
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            final status = await Permission.bluetooth.request();
            if (status.isDenied || status.isPermanentlyDenied) {
              DialogUtils.showError('Bluetooth permission required');
              return;
            }
          }
        }
      } catch (e) {
        print('[BluetoothPrinter] Connect permission check failed: $e');
      }
      selectedDevice.value = device;
      print(
        '[BluetoothPrinter] Selected printer: ${device.name} (${device.address})',
      );
    } catch (e) {
      print('[BluetoothPrinter] Connect error: $e');
      DialogUtils.showError('Failed to select printer: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      selectedDevice.value = null;
      // No persistent connection tracked here; if a connection exists it's closed per-print.
    } catch (e) {
      print('[BluetoothPrinter] Disconnect error: $e');
      DialogUtils.showError('Failed to disconnect printer: $e');
    }
  }

  /// Generate a simple PDF voucher from plain text
  Future<Uint8List> generateVoucherPdf(String voucherText) async {
    final doc = pw.Document();
    final lines = voucherText.split('\n');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'Sale Voucher',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Divider(),
                pw.SizedBox(height: 6),
                // Body: each input line as its own row
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines
                      .map((l) => pw.Text(l, style: pw.TextStyle(fontSize: 10)))
                      .toList(),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Thank you', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '${DateTime.now().toLocal()}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Trigger a download/share of the voucher PDF on all platforms
  Future<void> downloadVoucherPdf(
    String voucherText, {
    String filename = 'voucher.pdf',
  }) async {
    try {
      final bytes = await generateVoucherPdf(voucherText);
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      print('[BluetoothPrinter] PDF generation error: $e');
      DialogUtils.showError('Could not generate voucher PDF: $e');
    }
  }

  /// Print voucher: try Bluetooth ESC/POS first, fall back to PDF share/download
  Future<void> printVoucher(String voucherText) async {
    if (kIsWeb) {
      await downloadVoucherPdf(
        voucherText,
        filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      return;
    }

    final device = selectedDevice.value;
    if (device == null) {
      DialogUtils.showInfo('No printer connected — downloading PDF instead');
      await downloadVoucherPdf(
        voucherText,
        filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      return;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.text(
        'SALE VOUCHER',
        styles: PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.hr();
      bytes += generator.text(
        voucherText,
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.hr();
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Connect via RFCOMM and send raw bytes
      final conn = await BluetoothConnection.toAddress(device.address);
      print('[BluetoothPrinter] Connected to ${device.address}');
      conn.output.add(Uint8List.fromList(bytes));
      await conn.output.allSent;
      await conn.close();
      print('[BluetoothPrinter] Print complete');
    } catch (e) {
      print('[BluetoothPrinter] ESC/POS print failed: $e');
      DialogUtils.showError('Printing failed, downloading PDF instead');
      await downloadVoucherPdf(
        voucherText,
        filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    }
  }
}
