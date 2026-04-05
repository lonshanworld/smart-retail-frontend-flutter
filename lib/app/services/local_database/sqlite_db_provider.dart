import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

/// Simple sqlite-backed provider that stores rows as JSON in per-table
/// SQLite tables. Each table has schema: (id TEXT PRIMARY KEY, data TEXT).
class SqliteDbProvider {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'smart_retail_local.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {},
      onOpen: (db) async {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              password_hash TEXT NOT NULL,
              phone TEXT,
              role TEXT NOT NULL,
              is_active INTEGER DEFAULT 1,
              merchant_id TEXT,
              business_type TEXT DEFAULT 'retail',
              settings TEXT DEFAULT '{}',
              opening_hours TEXT,
              supports_delivery INTEGER DEFAULT 0,
              assigned_shop_id TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS staff_contracts (
              id TEXT PRIMARY KEY,
              staff_id TEXT NOT NULL,
              salary REAL NOT NULL,
              pay_frequency TEXT NOT NULL,
              start_date TEXT NOT NULL,
              end_date TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS inventory_items (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              name TEXT,
              description TEXT,
              sku TEXT,
              selling_price REAL,
              original_price REAL,
              low_stock_threshold INTEGER,
              category TEXT,
              category_id TEXT,
              subcategory_id TEXT,
              brand_id TEXT,
              supplier_id TEXT,
              is_archived INTEGER DEFAULT 0,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS shop_stock (
              id TEXT PRIMARY KEY,
              inventory_item_id TEXT,
              shop_id TEXT,
              shop_name TEXT,
              quantity INTEGER
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS sales (
              id TEXT PRIMARY KEY,
              client_sale_id TEXT UNIQUE,
              merchant_id TEXT,
              shop_id TEXT,
              staff_id TEXT,
              customer_id TEXT,
              sale_date TEXT,
              total_amount REAL,
              delivery_charge REAL DEFAULT 0.0,
              applied_promotion_id TEXT,
              created_at TEXT,
              updated_at TEXT,
              discount_amount REAL DEFAULT 0.0,
              payment_type TEXT,
              payment_status TEXT,
              stripe_payment_intent_id TEXT,
              notes TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_items (
              id TEXT PRIMARY KEY,
              sale_id TEXT,
              inventory_item_id TEXT,
              item_name TEXT,
              item_sku TEXT,
              quantity_sold INTEGER,
              selling_price_at_sale REAL,
              original_price_at_sale REAL,
              subtotal REAL
              ,created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS shops (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              merchant_id TEXT,
              address TEXT,
              phone TEXT,
              tax_rate REAL DEFAULT 5.0,
              is_active INTEGER DEFAULT 1,
              is_primary INTEGER DEFAULT 0,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS suppliers (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              name TEXT,
              contact_name TEXT,
              contact_email TEXT,
              contact_phone TEXT,
              address TEXT,
              notes TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS promotions (
              id TEXT PRIMARY KEY,
              merchantId TEXT,
              merchant_id TEXT,
              shopId TEXT,
              shop_id TEXT,
              name TEXT,
              description TEXT,
              type TEXT,
              value REAL,
              minSpend REAL,
              conditions TEXT,
              isActive INTEGER,
              startDate TEXT,
              endDate TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              promo_type TEXT,
              promo_value REAL,
              min_spend REAL,
              start_date TEXT,
              end_date TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS stock_movements (
              id TEXT PRIMARY KEY,
              inventory_item_id TEXT,
              shopId TEXT,
              shop_id TEXT,
              itemId TEXT,
              item_id TEXT,
              user_id TEXT,
              movement_type TEXT,
              quantity_changed INTEGER,
              new_quantity INTEGER,
              quantity REAL,
              actorId TEXT,
              notes TEXT,
              reason TEXT,
              clientOperationId TEXT,
              movement_date TEXT,
              time TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS inventory_operations (
              id TEXT PRIMARY KEY,
              client_operation_id TEXT UNIQUE NOT NULL,
              operation_type TEXT NOT NULL,
              actor_id TEXT NOT NULL,
              shop_id TEXT,
              created_at TEXT
            );
          ''');
          // Catalog tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              name TEXT,
              description TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS subcategories (
              id TEXT PRIMARY KEY,
              category_id TEXT,
              merchant_id TEXT,
              name TEXT,
              description TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS brands (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              name TEXT,
              description TEXT,
              image_url TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS shop_customers (
              id TEXT PRIMARY KEY,
              shop_id TEXT,
              merchant_id TEXT,
              name TEXT NOT NULL,
              email TEXT,
              phone TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS promotion_products (
              promotion_id TEXT NOT NULL,
              inventory_item_id TEXT NOT NULL,
              PRIMARY KEY (promotion_id, inventory_item_id)
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS invoices (
              id TEXT PRIMARY KEY,
              sale_id TEXT UNIQUE,
              invoice_number TEXT NOT NULL UNIQUE,
              merchant_id TEXT NOT NULL,
              shop_id TEXT NOT NULL,
              customer_id TEXT,
              invoice_date TEXT,
              due_date TEXT,
              subtotal REAL NOT NULL,
              discount_amount REAL DEFAULT 0.0,
              tax_amount REAL DEFAULT 0.0,
              delivery_charge REAL DEFAULT 0.0,
              total_amount REAL NOT NULL,
              payment_status TEXT DEFAULT 'paid',
              notes TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS salary_payments (
              id TEXT PRIMARY KEY,
              staff_id TEXT NOT NULL,
              payment_date TEXT NOT NULL,
              amount_paid REAL NOT NULL,
              payment_period_start TEXT NOT NULL,
              payment_period_end TEXT NOT NULL,
              payment_method TEXT,
              notes TEXT,
              created_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS notifications (
              id TEXT PRIMARY KEY,
              recipient_user_id TEXT NOT NULL,
              title TEXT NOT NULL,
              message TEXT NOT NULL,
              notification_type TEXT,
              related_entity_type TEXT,
              related_entity_id TEXT,
              is_read INTEGER DEFAULT 0,
              created_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS payment_settings (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              shop_id TEXT,
              qr_image_url TEXT DEFAULT '',
              tax REAL DEFAULT 0,
              service_charge REAL DEFAULT 0,
              delivery_charge REAL DEFAULT 0,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS testimonials (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              shop_id TEXT,
              name TEXT NOT NULL,
              role TEXT,
              content TEXT NOT NULL,
              rating INTEGER DEFAULT 5,
              avatar TEXT,
              is_active INTEGER DEFAULT 1,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS support_tickets (
              id TEXT PRIMARY KEY,
              merchant_id TEXT,
              shop_id TEXT,
              subject TEXT NOT NULL,
              status TEXT DEFAULT 'OPEN',
              priority TEXT DEFAULT 'MEDIUM',
              customer_name TEXT,
              customer_email TEXT,
              customer_phone TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS support_messages (
              id TEXT PRIMARY KEY,
              ticket_id TEXT NOT NULL,
              sender_role TEXT DEFAULT 'CUSTOMER',
              content TEXT NOT NULL,
              is_admin_reply INTEGER DEFAULT 0,
              created_at TEXT
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS external_id_map (
              id TEXT PRIMARY KEY,
              source TEXT NOT NULL,
              source_id TEXT NOT NULL,
              target_table TEXT NOT NULL,
              target_id TEXT NOT NULL,
              created_at TEXT,
              UNIQUE(source, source_id, target_table)
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS migration_audit (
              id TEXT PRIMARY KEY,
              source TEXT NOT NULL,
              source_id TEXT,
              target_table TEXT,
              payload TEXT,
              imported_at TEXT
            );
          ''');

          await db.execute('''
            CREATE VIEW IF NOT EXISTS shop_settings_view AS
            SELECT s.id AS shop_id,
                   s.merchant_id,
                   s.name AS shop_name,
                   s.business_type,
                   COALESCE(ps.tax, 0) AS tax,
                   COALESCE(ps.service_charge, 0) AS service_charge,
                   COALESCE(ps.delivery_charge, 0) AS delivery_charge,
                   s.settings AS shop_settings,
                   s.opening_hours
            FROM shops s
            LEFT JOIN payment_settings ps ON ps.shop_id = s.id;
          ''');

          // Backfill missing columns for older local DB versions.
          await _addColumnIfNotExists(db, 'sales', 'shop_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'client_sale_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'staff_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'customer_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'sale_date', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'delivery_charge', 'REAL');
          await _addColumnIfNotExists(db, 'sales', 'applied_promotion_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'discount_amount', 'REAL');
          await _addColumnIfNotExists(db, 'sales', 'payment_type', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'payment_status', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'stripe_payment_intent_id', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'notes', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'created_at', 'TEXT');
          await _addColumnIfNotExists(db, 'sales', 'updated_at', 'TEXT');
          await _addColumnIfNotExists(db, 'shop_stock', 'shop_id', 'TEXT');
          await _addColumnIfNotExists(db, 'shop_stock', 'shop_name', 'TEXT');
          await _addColumnIfNotExists(db, 'shop_stock', 'last_stocked_in_at', 'TEXT');
          await _addColumnIfNotExists(db, 'promotions', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'business_type', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'settings', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'opening_hours', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'supports_delivery', 'INTEGER');
          await _addColumnIfNotExists(db, 'promotions', 'shop_id', 'TEXT');
          await _addColumnIfNotExists(db, 'subcategories', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'promotions', 'promo_type', 'TEXT');
          await _addColumnIfNotExists(db, 'promotions', 'promo_value', 'REAL');
          await _addColumnIfNotExists(db, 'promotions', 'min_spend', 'REAL');
          await _addColumnIfNotExists(db, 'staff_contracts', 'staff_id', 'TEXT');
          await _addColumnIfNotExists(db, 'staff_contracts', 'salary', 'REAL');
          await _addColumnIfNotExists(db, 'staff_contracts', 'pay_frequency', 'TEXT');
          await _addColumnIfNotExists(db, 'staff_contracts', 'start_date', 'TEXT');
          await _addColumnIfNotExists(db, 'staff_contracts', 'end_date', 'TEXT');
          await _addColumnIfNotExists(db, 'staff_contracts', 'is_active', 'INTEGER');
          await _addColumnIfNotExists(db, 'staff_contracts', 'created_at', 'TEXT');
          await _addColumnIfNotExists(db, 'staff_contracts', 'updated_at', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_operations', 'client_operation_id', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_operations', 'operation_type', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_operations', 'actor_id', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_operations', 'shop_id', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_operations', 'created_at', 'TEXT');
          await _addColumnIfNotExists(db, 'promotions', 'updated_at', 'TEXT');
          await _addColumnIfNotExists(db, 'inventory_items', 'is_archived', 'INTEGER');
          await _addColumnIfNotExists(db, 'brands', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'categories', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'shop_customers', 'merchant_id', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'phone', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'tax_rate', 'REAL');
          await _addColumnIfNotExists(db, 'shops', 'is_active', 'INTEGER');
          await _addColumnIfNotExists(db, 'shops', 'is_primary', 'INTEGER');
          await _addColumnIfNotExists(db, 'shops', 'business_type', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'settings', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'opening_hours', 'TEXT');
          await _addColumnIfNotExists(db, 'shops', 'supports_delivery', 'INTEGER');
        } catch (_) {}
      },
    );
    return _db!;
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String columnType,
  ) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info('$table')");
    final hasColumn = tableInfo.any((row) => row['name'] == column);
    if (!hasColumn) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $columnType');
      } catch (_) {
        // ignore if fails due to race/migration issues
      }
    }
  }

  Future<void> ensureTable(String name) async {
    final db = await database;
    final safe = name.replaceAll('"', '');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS "$safe" (id TEXT PRIMARY KEY, data TEXT)',
    );
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    try {
      await ensureTable(table);
      final db = await database;
      final rows = await db.query(table);
      final decodedRows = rows.map((r) {
        // If table uses a JSON-backed storage column, decode the JSON.
        if (r.containsKey('data')) {
          final data = r['data'] as String?;
          if (data == null) {
            return {'id': r['id']};
          }
          final decoded = json.decode(data) as Map<String, dynamic>;
          if (!decoded.containsKey('id')) decoded['id'] = r['id'];
          return decoded;
        }

        // Structured tables return all columns directly.
        return Map<String, dynamic>.from(r);
      }).toList();

      decodedRows.sort((left, right) => _compareNewestFirst(left, right));
      return decodedRows;
    } catch (_) {
      return [];
    }
  }

  int _compareNewestFirst(Map<String, dynamic> left, Map<String, dynamic> right) {
    final leftKey = _resolveSortKey(left);
    final rightKey = _resolveSortKey(right);

    if (leftKey == null && rightKey == null) return 0;
    if (leftKey == null) return 1;
    if (rightKey == null) return -1;

    final leftDate = DateTime.tryParse(leftKey);
    final rightDate = DateTime.tryParse(rightKey);
    if (leftDate != null && rightDate != null) {
      return rightDate.compareTo(leftDate);
    }

    final leftNum = int.tryParse(leftKey);
    final rightNum = int.tryParse(rightKey);
    if (leftNum != null && rightNum != null) {
      return rightNum.compareTo(leftNum);
    }

    return rightKey.compareTo(leftKey);
  }

  String? _resolveSortKey(Map<String, dynamic> row) {
    const candidates = [
      'created_at',
      'createdAt',
      'updated_at',
      'updatedAt',
      'movement_date',
      'movementDate',
      'sale_date',
      'saleDate',
      'invoice_date',
      'invoiceDate',
      'time',
      'id',
    ];

    for (final key in candidates) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Future<void> insertOrReplace(String table, Map<String, dynamic> row) async {
    await ensureTable(table);
    final db = await database;
    final logMessage =
        'DEBUG [SqliteDbProvider] insertOrReplace called for "$table" with row: $row';
    getLogger('app').info(logMessage);
    print(logMessage);
    // Inspect table schema to decide whether it's a JSON-backed table (id,data)
    try {
      final pragma = await db.rawQuery("PRAGMA table_info('$table')");
      final hasDataCol = pragma.any((c) => (c['name'] as String?) == 'data');
      if (hasDataCol) {
        final id =
            row['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        final data = json.encode(row);
        await db.insert(table, {
          'id': id,
          'data': data,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      }
      // Structured table: map provided keys to available columns and insert
      final columns = pragma.map((c) => c['name'] as String).toList();
      final insertMap = <String, dynamic>{};
      for (final col in columns) {
        if (col == 'rowid') continue;
        if (col == 'id') {
          insertMap['id'] =
              row['id']?.toString() ??
              DateTime.now().microsecondsSinceEpoch.toString();
          continue;
        }
        // Prefer exact key, fall back to common variants
        if (row.containsKey(col)) {
          insertMap[col] = row[col];
          continue;
        }
        // snake_case <-> camelCase fallback
        final camel = col
            .split('_')
            .map((s) => s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1)))
            .join();
        final camelKey = camel[0].toLowerCase() + camel.substring(1);
        if (row.containsKey(camelKey)) {
          insertMap[col] = row[camelKey];
          continue;
        }
        // lastly, try deprecated variants
        insertMap[col] = row[col];
      }
      final insertMapLog =
          'DEBUG [SqliteDbProvider] insertMap for "$table": $insertMap';
      getLogger('app').info(insertMapLog);
      print(insertMapLog);
      for (final entry in insertMap.entries) {
        if (entry.value is Map) {
          final mapValueLog =
              'DEBUG [SqliteDbProvider] insertMap has nested map at key ${entry.key}: ${entry.value}';
          getLogger('app').info(mapValueLog);
          print(mapValueLog);
        }
      }
      await db.insert(
        table,
        insertMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      final failLog =
          'DEBUG [SqliteDbProvider] insertOrReplace failed for "$table" with row: $row';
      getLogger('app').info(failLog);
      print(failLog);
      final errorLog = 'DEBUG [SqliteDbProvider] error: $e';
      getLogger('app').info(errorLog);
      print(errorLog);
      final stackLog = 'DEBUG [SqliteDbProvider] stackTrace: $stackTrace';
      getLogger('app').info(stackLog);
      print(stackLog);
      final pragma = await db.rawQuery("PRAGMA table_info('$table')");
      final hasDataCol = pragma.any((c) => (c['name'] as String?) == 'data');
      if (hasDataCol) {
        // Fallback to JSON storage only for tables that actually have a data column.
        final id =
            row['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        final data = json.encode(row);
        try {
          await db.insert(table, {
            'id': id,
            'data': data,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e2, stack2) {
          getLogger(
            'app',
          ).info('DEBUG [SqliteDbProvider] fallback insert failed: $e2');
          getLogger(
            'app',
          ).info('DEBUG [SqliteDbProvider] fallback stackTrace: $stack2');
        }
      }
    }
  }

  Future<void> deleteById(String table, String id) async {
    try {
      final db = await database;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  Future<void> clearTable(String table) async {
    try {
      final db = await database;
      await db.delete(table);
    } catch (_) {}
  }

  Future<void> dropTablesByPrefix(String prefix) async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE ?",
      ['$prefix%'],
    );
    for (final r in res) {
      final name = r['name'] as String?;
      if (name != null) await db.execute('DROP TABLE IF EXISTS "$name"');
    }
  }

  Future<int> count(String table) async {
    try {
      await ensureTable(table);
      final db = await database;
      final res = await db.rawQuery('SELECT COUNT(*) as c FROM "$table"');
      return (res.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
