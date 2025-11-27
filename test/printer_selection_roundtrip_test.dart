import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/data/services/printer_storage.dart';

void main() {
  test('PrinterSelection map roundtrip', () {
    final s = PrinterSelection(
      transport: 'ble',
      deviceId: 'dev-xyz',
      deviceName: 'My Printer',
      serviceUuid: 'svc',
      charUuid: 'chr',
    );

    final m = s.toMap();
    final r = PrinterSelection.fromMap(m);

    expect(r, isNotNull);
    expect(r!.transport, equals(s.transport));
    expect(r.deviceId, equals(s.deviceId));
    expect(r.deviceName, equals(s.deviceName));
    expect(r.serviceUuid, equals(s.serviceUuid));
    expect(r.charUuid, equals(s.charUuid));
  });
}
