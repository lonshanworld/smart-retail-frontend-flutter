import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/services/printer_storage.dart';

void main() {
  test('PrinterSelection toMap and fromMap (pure Dart)', () {
    final s = PrinterSelection(
      transport: 'ble',
      deviceId: 'device-1',
      deviceName: 'Test Printer',
      serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
      charUuid: '00002af1-0000-1000-8000-00805f9b34fb',
    );

    final map = s.toMap();
    final recovered = PrinterSelection.fromMap(map);

    expect(recovered, isNotNull);
    expect(recovered!.transport, equals(s.transport));
    expect(recovered.deviceId, equals(s.deviceId));
    expect(recovered.deviceName, equals(s.deviceName));
    expect(recovered.serviceUuid, equals(s.serviceUuid));
    expect(recovered.charUuid, equals(s.charUuid));
  });
}
