import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/services/printer_preferences_storage.dart';
import 'package:smart_retail/app/services/invoice_pdf_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/web_file_utils.dart';

class BluetoothPrinterService extends GetxService {
  final devices = <BluetoothDevice>[].obs;
  final isScanning = false.obs;
  final selectedDevice = Rxn<BluetoothDevice>();
  final selectedTransport = 'classic'.obs;
  final debugLogs = <String>[].obs;

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  BluetoothConnection? _activeConnection;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  StreamSubscription<DiscoveredDevice>? _bleScanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _bleConnectionSubscription;
  String? _bleConnectedDeviceId;
  String? _bleServiceUuid;
  String? _bleCharacteristicUuid;

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

  Future<BluetoothConnection> _ensureConnection(BluetoothDevice device) async {
    final active = _activeConnection;
    if (active?.isConnected == true) {
      return active!;
    }

    _activeConnection = await BluetoothConnection.toAddress(device.address);
    return _activeConnection!;
  }

  Future<void> _ensureBlePermissions() async {
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
        throw StateError('Bluetooth permissions denied');
      }
    }
  }

  Future<void> scanBleForDevices({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) {
      devices.clear();
      logDebug('BLE scanning is not available on web.');
      return;
    }

    try {
      await _ensureBlePermissions();
    } catch (e) {
      logDebug('Bluetooth permission denied while scanning BLE printers.');
      DialogUtils.showError(
        'Bluetooth permission denied. Please enable permissions in settings.',
      );
      return;
    }

    try {
      isScanning.value = true;
      devices.clear();
      logDebug('Started BLE printer scan. Loading discovery results.');

      await _bleScanSubscription?.cancel();
      _bleScanSubscription = null;

      final stream = _ble.scanForDevices(
        withServices: const [],
        scanMode: ScanMode.lowLatency,
      );

      _bleScanSubscription = stream.listen((device) {
        final printerDevice = BluetoothDevice(
          address: device.id,
          name: device.name.isEmpty ? 'Unknown' : device.name,
        );
        if (!devices.any((item) => item.address == printerDevice.address)) {
          devices.add(printerDevice);
          logDebug(
            'Discovered BLE printer: ${printerDevice.name ?? 'Unknown'} (${printerDevice.address}).',
          );
        }
      });

      await Future.delayed(timeout);
      await _bleScanSubscription?.cancel();
      _bleScanSubscription = null;
      logDebug('BLE printer scan finished. Total devices: ${devices.length}.');
    } catch (e) {
      logDebug('BLE scan error: $e');
      DialogUtils.showError('Failed to scan BLE printers: $e');
    } finally {
      await _bleScanSubscription?.cancel();
      _bleScanSubscription = null;
      isScanning.value = false;
    }
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
      logDebug(
        'Started printer scan. Loading bonded devices and discovery results.',
      );

      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      devices.assignAll(bonded);
      logDebug('Found ${bonded.length} bonded device(s).');

      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
      final stream = FlutterBluetoothSerial.instance.startDiscovery();
      _discoverySubscription = stream.listen((result) {
        final device = result.device;
        if (!devices.any((item) => item.address == device.address)) {
          devices.add(device);
          logDebug(
            'Discovered printer: ${device.name ?? 'Unknown'} (${device.address}).',
          );
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
      logDebug('Printer scan finished. Total devices: ${devices.length}.');
    } catch (e) {
      logDebug('Scan error: $e');
      DialogUtils.showError('Failed to scan for printers: $e');
    } finally {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      await _discoverySubscription?.cancel();
      _discoverySubscription = null;
      isScanning.value = false;
    }
  }

  Future<void> connectToDevice(
    BluetoothDevice? device, {
    String transport = 'classic',
    String? bleServiceUuid,
    String? bleCharacteristicUuid,
  }) async {
    if (kIsWeb) {
      logDebug('Bluetooth connect requested on web, which is not supported.');
      DialogUtils.showInfo('Bluetooth not supported on web');
      return;
    }
    if (device == null) return;

    final normalizedTransport = transport.toLowerCase().trim();
    if (normalizedTransport == 'ble') {
      if (bleServiceUuid == null ||
          bleServiceUuid.trim().isEmpty ||
          bleCharacteristicUuid == null ||
          bleCharacteristicUuid.trim().isEmpty) {
        logDebug('BLE printer UUIDs are missing.');
        DialogUtils.showError(
          'BLE printer service and characteristic UUIDs are required',
        );
        return;
      }
      await connectBle(
        device,
        serviceUuid: bleServiceUuid.trim(),
        characteristicUuid: bleCharacteristicUuid.trim(),
      );
      return;
    }

    await _closeBleConnection();
    selectedTransport.value = 'classic';

    if (selectedDevice.value?.address == device.address &&
        _activeConnection?.isConnected == true) {
      logDebug('Printer already connected: ${device.name ?? device.address}.');
      return;
    }

    if (selectedDevice.value?.address != device.address) {
      await disconnect();
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.bluetoothConnect.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          logDebug(
            'Bluetooth connect permission denied for ${device.name ?? device.address}.',
          );
          DialogUtils.showError('Bluetooth connect permission required');
          return;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.bluetooth.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          logDebug(
            'Bluetooth permission denied for ${device.name ?? device.address}.',
          );
          DialogUtils.showError('Bluetooth permission required');
          return;
        }
      }
    } catch (e) {
      logDebug('Connect permission check failed: $e');
    }

    try {
      final connection = await _ensureConnection(device);
      selectedDevice.value = device;
      logDebug(
        'Connected printer: ${device.name ?? 'Unknown'} (${device.address}).',
      );
      await connection.output.allSent;
    } catch (e) {
      await _closeActiveConnection();
      selectedDevice.value = null;
      logDebug('Connect error: $e');
      DialogUtils.showError('Failed to select printer: $e');
    }
  }

  Future<void> connectBle(
    BluetoothDevice device, {
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (device.address == null || device.address!.isEmpty) {
      logDebug('BLE printer device id is missing.');
      DialogUtils.showError('BLE printer id is missing');
      return;
    }

    if (kIsWeb) {
      logDebug('Bluetooth connect requested on web, which is not supported.');
      DialogUtils.showInfo('Bluetooth not supported on web');
      return;
    }

    try {
      await _ensureBlePermissions();
    } catch (e) {
      logDebug('BLE connect permission check failed: $e');
      DialogUtils.showError('Bluetooth permission required');
      return;
    }

    try {
      await _closeActiveConnection();
      await _closeBleConnection();

      final serviceId = Uuid.parse(serviceUuid);
      final characteristicId = Uuid.parse(characteristicUuid);
      final deviceId = device.address!;
      final completer = Completer<void>();

      _bleServiceUuid = serviceUuid;
      _bleCharacteristicUuid = characteristicUuid;
      selectedDevice.value = device;
      selectedTransport.value = 'ble';

      _bleConnectionSubscription = _ble
          .connectToDevice(
            id: deviceId,
            servicesWithCharacteristicsToDiscover: {
              serviceId: [characteristicId],
            },
            connectionTimeout: const Duration(seconds: 10),
          )
          .listen(
            (update) async {
              if (update.connectionState == DeviceConnectionState.connected) {
                _bleConnectedDeviceId = deviceId;
                logDebug(
                  'Connected BLE printer: ${device.name ?? 'Unknown'} (${device.address}).',
                );
                if (!completer.isCompleted) {
                  completer.complete();
                }
                try {
                  await _ble.requestMtu(deviceId: deviceId, mtu: 247);
                } catch (_) {}
              } else if (update.connectionState ==
                  DeviceConnectionState.disconnected) {
                if (_bleConnectedDeviceId == deviceId) {
                  _bleConnectedDeviceId = null;
                }
              }
            },
            onError: (error) {
              _bleConnectedDeviceId = null;
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
            },
          );

      await completer.future.timeout(const Duration(seconds: 12));
    } catch (e) {
      await _closeBleConnection();
      selectedDevice.value = null;
      selectedTransport.value = 'classic';
      logDebug('BLE connect error: $e');
      DialogUtils.showError('Failed to connect BLE printer: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      logDebug(
        'Disconnecting printer: ${selectedDevice.value?.name ?? 'Unknown'}',
      );
      await _closeActiveConnection();
      await _closeBleConnection();
      selectedDevice.value = null;
      selectedTransport.value = 'classic';
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

  Future<Uint8List> _encodePdfRasterToEscPos(
    PdfRaster raster,
    int targetWidthPx,
  ) async {
    final uiImage = await raster.toImage();
    final targetHeightPx = (uiImage.height * targetWidthPx / uiImage.width)
        .round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, targetWidthPx.toDouble(), targetHeightPx.toDouble()),
      Paint()..color = Colors.white,
    );
    final paint = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      uiImage,
      Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidthPx.toDouble(), targetHeightPx.toDouble()),
      paint,
    );

    final image = recorder.endRecording().toImageSync(
      targetWidthPx,
      targetHeightPx,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to rasterize PDF page for bluetooth printing');
    }
    return _encodeEscPosRaster(byteData, targetWidthPx, targetHeightPx);
  }

  Future<bool> _printPdfBytesViaBluetooth(
    Uint8List pdfBytes, {
    String? documentName,
  }) async {
    if (kIsWeb) {
      logDebug('Bluetooth PDF printing is not available on web.');
      return false;
    }

    final device = selectedDevice.value;
    if (device == null) {
      logDebug('No bluetooth printer selected.');
      DialogUtils.showInfo('Please select a bluetooth printer first.');
      return false;
    }

    try {
      final preferences = await PrinterPreferencesStorage.load();
      final targetWidthPx = _paperWidthToPixels(preferences.paperWidthMm);
      logDebug(
        'Using ${selectedTransport.value.toUpperCase()} printer ${device.address} for PDF print.',
      );

      await for (final page in Printing.raster(pdfBytes, dpi: 203)) {
        final pageBytes = await _encodePdfRasterToEscPos(page, targetWidthPx);
        await _writePrintBytes(pageBytes);
        await _writePrintBytes(Uint8List.fromList(const [0x0A, 0x0A, 0x0A]));
      }

      logDebug(
        'PDF print complete${documentName == null ? '' : ' for $documentName'}.',
      );
      return true;
    } catch (e) {
      logDebug('PDF bluetooth print failed: $e');
      DialogUtils.showError('Failed to print PDF on bluetooth printer: $e');
      return false;
    }
  }

  Future<bool> printInvoice(Invoice invoice) async {
    final pdfBytes = await InvoicePdfService.buildInvoicePdfBytes(invoice);
    return _printPdfBytesViaBluetooth(
      pdfBytes,
      documentName: invoice.invoiceNumber,
    );
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
      logDebug(
        'Using ${selectedTransport.value.toUpperCase()} printer ${device.address} for raster print.',
      );
      await _writePrintBytes(bytes);
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

  Future<void> _closeActiveConnection() async {
    final connection = _activeConnection;
    _activeConnection = null;
    if (connection == null) return;

    try {
      await connection.close();
    } catch (e) {
      logDebug('Failed to close printer connection cleanly: $e');
    }
  }

  Future<void> _closeBleConnection() async {
    final subscription = _bleConnectionSubscription;
    _bleConnectionSubscription = null;
    _bleConnectedDeviceId = null;
    _bleServiceUuid = null;
    _bleCharacteristicUuid = null;

    try {
      await subscription?.cancel();
    } catch (e) {
      logDebug('Failed to close BLE printer connection cleanly: $e');
    }
  }

  Future<void> _writePrintBytes(Uint8List bytes) async {
    if (selectedTransport.value == 'ble') {
      await _writeBlePrintBytes(bytes);
      return;
    }

    final connection = _activeConnection;
    if (connection == null || !connection.isConnected) {
      throw StateError('No classic bluetooth printer connected');
    }

    connection.output.add(bytes);
    await connection.output.allSent;
  }

  Future<void> _writeBlePrintBytes(Uint8List bytes) async {
    final device = selectedDevice.value;
    final serviceUuid = _bleServiceUuid;
    final characteristicUuid = _bleCharacteristicUuid;

    if (device == null ||
        device.address == null ||
        _bleConnectedDeviceId == null ||
        serviceUuid == null ||
        characteristicUuid == null) {
      throw StateError('No BLE printer connected');
    }

    final serviceId = Uuid.parse(serviceUuid);
    final charId = Uuid.parse(characteristicUuid);
    final characteristic = QualifiedCharacteristic(
      deviceId: device.address!,
      serviceId: serviceId,
      characteristicId: charId,
    );

    const chunkSize = 180;
    var useWithResponse = true;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize) > bytes.length
          ? bytes.length
          : offset + chunkSize;
      final chunk = bytes.sublist(offset, end);
      try {
        if (useWithResponse) {
          await _ble.writeCharacteristicWithResponse(
            characteristic,
            value: chunk,
          );
        } else {
          await _ble.writeCharacteristicWithoutResponse(
            characteristic,
            value: chunk,
          );
        }
      } catch (e) {
        if (useWithResponse) {
          useWithResponse = false;
          await _ble.writeCharacteristicWithoutResponse(
            characteristic,
            value: chunk,
          );
        } else {
          rethrow;
        }
      }
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }

  @override
  void onClose() {
    _discoverySubscription?.cancel();
    _bleScanSubscription?.cancel();
    _closeBleConnection();
    _activeConnection?.close();
    super.onClose();
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
