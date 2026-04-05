import 'package:equatable/equatable.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

// ============ SYNC STATUS ENUM ============
enum SyncStatus { idle, syncing, success, error }

// ============ SYNC REQUEST ============
class SyncRequest extends Equatable {
  final String syncBatchId;
  final DateTime syncTimestamp;
  final List<SaleForSync> sales;

  const SyncRequest({
    required this.syncBatchId,
    required this.syncTimestamp,
    required this.sales,
  });

  Map<String, dynamic> toJson() => {
    'sync_batch_id': syncBatchId,
    'sync_timestamp': syncTimestamp.toIso8601String(),
    'sales': sales.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [syncBatchId, syncTimestamp, sales];
}

// ============ SALE FOR SYNC ============
class SaleForSync extends Equatable {
  final String localId;
  final String shopId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final double discountAmount;
  final String paymentType;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final DateTime createdAt;

  const SaleForSync({
    required this.localId,
    required this.shopId,
    required this.items,
    required this.totalAmount,
    required this.discountAmount,
    required this.paymentType,
    this.customerId,
    this.customerName,
    this.notes,
    required this.createdAt,
  });

  factory SaleForSync.fromMap(Map<String, dynamic> map) {
    return SaleForSync(
      localId: map['id'] ?? '',
      shopId: map['shop_id'] ?? '',
      items: List<Map<String, dynamic>>.from(
        (map['items'] is String)
            ? _parseJsonString(map['items'])
            : (map['items'] as List? ?? []),
      ),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      paymentType: map['payment_type'] ?? 'cash',
      customerId: map['customer_id'],
      customerName: map['customer_name'],
      notes: map['notes'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'shop_id': shopId,
    'items': items,
    'total_amount': totalAmount,
    'discount_amount': discountAmount,
    'payment_type': paymentType,
    'customer_id': customerId,
    'customer_name': customerName,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    localId,
    shopId,
    items,
    totalAmount,
    discountAmount,
    paymentType,
    customerId,
    customerName,
    notes,
    createdAt,
  ];
}

// ============ SYNC RESULT ============
class SyncResult extends Equatable {
  final String localId;
  final String? serverId;
  final String status; // 'synced', 'failed'
  final String? error;
  final DateTime? serverTimestamp;

  const SyncResult({
    required this.localId,
    this.serverId,
    required this.status,
    this.error,
    this.serverTimestamp,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      localId: json['local_id'] ?? '',
      serverId: json['server_id'],
      status: json['status'] ?? 'failed',
      error: json['error'],
      serverTimestamp: json['server_timestamp'] is String
          ? DateTime.parse(json['server_timestamp'])
          : null,
    );
  }

  bool get isSuccess => status == 'synced';
  bool get isFailed => status == 'failed';

  @override
  List<Object?> get props => [
    localId,
    serverId,
    status,
    error,
    serverTimestamp,
  ];
}

// ============ BATCH SYNC RESPONSE ============
class BatchSyncResponse extends Equatable {
  final String status; // 'success', 'partial', 'failed'
  final String syncBatchId;
  final List<SyncResult> results;
  final int syncedCount;
  final int failedCount;

  const BatchSyncResponse({
    required this.status,
    required this.syncBatchId,
    required this.results,
    required this.syncedCount,
    required this.failedCount,
  });

  factory BatchSyncResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List? ?? [])
        .map((r) => SyncResult.fromJson(r as Map<String, dynamic>))
        .toList();

    return BatchSyncResponse(
      status: json['status'] ?? 'failed',
      syncBatchId: json['sync_batch_id'] ?? '',
      results: results,
      syncedCount: json['synced_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
    );
  }

  bool get isSuccess => failedCount == 0;
  bool get isPartial => failedCount > 0 && syncedCount > 0;

  @override
  List<Object?> get props => [
    status,
    syncBatchId,
    results,
    syncedCount,
    failedCount,
  ];
}

// ============ SYNC LOG ============
class SyncLog extends Equatable {
  final String id;
  final String entityType; // 'sale', 'product'
  final String entityId;
  final String action; // 'sync', 'conflict', 'error'
  final String status; // 'success', 'failed', 'retry'
  final String? errorMessage;
  final String? syncBatchId;
  final DateTime createdAt;

  const SyncLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.status,
    this.errorMessage,
    this.syncBatchId,
    required this.createdAt,
  });

  factory SyncLog.fromMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id'] ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id'] ?? '',
      action: map['action'] ?? '',
      status: map['status'] ?? '',
      errorMessage: map['error_message'],
      syncBatchId: map['sync_batch_id'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'action': action,
    'status': status,
    'error_message': errorMessage,
    'sync_batch_id': syncBatchId,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    entityType,
    entityId,
    action,
    status,
    errorMessage,
    syncBatchId,
    createdAt,
  ];
}

// ============ UTILITY FUNCTIONS ============

List<dynamic> _parseJsonString(String jsonString) {
  try {
    // Simple parsing for JSON array strings
    if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
      // Use a basic JSON parser or return empty list
      return [];
    }
  } catch (e) {
    getLogger('app').info('Error parsing JSON: $e');
  }
  return [];
}

