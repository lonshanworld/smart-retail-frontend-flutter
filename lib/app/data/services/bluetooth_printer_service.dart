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
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/printer_preferences_storage.dart';
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

  Future<int> _androidSdkInt() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _requestPermissionsWithRetry(
    List<Permission> perms, {
    int maxAttempts = 2,
  }) async {
    if (perms.isEmpty) return;

    Map<Permission, PermissionStatus> statuses =
        <Permission, PermissionStatus>{};
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      statuses = await perms.request();

      final hasDenied = statuses.values.any(
        (status) =>
            status.isDenied ||
            status.isPermanentlyDenied ||
            status.isRestricted,
      );
      if (!hasDenied) {
        return;
      }

      final canRetry = statuses.values.any((status) => status.isDenied);
      if (attempt < maxAttempts && canRetry) {
        logDebug(
          'Bluetooth permission denied. Retrying request ($attempt/$maxAttempts).',
        );
        continue;
      }

      break;
    }

    throw StateError('Bluetooth permissions denied');
  }

  Future<void> _ensureBlePermissions() async {
    final perms = <Permission>[];
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = await _androidSdkInt();
      if (sdk >= 31) {
        perms.addAll([Permission.bluetoothScan, Permission.bluetoothConnect]);
      } else {
        perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
    }

    await _requestPermissionsWithRetry(perms);
  }

  Future<void> _ensureClassicScanPermissions() async {
    final perms = <Permission>[];
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = await _androidSdkInt();
      if (sdk >= 31) {
        perms.addAll([Permission.bluetoothScan, Permission.bluetoothConnect]);
      } else {
        perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
    }

    await _requestPermissionsWithRetry(perms);
  }

  Future<void> _ensureClassicPermissions() async {
    final perms = <Permission>[];
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = await _androidSdkInt();
      if (sdk >= 31) {
        perms.add(Permission.bluetoothConnect);
      } else {
        perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      perms.addAll([Permission.bluetooth, Permission.locationWhenInUse]);
    }

    await _requestPermissionsWithRetry(perms);
  }

  Future<void> _logClassicConnectPermissionSnapshot() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final sdk = await _androidSdkInt();
    try {
      final bt = await Permission.bluetooth.status;
      final btConnect = await Permission.bluetoothConnect.status;
      final btScan = await Permission.bluetoothScan.status;
      logDebug(
        'Classic connect permission snapshot: sdk=$sdk, bluetooth=$bt, bluetoothConnect=$btConnect, bluetoothScan=$btScan',
      );
    } catch (e) {
      logDebug('Failed to read classic connect permission snapshot: $e');
    }
  }

  Future<void> _retryLegacyBluetoothPermissionIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final sdk = await _androidSdkInt();
    if (sdk < 31) return;

    try {
      final bt = await Permission.bluetooth.status;
      if (bt.isDenied) {
        logDebug(
          'Legacy BLUETOOTH permission is denied on Android 12+. Retrying request once for diagnostics.',
        );
        final retried = await Permission.bluetooth.request();
        logDebug('Legacy BLUETOOTH retry result: $retried');
      }

      final btAfter = await Permission.bluetooth.status;
      final btConnect = await Permission.bluetoothConnect.status;
      final btScan = await Permission.bluetoothScan.status;
      if (btAfter.isDenied && btConnect.isGranted && btScan.isGranted) {
        logDebug(
          'Compatibility warning: BLUETOOTH remains denied while BLUETOOTH_CONNECT/SCAN are granted. This indicates a classic plugin compatibility issue on Android 12+ and may require plugin upgrade or a full reinstall.',
        );
      }
    } catch (e) {
      logDebug('Legacy BLUETOOTH retry check failed: $e');
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
      await _ensureClassicScanPermissions();
    } catch (e) {
      logDebug('Permission request failed while scanning: $e');
      DialogUtils.showError(
        'Bluetooth permission denied. Please enable permissions in settings.',
      );
      return;
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
      await _ensureClassicPermissions();
    } catch (e) {
      logDebug(
        'Bluetooth permission denied for ${device.name ?? device.address}: $e',
      );
      DialogUtils.showError(
        'Bluetooth permission required. Please allow Bluetooth permissions in app settings.',
      );
      return;
    }

    try {
      await _retryLegacyBluetoothPermissionIfNeeded();
      await _logClassicConnectPermissionSnapshot();
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
    if (paperWidthMm <= 40) {
      return 256;
    }
    if (paperWidthMm <= 58) {
      return 384;
    }
    return 576;
  }

  double _receiptFontSize(double fontScale) {
    return (13.5 * fontScale).clamp(11.0, 36.0);
  }

  int _receiptCharsPerLine(int paperWidthMm) {
    if (paperWidthMm <= 40) return 24;
    if (paperWidthMm <= 58) return 32;
    return 42;
  }

  String _lineFill(int count, String char) {
    if (count <= 0) return '';
    return List.filled(count, char).join();
  }

  String _centerText(String text, int width) {
    final clean = text.trim();
    if (clean.isEmpty) return '';
    if (clean.length >= width) return clean;
    final left = (width - clean.length) ~/ 2;
    return '${' ' * left}$clean';
  }

  String _amountLine(String label, String value, int width) {
    final left = label.trim();
    final right = value.trim();
    if ((left.length + right.length + 1) >= width) {
      return '$left $right';
    }
    return '$left${' ' * (width - left.length - right.length)}$right';
  }

  List<String> _wrapText(String text, int width) {
    final clean = text.trim();
    if (clean.isEmpty) return const [''];
    final words = clean.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      if (current.isEmpty) {
        current = word;
        continue;
      }
      final candidate = '$current $word';
      if (candidate.length <= width) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  String _formatMoney(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  String _buildSaleVoucherText(Sale sale, PrinterPreferences preferences) {
    return _buildVoucherTemplateText(
      preferences: preferences,
      invoiceNumber: sale.id,
      dateTime: sale.saleDate,
      payment: sale.paymentType.toUpperCase(),
      status: sale.paymentStatus.toUpperCase(),
      items: sale.items
          .map(
            (item) => _VoucherTemplateItem(
              name: (item.itemName?.trim().isNotEmpty == true)
                  ? item.itemName!.trim()
                  : 'Unnamed item',
              quantity: item.quantitySold,
              unitPrice: item.sellingPriceAtSale,
              amount: item.subtotal,
            ),
          )
          .toList(),
      subtotal: sale.items.fold<double>(
        0.0,
        (sum, item) => sum + item.subtotal,
      ),
      discountAmount: sale.discountAmount ?? 0,
      taxAmount: 0,
      deliveryCharge: sale.deliveryCharge,
      totalAmount: sale.totalAmount,
      notes: sale.notes,
    );
  }

  String _buildInvoiceVoucherText(
    Invoice invoice,
    PrinterPreferences preferences,
  ) {
    return _buildVoucherTemplateText(
      preferences: preferences,
      invoiceNumber: invoice.invoiceNumber,
      dateTime: invoice.checkoutTime,
      payment: 'INVOICE',
      status: invoice.paymentStatus.toUpperCase(),
      items: invoice.items
          .map(
            (item) => _VoucherTemplateItem(
              name: (item.itemName?.trim().isNotEmpty == true)
                  ? item.itemName!.trim()
                  : item.inventoryItemId,
              quantity: item.quantitySold,
              unitPrice: item.sellingPriceAtSale,
              amount: item.subtotal,
            ),
          )
          .toList(),
      subtotal: invoice.subtotal,
      discountAmount: invoice.discountAmount,
      taxAmount: invoice.taxAmount,
      deliveryCharge: invoice.deliveryCharge,
      totalAmount: invoice.totalAmount,
      notes: invoice.notes,
    );
  }

  String _buildVoucherTemplateText({
    required PrinterPreferences preferences,
    required String invoiceNumber,
    required DateTime dateTime,
    required String payment,
    required String status,
    required List<_VoucherTemplateItem> items,
    required double subtotal,
    required double discountAmount,
    required double taxAmount,
    required double deliveryCharge,
    required double totalAmount,
    String? notes,
  }) {
    final widthScale = (preferences.printContentWidthPercent / 100).clamp(
      0.5,
      1.5,
    );
    final width = (_receiptCharsPerLine(preferences.paperWidthMm) * widthScale)
        .round()
        .clamp(16, 96);
    final divider = _lineFill(width, '-');
    final strongDivider = _lineFill(width, '=');
    final qtyWidth = width <= 32 ? 3 : 4;
    final unitWidth = width <= 32 ? 6 : 7;
    final amountWidth = width <= 32 ? 6 : 7;
    const columnGap = ' ';
    final fixedWidth =
        qtyWidth + unitWidth + amountWidth + (columnGap.length * 3);
    final itemNameWidth = (width - fixedWidth).clamp(8, width).toInt();

    final lines = <String>[];

    if (preferences.voucherHeaderShopName.trim().isNotEmpty) {
      lines.add(_centerText(preferences.voucherHeaderShopName, width));
    }
    if (preferences.voucherHeaderAddress.trim().isNotEmpty) {
      lines.addAll(
        _wrapText(
          preferences.voucherHeaderAddress,
          width,
        ).map((line) => _centerText(line, width)),
      );
    }
    if (preferences.voucherHeaderContact.trim().isNotEmpty) {
      lines.add(_centerText(preferences.voucherHeaderContact, width));
    }

    if (lines.isNotEmpty) {
      lines.add(divider);
    }

    lines.add(_centerText('INVOICE', width));
    lines.add(_amountLine('Invoice #', invoiceNumber, width));
    lines.add(
      _amountLine(
        'Date',
        dateTime.toLocal().toString().substring(0, 16),
        width,
      ),
    );
    lines.add(_amountLine('Payment', payment, width));
    lines.add(_amountLine('Status', status, width));
    lines.add(divider);

    final tableHeader =
        'Item'.padRight(itemNameWidth) +
        columnGap +
        'Qty'.padLeft(qtyWidth) +
        columnGap +
        'Price'.padLeft(unitWidth) +
        columnGap +
        'Amt'.padLeft(amountWidth);
    lines.add(tableHeader);
    lines.add(divider);

    for (final item in items) {
      final itemName = item.name;
      final wrappedName = _wrapText(itemName, itemNameWidth);
      final qty = item.quantity.toString();
      final unit = item.unitPrice.toStringAsFixed(2);
      final amount = item.amount.toStringAsFixed(2);

      lines.add(
        wrappedName.first.padRight(itemNameWidth) +
            columnGap +
            qty.padLeft(qtyWidth) +
            columnGap +
            unit.padLeft(unitWidth) +
            columnGap +
            amount.padLeft(amountWidth),
      );

      if (wrappedName.length > 1) {
        for (final extra in wrappedName.skip(1)) {
          lines.add(extra.padRight(itemNameWidth));
        }
      }
    }

    lines.add(strongDivider);

    lines.add(_amountLine('Subtotal', _formatMoney(subtotal), width));
    if (discountAmount > 0) {
      lines.add(_amountLine('Discount', _formatMoney(-discountAmount), width));
    }
    if (taxAmount > 0) {
      lines.add(_amountLine('Tax', _formatMoney(taxAmount), width));
    }
    if (deliveryCharge > 0) {
      lines.add(_amountLine('Delivery', _formatMoney(deliveryCharge), width));
    }
    lines.add(_amountLine('TOTAL', _formatMoney(totalAmount), width));
    lines.add(strongDivider);

    if (notes != null && notes.trim().isNotEmpty) {
      lines.add('Notes:');
      lines.addAll(_wrapText(notes.trim(), width));
      lines.add(divider);
    }

    lines.add(_centerText('Thank you for your purchase', width));
    lines.add('');
    lines.addAll(
      _wrapText(
        'Need custom software for your business? Visit nanonux.com.',
        width,
      ).map((line) => _centerText(line, width)),
    );
    // Extra trailing feed area helps protect footer text during manual tear.
    lines.add('');
    lines.add('');
    lines.add('');
    lines.add('');
    lines.add('');
    lines.add('');
    lines.add('');

    return lines.join('\n');
  }

  Future<Uint8List> _renderReceiptRasterBytes(
    String receiptText,
    PrinterPreferences preferences, {
    String? emphasizedHeaderLine,
  }) async {
    final widthPx = _paperWidthToPixels(preferences.paperWidthMm);
    final widthRatio = (preferences.printContentWidthPercent / 100).clamp(
      0.70,
      1.5,
    );
    final baseFontSize = _receiptFontSize(preferences.fontScale);
    final contentWidth = widthRatio <= 1.0
        ? (widthPx * widthRatio).toDouble()
        : widthPx.toDouble();
    final horizontalPadding = widthRatio <= 1.0
        ? ((widthPx - contentWidth) / 2).round().clamp(8, widthPx ~/ 4)
        : 8;
    final adjustedFontSize = widthRatio > 1.0
        ? (baseFontSize / widthRatio).clamp(8.5, baseFontSize)
        : baseFontSize;
    final verticalPadding = (baseFontSize * 1.2).round().clamp(12, 32);

    final normalizedText = receiptText.replaceAll('\r\n', '\n');
    final emphasizedTarget = emphasizedHeaderLine?.trim() ?? '';
    const thankYouLine = 'Thank you for your purchase';
    var emphasizedApplied = false;
    final textSpans = <InlineSpan>[];
    final lines = normalizedText.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      final shouldEmphasize =
          !emphasizedApplied &&
          emphasizedTarget.isNotEmpty &&
          trimmedLine == emphasizedTarget;
      if (shouldEmphasize) {
        emphasizedApplied = true;
      }

      var lineFontSize = shouldEmphasize
          ? (adjustedFontSize * 1.35).clamp(10.0, 64.0).toDouble()
          : adjustedFontSize;
      if (trimmedLine == thankYouLine) {
        lineFontSize = (lineFontSize * 1.1).clamp(8.5, 64.0).toDouble();
      }

      // Compensate left padding for emphasized centered line so it stays visually centered.
      var textToDraw = line;
      if (shouldEmphasize) {
        final leadingSpaces = line.length - line.trimLeft().length;
        final compensatedLeadingSpaces = (leadingSpaces / 1.35).round().clamp(
          0,
          leadingSpaces,
        );
        textToDraw =
            '${' ' * compensatedLeadingSpaces}${trimmedLine.isEmpty ? '' : line.trimLeft()}';
      }

      textSpans.add(
        TextSpan(
          text: textToDraw,
          style: TextStyle(
            color: Colors.black,
            fontSize: lineFontSize,
            height: 1.25,
            fontFamily: 'monospace',
          ),
        ),
      );
      if (i < lines.length - 1) {
        textSpans.add(const TextSpan(text: '\n'));
      }
    }

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      maxLines: null,
      text: TextSpan(children: textSpans),
    );
    painter.layout(maxWidth: contentWidth);

    final heightPx = (painter.height + (verticalPadding * 2)).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      Paint()..color = Colors.white,
    );
    painter.paint(
      canvas,
      Offset(horizontalPadding.toDouble(), verticalPadding.toDouble()),
    );

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

  Future<bool> printInvoice(Invoice invoice) async {
    final preferences = await PrinterPreferencesStorage.load();
    final voucherText = _buildInvoiceVoucherText(invoice, preferences);
    final ok = await _sendRasterReceipt(
      voucherText,
      allowFallbackPdf: true,
      emphasizedHeaderLine: preferences.voucherHeaderShopName,
    );
    if (!ok) {
      logDebug('Falling back after invoice raster print failure.');
    }
    return ok;
  }

  Future<bool> _sendRasterReceipt(
    String receiptText, {
    required bool allowFallbackPdf,
    String? emphasizedHeaderLine,
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
      final bytes = await _renderReceiptRasterBytes(
        receiptText,
        preferences,
        emphasizedHeaderLine: emphasizedHeaderLine,
      );
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
                  'INVOICE',
                  style: pw.TextStyle(fontSize: 16),
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
                pw.Text(
                  'Thank you for your purchase',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${DateTime.now().toLocal()}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> generateSaleVoucherPdf(
    Sale sale,
    PrinterPreferences preferences,
  ) async {
    final doc = pw.Document();
    final subtotal = sale.items.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(14),
        build: (_) {
          final rows = sale.items
              .map(
                (item) => [
                  (item.itemName?.trim().isNotEmpty == true)
                      ? item.itemName!.trim()
                      : 'Unnamed item',
                  item.quantitySold.toString(),
                  _formatMoney(item.sellingPriceAtSale),
                  _formatMoney(item.subtotal),
                ],
              )
              .toList();

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (preferences.voucherHeaderShopName.trim().isNotEmpty)
                pw.Text(
                  preferences.voucherHeaderShopName.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 14),
                ),
              if (preferences.voucherHeaderAddress.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    preferences.voucherHeaderAddress.trim(),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (preferences.voucherHeaderContact.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    preferences.voucherHeaderContact.trim(),
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 6),
              pw.Text(
                'INVOICE',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 15),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Invoice #: ${sale.id}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Date: ${sale.saleDate.toLocal().toString().substring(0, 16)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Payment: ${sale.paymentType.toUpperCase()}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Status: ${sale.paymentStatus.toUpperCase()}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headerStyle: const pw.TextStyle(fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(0.7),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.1),
                },
                headers: const ['Item', 'Qty', 'Price', 'Amount'],
                data: rows,
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 150,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _buildPdfAmountRow('Subtotal', _formatMoney(subtotal)),
                      if ((sale.discountAmount ?? 0) > 0)
                        _buildPdfAmountRow(
                          'Discount',
                          _formatMoney(-(sale.discountAmount ?? 0)),
                        ),
                      if (sale.deliveryCharge > 0)
                        _buildPdfAmountRow(
                          'Delivery',
                          _formatMoney(sale.deliveryCharge),
                        ),
                      pw.Divider(),
                      _buildPdfAmountRow(
                        'TOTAL',
                        _formatMoney(sale.totalAmount),
                      ),
                    ],
                  ),
                ),
              ),
              if (sale.notes != null && sale.notes!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Notes', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  sale.notes!.trim(),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
              ],
              pw.Spacer(),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.Text(
                'Thank you for your purchase',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPdfAmountRow(
    String label,
    String amount, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: bold ? 10 : 9,
      fontWeight: pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(amount, style: style),
      ],
    );
  }

  Future<void> downloadSaleVoucherPdf(Sale sale, {String? filename}) async {
    try {
      final preferences = await PrinterPreferencesStorage.load();
      final bytes = await generateSaleVoucherPdf(sale, preferences);
      final outputName = filename ?? 'voucher-${sale.id}.pdf';
      if (kIsWeb) {
        await downloadFile(bytes, outputName);
        logDebug('Web download triggered: $outputName');
        return;
      }

      final directory = await _getLocalPdfDirectory();
      final file = File(p.join(directory.path, outputName));
      await file.writeAsBytes(bytes);
      logDebug('Voucher PDF saved to ${file.path}');
    } catch (e) {
      logDebug('PDF generation error: $e');
      DialogUtils.showError('Could not generate voucher PDF: $e');
    }
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

  Future<void> printSaleVoucher(Sale sale) async {
    final preferences = await PrinterPreferencesStorage.load();
    final voucherText = _buildSaleVoucherText(sale, preferences);
    final ok = await _sendRasterReceipt(
      voucherText,
      allowFallbackPdf: true,
      emphasizedHeaderLine: preferences.voucherHeaderShopName,
    );
    if (!ok) {
      logDebug('Falling back after raster print failure.');
    }
  }
}

class _VoucherTemplateItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double amount;

  const _VoucherTemplateItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });
}
