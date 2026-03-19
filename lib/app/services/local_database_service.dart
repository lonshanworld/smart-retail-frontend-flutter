import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'platform_paths.dart';
import 'package:uuid/uuid.dart';

class LocalDatabaseService {
  static const String DB_NAME = 'smart_retail.db';
  static const int DB_VERSION = 2;
  static Database? _database;

  // Table names
  static const String TABLE_OFFLINE_SALES = 'offline_sales';
  static const String TABLE_CACHED_PRODUCTS = 'cached_products';
  static const String TABLE_CACHED_PROMOTIONS = 'cached_promotions';
  static const String TABLE_CACHED_SHOP_INFO = 'cached_shop_info';
  static const String TABLE_SYNC_LOG = 'sync_log';
  static const String TABLE_APP_SETTINGS = 'app_settings';
  static const String TABLE_OFFLINE_OPERATIONS = 'offline_operations';

  // Column names - offline_sales
  static const String COL_ID = 'id';
  static const String COL_SHOP_ID = 'shop_id';
  static const String COL_ITEMS = 'items';
  static const String COL_TOTAL_AMOUNT = 'total_amount';
  static const String COL_DISCOUNT_AMOUNT = 'discount_amount';
  static const String COL_PAYMENT_TYPE = 'payment_type';
  static const String COL_CUSTOMER_ID = 'customer_id';
  static const String COL_CUSTOMER_NAME = 'customer_name';
  static const String COL_NOTES = 'notes';
  static const String COL_STATUS = 'status';
  static const String COL_SYNC_ATTEMPTS = 'sync_attempts';
  static const String COL_LAST_SYNC_ERROR = 'last_sync_error';
  static const String COL_SERVER_SALE_ID = 'server_sale_id';
  static const String COL_CREATED_AT = 'created_at';
  static const String COL_SYNCED_AT = 'synced_at';
  static const String COL_UPDATED_AT = 'updated_at';

  // Column names - offline_operations
  static const String COL_CLIENT_OPERATION_ID = 'client_operation_id';
  static const String COL_ENTITY_TYPE = 'entity_type';
  static const String COL_ACTION = 'action';
  static const String COL_METHOD = 'method';
  static const String COL_ENDPOINT = 'endpoint';
  static const String COL_PAYLOAD = 'payload';
  static const String COL_HEADERS = 'headers';
  static const String COL_RESPONSE_CODE = 'response_code';
  static const String COL_RESPONSE_BODY = 'response_body';

  // Status values
  static const String STATUS_PENDING = 'pending';
  static const String STATUS_SYNCING = 'syncing';
  static const String STATUS_SYNCED = 'synced';
  static const String STATUS_FAILED = 'failed';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await _getDbPath();
    return await openDatabase(
      dbPath,
      version: DB_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> _getDbPath() async {
    final basePath = await getPreferredDatabaseDirectory();
    if (basePath.isEmpty) {
      // On web, return name-only (sqflite_web or similar will handle storage)
      return DB_NAME;
    }
    return join(basePath, DB_NAME);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create offline_sales table
    await db.execute('''
      CREATE TABLE $TABLE_OFFLINE_SALES (
        $COL_ID TEXT PRIMARY KEY,
        $COL_SHOP_ID TEXT NOT NULL,
        $COL_ITEMS TEXT NOT NULL,
        $COL_TOTAL_AMOUNT REAL NOT NULL,
        $COL_DISCOUNT_AMOUNT REAL DEFAULT 0.0,
        $COL_PAYMENT_TYPE TEXT NOT NULL,
        $COL_CUSTOMER_ID TEXT,
        $COL_CUSTOMER_NAME TEXT,
        $COL_NOTES TEXT,
        $COL_STATUS TEXT DEFAULT 'pending',
        $COL_SYNC_ATTEMPTS INTEGER DEFAULT 0,
        $COL_LAST_SYNC_ERROR TEXT,
        $COL_SERVER_SALE_ID TEXT,
        $COL_CREATED_AT TEXT NOT NULL,
        $COL_SYNCED_AT TEXT,
        $COL_UPDATED_AT TEXT NOT NULL
      )
    ''');

    // Create indexes for offline_sales
    await db.execute(
      'CREATE INDEX idx_offline_sales_status ON $TABLE_OFFLINE_SALES($COL_STATUS)',
    );
    await db.execute(
      'CREATE INDEX idx_offline_sales_shop_id ON $TABLE_OFFLINE_SALES($COL_SHOP_ID)',
    );
    await db.execute(
      'CREATE INDEX idx_offline_sales_synced_at ON $TABLE_OFFLINE_SALES($COL_SYNCED_AT)',
    );

    // Create cached_products table
    await db.execute('''
      CREATE TABLE $TABLE_CACHED_PRODUCTS (
        id TEXT PRIMARY KEY,
        merchant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sku TEXT,
        category TEXT,
        selling_price REAL NOT NULL,
        original_price REAL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_cached_products_merchant_id ON $TABLE_CACHED_PRODUCTS(merchant_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cached_products_expires_at ON $TABLE_CACHED_PRODUCTS(expires_at)',
    );

    // Create cached_promotions table
    await db.execute('''
      CREATE TABLE $TABLE_CACHED_PROMOTIONS (
        id TEXT PRIMARY KEY,
        merchant_id TEXT NOT NULL,
        shop_id TEXT,
        name TEXT NOT NULL,
        promo_type TEXT NOT NULL,
        promo_value REAL NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_cached_promotions_merchant_id ON $TABLE_CACHED_PROMOTIONS(merchant_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cached_promotions_shop_id ON $TABLE_CACHED_PROMOTIONS(shop_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cached_promotions_expires_at ON $TABLE_CACHED_PROMOTIONS(expires_at)',
    );

    // Create cached_shop_info table
    await db.execute('''
      CREATE TABLE $TABLE_CACHED_SHOP_INFO (
        id TEXT PRIMARY KEY,
        merchant_id TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_cached_shop_merchant_id ON $TABLE_CACHED_SHOP_INFO(merchant_id)',
    );

    // Create sync_log table
    await db.execute('''
      CREATE TABLE $TABLE_SYNC_LOG (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        status TEXT NOT NULL,
        error_message TEXT,
        sync_batch_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_sync_log_created_at ON $TABLE_SYNC_LOG(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_log_status ON $TABLE_SYNC_LOG(status)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_log_batch_id ON $TABLE_SYNC_LOG(sync_batch_id)',
    );

    // Create app_settings table
    await db.execute('''
      CREATE TABLE $TABLE_APP_SETTINGS (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $TABLE_OFFLINE_OPERATIONS (
        $COL_ID TEXT PRIMARY KEY,
        $COL_CLIENT_OPERATION_ID TEXT UNIQUE NOT NULL,
        $COL_ENTITY_TYPE TEXT NOT NULL,
        $COL_ACTION TEXT NOT NULL,
        $COL_METHOD TEXT NOT NULL,
        $COL_ENDPOINT TEXT NOT NULL,
        $COL_PAYLOAD TEXT NOT NULL,
        $COL_HEADERS TEXT,
        $COL_STATUS TEXT NOT NULL DEFAULT 'pending',
        $COL_SYNC_ATTEMPTS INTEGER DEFAULT 0,
        $COL_LAST_SYNC_ERROR TEXT,
        $COL_RESPONSE_CODE INTEGER,
        $COL_RESPONSE_BODY TEXT,
        $COL_CREATED_AT TEXT NOT NULL,
        $COL_SYNCED_AT TEXT,
        $COL_UPDATED_AT TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_offline_operations_status ON $TABLE_OFFLINE_OPERATIONS($COL_STATUS)',
    );
    await db.execute(
      'CREATE INDEX idx_offline_operations_created_at ON $TABLE_OFFLINE_OPERATIONS($COL_CREATED_AT)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $TABLE_OFFLINE_OPERATIONS (
          $COL_ID TEXT PRIMARY KEY,
          $COL_CLIENT_OPERATION_ID TEXT UNIQUE NOT NULL,
          $COL_ENTITY_TYPE TEXT NOT NULL,
          $COL_ACTION TEXT NOT NULL,
          $COL_METHOD TEXT NOT NULL,
          $COL_ENDPOINT TEXT NOT NULL,
          $COL_PAYLOAD TEXT NOT NULL,
          $COL_HEADERS TEXT,
          $COL_STATUS TEXT NOT NULL DEFAULT 'pending',
          $COL_SYNC_ATTEMPTS INTEGER DEFAULT 0,
          $COL_LAST_SYNC_ERROR TEXT,
          $COL_RESPONSE_CODE INTEGER,
          $COL_RESPONSE_BODY TEXT,
          $COL_CREATED_AT TEXT NOT NULL,
          $COL_SYNCED_AT TEXT,
          $COL_UPDATED_AT TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_offline_operations_status ON $TABLE_OFFLINE_OPERATIONS($COL_STATUS)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_offline_operations_created_at ON $TABLE_OFFLINE_OPERATIONS($COL_CREATED_AT)',
      );
    }
  }

  // ============ OFFLINE SALES METHODS ============

  Future<void> queueSale(Map<String, dynamic> saleData) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final saleId = (saleData['id']?.toString().isNotEmpty ?? false)
        ? saleData['id'].toString()
        : const Uuid().v4();

    final sale = {
      COL_ID: saleId,
      ...saleData,
      COL_STATUS: STATUS_PENDING,
      COL_SYNC_ATTEMPTS: 0,
      COL_CREATED_AT: now,
      COL_UPDATED_AT: now,
    };

    await db.insert(
      TABLE_OFFLINE_SALES,
      sale,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSales() async {
    final db = await database;
    return await db.query(
      TABLE_OFFLINE_SALES,
      where: '$COL_STATUS = ?',
      whereArgs: [STATUS_PENDING],
      orderBy: '$COL_CREATED_AT ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getFailedSales() async {
    final db = await database;
    return await db.query(
      TABLE_OFFLINE_SALES,
      where: '$COL_STATUS = ? OR $COL_STATUS = ?',
      whereArgs: [STATUS_FAILED, STATUS_SYNCING],
      orderBy: '$COL_CREATED_AT ASC',
    );
  }

  Future<void> markSaleAsSynced(String saleId, String serverSaleId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      TABLE_OFFLINE_SALES,
      {
        COL_STATUS: STATUS_SYNCED,
        COL_SERVER_SALE_ID: serverSaleId,
        COL_SYNCED_AT: now,
        COL_UPDATED_AT: now,
        COL_SYNC_ATTEMPTS: 0,
        COL_LAST_SYNC_ERROR: null,
      },
      where: '$COL_ID = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> markSaleAsSyncing(String saleId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      TABLE_OFFLINE_SALES,
      {COL_STATUS: STATUS_SYNCING, COL_UPDATED_AT: now},
      where: '$COL_ID = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> markSaleFailed(String saleId, String? errorMsg) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final sale = await db.query(
      TABLE_OFFLINE_SALES,
      where: '$COL_ID = ?',
      whereArgs: [saleId],
    );

    if (sale.isEmpty) return;

    int attempts = (sale.first[COL_SYNC_ATTEMPTS] as int?) ?? 0;

    await db.update(
      TABLE_OFFLINE_SALES,
      {
        COL_STATUS: STATUS_FAILED,
        COL_LAST_SYNC_ERROR: errorMsg,
        COL_SYNC_ATTEMPTS: attempts + 1,
        COL_UPDATED_AT: now,
      },
      where: '$COL_ID = ?',
      whereArgs: [saleId],
    );
  }

  Future<int> getPendingSalesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_OFFLINE_SALES WHERE $COL_STATUS = ?',
      [STATUS_PENDING],
    );
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  Future<void> deleteSale(String saleId) async {
    final db = await database;
    await db.delete(
      TABLE_OFFLINE_SALES,
      where: '$COL_ID = ?',
      whereArgs: [saleId],
    );
  }

  Future<void> clearAllSales() async {
    final db = await database;
    await db.delete(TABLE_OFFLINE_SALES);
  }

  // ============ OFFLINE OPERATION QUEUE METHODS ============

  Future<void> queueOperation(Map<String, dynamic> operation) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final operationId = (operation[COL_CLIENT_OPERATION_ID]?.toString().isNotEmpty ?? false)
        ? operation[COL_CLIENT_OPERATION_ID].toString()
        : const Uuid().v4();

    await db.insert(
      TABLE_OFFLINE_OPERATIONS,
      {
        COL_ID: operation[COL_ID] ?? const Uuid().v4(),
        COL_CLIENT_OPERATION_ID: operationId,
        COL_ENTITY_TYPE: operation[COL_ENTITY_TYPE] ?? 'unknown',
        COL_ACTION: operation[COL_ACTION] ?? 'mutation',
        COL_METHOD: operation[COL_METHOD] ?? 'POST',
        COL_ENDPOINT: operation[COL_ENDPOINT] ?? '',
        COL_PAYLOAD: operation[COL_PAYLOAD] is String
            ? operation[COL_PAYLOAD]
            : _jsonEncode(operation[COL_PAYLOAD] ?? {}),
        COL_HEADERS: operation[COL_HEADERS] is String
            ? operation[COL_HEADERS]
            : (operation[COL_HEADERS] != null ? _jsonEncode(operation[COL_HEADERS]) : null),
        COL_STATUS: STATUS_PENDING,
        COL_SYNC_ATTEMPTS: 0,
        COL_CREATED_AT: now,
        COL_UPDATED_AT: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query(
      TABLE_OFFLINE_OPERATIONS,
      where: '$COL_STATUS = ?',
      whereArgs: [STATUS_PENDING],
      orderBy: '$COL_CREATED_AT ASC',
    );
  }

  Future<void> markOperationAsSynced(String operationId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      TABLE_OFFLINE_OPERATIONS,
      {
        COL_STATUS: STATUS_SYNCED,
        COL_SYNCED_AT: now,
        COL_UPDATED_AT: now,
        COL_LAST_SYNC_ERROR: null,
      },
      where: '$COL_ID = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> markOperationFailed(String operationId, String? errorMsg) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final op = await db.query(
      TABLE_OFFLINE_OPERATIONS,
      where: '$COL_ID = ?',
      whereArgs: [operationId],
    );
    if (op.isEmpty) return;
    final attempts = (op.first[COL_SYNC_ATTEMPTS] as int?) ?? 0;
    await db.update(
      TABLE_OFFLINE_OPERATIONS,
      {
        COL_STATUS: STATUS_FAILED,
        COL_SYNC_ATTEMPTS: attempts + 1,
        COL_LAST_SYNC_ERROR: errorMsg,
        COL_UPDATED_AT: now,
      },
      where: '$COL_ID = ?',
      whereArgs: [operationId],
    );
  }

  Future<int> getPendingOperationsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_OFFLINE_OPERATIONS WHERE $COL_STATUS = ?',
      [STATUS_PENDING],
    );
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  // ============ CACHE METHODS ============

  Future<void> cacheProducts(
    List<Map<String, dynamic>> products,
    String merchantId,
  ) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: 24));

    for (var product in products) {
      await db.insert(TABLE_CACHED_PRODUCTS, {
        'id': product['id'],
        'merchant_id': merchantId,
        'name': product['name'] ?? '',
        'sku': product['sku'],
        'category': product['category'],
        'selling_price': product['selling_price'] ?? 0.0,
        'original_price': product['original_price'],
        'data': _jsonEncode(product),
        'cached_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedProducts(
    String merchantId,
  ) async {
    final db = await database;
    final now = DateTime.now();

    // Check if cache is expired
    final expiredRecords = await db.query(
      TABLE_CACHED_PRODUCTS,
      where: 'merchant_id = ? AND expires_at < ?',
      whereArgs: [merchantId, now.toIso8601String()],
    );

    if (expiredRecords.isNotEmpty) {
      // Delete expired records
      for (var record in expiredRecords) {
        await db.delete(
          TABLE_CACHED_PRODUCTS,
          where: 'id = ?',
          whereArgs: [record['id']],
        );
      }
    }

    final products = await db.query(
      TABLE_CACHED_PRODUCTS,
      where: 'merchant_id = ? AND expires_at > ?',
      whereArgs: [merchantId, now.toIso8601String()],
    );

    return products.isEmpty ? null : products;
  }

  Future<void> cachePromotions(
    List<Map<String, dynamic>> promotions,
    String merchantId,
  ) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: 24));

    for (var promo in promotions) {
      await db.insert(TABLE_CACHED_PROMOTIONS, {
        'id': promo['id'],
        'merchant_id': merchantId,
        'shop_id': promo['shop_id'],
        'name': promo['name'] ?? '',
        'promo_type': promo['promo_type'] ?? '',
        'promo_value': promo['promo_value'] ?? 0.0,
        'data': _jsonEncode(promo),
        'cached_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>?> getCachedPromotions(
    String merchantId,
  ) async {
    final db = await database;
    final now = DateTime.now();

    // Delete expired records
    await db.delete(
      TABLE_CACHED_PROMOTIONS,
      where: 'merchant_id = ? AND expires_at < ?',
      whereArgs: [merchantId, now.toIso8601String()],
    );

    final promotions = await db.query(
      TABLE_CACHED_PROMOTIONS,
      where: 'merchant_id = ? AND expires_at > ?',
      whereArgs: [merchantId, now.toIso8601String()],
    );

    return promotions.isEmpty ? null : promotions;
  }

  Future<void> cacheShopInfo(
    Map<String, dynamic> shopInfo,
    String merchantId,
  ) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: 7));

    await db.insert(TABLE_CACHED_SHOP_INFO, {
      'id': shopInfo['id'],
      'merchant_id': merchantId,
      'name': shopInfo['name'] ?? '',
      'address': shopInfo['address'],
      'data': _jsonEncode(shopInfo),
      'cached_at': now.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedShopInfo(String shopId) async {
    final db = await database;
    final now = DateTime.now();

    // Delete expired records
    await db.delete(
      TABLE_CACHED_SHOP_INFO,
      where: 'id = ? AND expires_at < ?',
      whereArgs: [shopId, now.toIso8601String()],
    );

    final result = await db.query(
      TABLE_CACHED_SHOP_INFO,
      where: 'id = ? AND expires_at > ?',
      whereArgs: [shopId, now.toIso8601String()],
    );

    return result.isEmpty ? null : result.first;
  }

  Future<bool> isCacheExpired(String cacheType) async {
    final db = await database;
    final now = DateTime.now();
    String table = '';

    if (cacheType == 'products') {
      table = TABLE_CACHED_PRODUCTS;
    } else if (cacheType == 'promotions') {
      table = TABLE_CACHED_PROMOTIONS;
    } else if (cacheType == 'shop_info') {
      table = TABLE_CACHED_SHOP_INFO;
    }

    if (table.isEmpty) return true;

    final result = await db.query(
      table,
      where: 'expires_at > ?',
      whereArgs: [now.toIso8601String()],
      limit: 1,
    );

    return result.isEmpty;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now();

    await db.delete(
      TABLE_CACHED_PRODUCTS,
      where: 'expires_at < ?',
      whereArgs: [now.toIso8601String()],
    );

    await db.delete(
      TABLE_CACHED_PROMOTIONS,
      where: 'expires_at < ?',
      whereArgs: [now.toIso8601String()],
    );

    await db.delete(
      TABLE_CACHED_SHOP_INFO,
      where: 'expires_at < ?',
      whereArgs: [now.toIso8601String()],
    );
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete(TABLE_CACHED_PRODUCTS);
    await db.delete(TABLE_CACHED_PROMOTIONS);
    await db.delete(TABLE_CACHED_SHOP_INFO);
  }

  // ============ SYNC LOG METHODS ============

  Future<void> logSyncAttempt(Map<String, dynamic> log) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(TABLE_SYNC_LOG, {
      ...log,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50}) async {
    final db = await database;
    return await db.query(
      TABLE_SYNC_LOG,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<int> getSyncSuccessCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_SYNC_LOG WHERE status = ?',
      ['success'],
    );
    return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
  }

  // ============ SETTINGS METHODS ============

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(TABLE_APP_SETTINGS, {
      'key': key,
      'value': value,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      TABLE_APP_SETTINGS,
      where: 'key = ?',
      whereArgs: [key],
    );

    return result.isEmpty ? null : result.first['value'] as String?;
  }

  Future<DateTime?> getLastSyncTime() async {
    final lastSyncStr = await getSetting('last_sync_time');
    return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await setSetting('last_sync_time', time.toIso8601String());
  }

  // ============ UTILITY METHODS ============

  Future<String> calculateCacheSize() async {
    final db = await database;

    final productsSize = await _getTableSize(db, TABLE_CACHED_PRODUCTS);
    final promotionsSize = await _getTableSize(db, TABLE_CACHED_PROMOTIONS);
    final shopSize = await _getTableSize(db, TABLE_CACHED_SHOP_INFO);
    final salesSize = await _getTableSize(db, TABLE_OFFLINE_SALES);

    final totalBytes = productsSize + promotionsSize + shopSize + salesSize;

    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<int> _getTableSize(Database db, String table) async {
    try {
      final result = await db.rawQuery(
        'SELECT page_count * page_size as size FROM pragma_page_count, pragma_page_size',
      );
      return result.isNotEmpty ? (result.first['size'] as int?) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  String _jsonEncode(Map<String, dynamic> data) {
    // Simple JSON encoding - can use jsonEncode from dart:convert
    // For now, we'll store the map directly
    return data.toString();
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
