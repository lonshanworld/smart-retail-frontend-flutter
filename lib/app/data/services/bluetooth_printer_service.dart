import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:smart_retail/app/data/services/printer_preferences_storage.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/web_file_utils.dart';

class BluetoothPrinterService extends GetxService {
  final devices = <BluetoothDevice>[].obs;
  final isScanning = false.obs;
  final selectedDevice = Rxn<BluetoothDevice>();
  final debugLogs = <String>[].obs;

  static const int _maxDebugLogEntries = 80;

  void logDebug(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T').last;
    final entry = '[$timestamp] $message';
    debugLogs.add(entry);
    if (debugLogs.length > _maxDebugLogEntries) {
      debugLogs.removeRange(0, debugLogs.length - _maxDebugLogEntries);
    }
    getLogger('app').info('[BluetoothPrinter] $message');
  }

  void clearDebugLogs() {
    debugLogs.clear();
  }

  Future<void> scanForDevices() async {
    if (kIsWeb) {
      devices.clear();
      logDebug('Bluetooth scanning is not available on web.');
      return;
    }

    try {
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
          (status) => status.isDenied || status.isPermanentlyDenied,
        );
        if (denied) {
          logDebug('Bluetooth permission denied while scanning for printers.');
          DialogUtils.showError(
            'Bluetooth permission denied. Please enable permissions in settings.',
          );
          return;
        }
      }
    } catch (e) {
      logDebug('Permission request failed while scanning: $e');
    }

    try {
      isScanning.value = true;
      devices.clear();
      logDebug('Started printer scan. Loading bonded devices and discovery results.');

      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      devices.assignAll(bonded);
      logDebug('Found ${bonded.length} bonded device(s).');

      final stream = FlutterBluetoothSerial.instance.startDiscovery();
      stream.listen((result) {
        final device = result.device;
        if (!devices.any((item) => item.address == device.address)) {
          devices.add(device);
          logDebug('Discovered printer: ${device.name ?? 'Unknown'} (${device.address}).');
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      logDebug('Printer scan finished. Total devices: ${devices.length}.');
    } catch (e) {
      logDebug('Scan error: $e');
      DialogUtils.showError('Failed to scan for printers: $e');
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectToDevice(BluetoothDevice? device) async {
    if (kIsWeb) {
      logDebug('Bluetooth connect requested on web, which is not supported.');
      DialogUtils.showInfo('Bluetooth not supported on web');
      return;
    }
    if (device == null) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.bluetoothConnect.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          logDebug('Bluetooth connect permission denied for ${device.name ?? device.address}.');
          DialogUtils.showError('Bluetooth connect permission required');
          return;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.bluetooth.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          logDebug('Bluetooth permission denied for ${device.name ?? device.address}.');
          DialogUtils.showError('Bluetooth permission required');
          return;
        }
      }
    } catch (e) {
      logDebug('Connect permission check failed: $e');
    }

    try {
      selectedDevice.value = device;
      logDebug('Selected printer: ${device.name ?? 'Unknown'} (${device.address}).');
    } catch (e) {
      logDebug('Connect error: $e');
      DialogUtils.showError('Failed to select printer: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      logDebug('Disconnecting printer: ${selectedDevice.value?.name ?? 'Unknown'}');
      selectedDevice.value = null;
      logDebug('Printer disconnected.');
    } catch (e) {
      logDebug('Disconnect error: $e');
      DialogUtils.showError('Failed to disconnect printer: $e');
    }
  }

  int _paperWidthToPixels(int paperWidthMm) {
    if (paperWidthMm <= 58) {
      return 384;
    }
    return 576;
  }

  double _receiptFontSize(double fontScale) {
    return (13.5 * fontScale).clamp(11.0, 22.0);
  }

  Future<Uint8List> _renderReceiptRasterBytes(
    String receiptText,
    PrinterPreferences preferences,
  ) async {
    final widthPx = _paperWidthToPixels(preferences.paperWidthMm);
    final paddingPx = (widthPx * 0.06).round().clamp(20, 36);
    final contentWidth = (widthPx - (paddingPx * 2)).toDouble();
    final baseFontSize = _receiptFontSize(preferences.fontScale);

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: null,
      text: TextSpan(
        text: receiptText.replaceAll('\r\n', '\n'),
        style: TextStyle(
          color: Colors.black,
          fontSize: baseFontSize,
          height: 1.25,
          fontFamily: 'monospace',
        ),
      ),
    );
    painter.layout(maxWidth: contentWidth);

    final heightPx = (painter.height + (paddingPx * 2)).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      Paint()..color = Colors.white,
    );
    painter.paint(canvas, Offset(paddingPx.toDouble(), paddingPx.toDouble()));

    final picture = recorder.endRecording();
    final image = await picture.toImage(widthPx, heightPx);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to rasterize receipt image');
    }
    return _encodeEscPosRaster(byteData, widthPx, heightPx);
  }

  Uint8List _encodeEscPosRaster(ByteData byteData, int widthPx, int heightPx) {
    final bytesPerRow = (widthPx + 7) ~/ 8;
    final rasterBytes = Uint8List(bytesPerRow * heightPx);
    final pixels = byteData.buffer.asUint8List();

    for (var y = 0; y < heightPx; y++) {
      for (var x = 0; x < widthPx; x++) {
        final pixelIndex = ((y * widthPx) + x) * 4;
        final red = pixels[pixelIndex];
        final green = pixels[pixelIndex + 1];
        final blue = pixels[pixelIndex + 2];
        final alpha = pixels[pixelIndex + 3];
        if (alpha < 16) continue;

        final brightness = ((red * 299) + (green * 587) + (blue * 114)) ~/ 1000;
        if (brightness < 180) {
          final rowOffset = y * bytesPerRow;
          final byteIndex = rowOffset + (x ~/ 8);
          rasterBytes[byteIndex] |= (0x80 >> (x % 8));
        }
      }
    }

    final header = <int>[
      0x1D,
      0x76,
      0x30,
      0x00,
      bytesPerRow & 0xFF,
      (bytesPerRow >> 8) & 0xFF,
      heightPx & 0xFF,
      (heightPx >> 8) & 0xFF,
    ];
    return Uint8List.fromList([...header, ...rasterBytes]);
  }

  Future<bool> _sendRasterReceipt(
    String receiptText, {
    required bool allowFallbackPdf,
  }) async {
    final device = selectedDevice.value;
    if (device == null) {
      if (allowFallbackPdf) {
        DialogUtils.showInfo('No printer connected — downloading PDF instead');
        await downloadVoucherPdf(
          receiptText,
          filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
      return false;
    }

    try {
      final preferences = await PrinterPreferencesStorage.load();
      final bytes = await _renderReceiptRasterBytes(receiptText, preferences);
      final connection = await BluetoothConnection.toAddress(device.address);
      logDebug('Connected to ${device.address} for raster print.');
      connection.output.add(bytes);
      await connection.output.allSent;
      await connection.close();
      logDebug('Raster print complete.');
      return true;
    } catch (e) {
      logDebug('Raster print failed: $e');
      if (allowFallbackPdf) {
        DialogUtils.showError('Printing failed, downloading PDF instead');
        await downloadVoucherPdf(
          receiptText,
          filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }
      return false;
    }
  }

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
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines
                      .map(
                        (line) =>
                            pw.Text(line, style: pw.TextStyle(fontSize: 10)),
                      )
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

  Future<void> downloadVoucherPdf(
    String voucherText, {
    String filename = 'voucher.pdf',
  }) async {
    try {
      final bytes = await generateVoucherPdf(voucherText);
      if (kIsWeb) {
        await downloadFile(bytes, filename);
        logDebug('Web download triggered: $filename');
        return;
      }

      final directory = await _getLocalPdfDirectory();
      final file = File(p.join(directory.path, filename));
      await file.writeAsBytes(bytes);
      logDebug('Voucher PDF saved to ${file.path}');
    } catch (e) {
      logDebug('PDF generation error: $e');
      DialogUtils.showError('Could not generate voucher PDF: $e');
    }
  }

  Future<Directory> _getLocalPdfDirectory() async {
    try {
      if (Platform.isAndroid) {
        try {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.documents,
          );
          if (dirs != null && dirs.isNotEmpty) {
            final base = dirs.first;
            String publicRoot = base.path;
            final androidIdx = base.path.indexOf('${p.separator}Android');
            if (androidIdx != -1) {
              publicRoot = base.path.substring(0, androidIdx);
            }
            final target = Directory(
              p.join(publicRoot, 'Documents', 'SmartRetail', 'Invoices'),
            );
            if (!await target.exists()) await target.create(recursive: true);
            logDebug('Using Android public path: ${target.path}');
            return target;
          }
        } catch (e) {
          logDebug('Android public path fallback failed: $e');
        }
      } else if (Platform.isIOS) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final target = Directory(
            p.join(docs.path, 'SmartRetail', 'Invoices'),
          );
          if (!await target.exists()) await target.create(recursive: true);
          return target;
        } catch (_) {}
      }

      try {
        final downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory != null) {
          final target = Directory(
            p.join(downloadsDirectory.path, 'SmartRetail', 'Invoices'),
          );
          if (!await target.exists()) await target.create(recursive: true);
          return target;
        }
      } catch (_) {}

      try {
        final appDocs = await getApplicationDocumentsDirectory();
        final target = Directory(
          p.join(appDocs.path, 'SmartRetail', 'Invoices'),
        );
        if (!await target.exists()) await target.create(recursive: true);
        return target;
      } catch (_) {}
    } catch (_) {}

    return Directory.systemTemp;
  }

  Future<void> printVoucher(String voucherText) async {
    if (kIsWeb) {
      await downloadVoucherPdf(
        voucherText,
        filename: 'voucher-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      return;
    }

    final ok = await _sendRasterReceipt(voucherText, allowFallbackPdf: true);
    if (!ok) {
      logDebug('Falling back after raster print failure.');
    }
  }
}
