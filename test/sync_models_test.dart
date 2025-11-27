import 'package:flutter_test/flutter_test.dart';
import 'package:smart_retail/app/models/sync_models.dart';

void main() {
  test('SaleForSync.fromMap with items as list', () {
    final map = {
      'id': 'local-1',
      'shop_id': 'shop-1',
      'items': [
        {'product': 'p1', 'qty': 2}
      ],
      'total_amount': 12.5,
      'discount_amount': 1.0,
      'payment_type': 'cash',
      'created_at': DateTime.now().toIso8601String(),
    };

    final s = SaleForSync.fromMap(map);
    expect(s.localId, equals('local-1'));
    expect(s.shopId, equals('shop-1'));
    expect(s.items.length, equals(1));
    expect(s.totalAmount, equals(12.5));
  });

  test('SyncResult parsing and flags', () {
    final json = {
      'local_id': 'l1',
      'server_id': 's1',
      'status': 'synced',
      'server_timestamp': DateTime.now().toIso8601String(),
    };
    final r = SyncResult.fromJson(json);
    expect(r.isSuccess, isTrue);
    expect(r.isFailed, isFalse);
  });

  test('BatchSyncResponse.fromJson and helpers', () {
    final json = {
      'status': 'success',
      'sync_batch_id': 'batch1',
      'results': [
        {'local_id': 'l1', 'server_id': 's1', 'status': 'synced'}
      ],
      'synced_count': 1,
      'failed_count': 0,
    };
    final b = BatchSyncResponse.fromJson(json);
    expect(b.isSuccess, isTrue);
    expect(b.isPartial, isFalse);
  });

  test('SyncLog fromMap/toMap roundtrip', () {
    final now = DateTime.now();
    final log = SyncLog(
      id: 'log1',
      entityType: 'sale',
      entityId: 'e1',
      action: 'sync',
      status: 'success',
      errorMessage: null,
      syncBatchId: 'batch1',
      createdAt: now,
    );

    final m = log.toMap();
    final parsed = SyncLog.fromMap(m);
    expect(parsed.id, equals('log1'));
    expect(parsed.entityType, equals('sale'));
    expect(parsed.createdAt.runtimeType, equals(DateTime));
  });
}
