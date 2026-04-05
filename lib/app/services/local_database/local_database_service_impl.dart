import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:smart_retail/app/services/local_database_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'local_db_helpers.dart' as helpers;
import 'sqlite_db_provider.dart';

/// Sqlite-backed concrete implementation of `LocalDatabaseService`.
class LocalDatabaseServiceImpl implements LocalDatabaseService {
  final SqliteDbProvider _provider = SqliteDbProvider();

  SqliteDbProvider get _db => _provider;

  LocalDatabaseServiceImpl() {
    _ensureSchema();
  }

  Future<void> _ensureSchema() async {
    try {
      final db = await _db.database;

      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          phone TEXT,
          assigned_shop_id TEXT,
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
          discount_amount REAL DEFAULT 0.0,
          applied_promotion_id TEXT,
          delivery_charge REAL DEFAULT 0.0,
          payment_type TEXT,
          payment_status TEXT,
          stripe_payment_intent_id TEXT,
          notes TEXT,
          created_at TEXT,
          updated_at TEXT
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
          subtotal REAL,
          created_at TEXT,
          updated_at TEXT
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shops (
          id TEXT PRIMARY KEY,
          name TEXT,
          merchant_id TEXT,
          address TEXT,
          phone TEXT,
          tax_rate REAL DEFAULT 5.0,
          is_active INTEGER DEFAULT 1,
          is_primary INTEGER DEFAULT 0,
          business_type TEXT DEFAULT 'retail',
          settings TEXT DEFAULT '{}',
          opening_hours TEXT,
          supports_delivery INTEGER DEFAULT 0,
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
          shopId TEXT,
          shop_id TEXT,
          inventoryItemId TEXT,
          inventory_item_id TEXT,
          itemId TEXT,
          item_id TEXT,
          userId TEXT,
          user_id TEXT,
          movementType TEXT,
          movement_type TEXT,
          quantityChanged INTEGER,
          quantity_changed INTEGER,
          newQuantity INTEGER,
          new_quantity INTEGER,
          quantity REAL,
          reason TEXT,
          movement_date TEXT,
          movementDate TEXT,
          clientOperationId TEXT,
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
      await _addColumnIfNotExists(
        db,
        'sales',
        'stripe_payment_intent_id',
        'TEXT',
      );
      await _addColumnIfNotExists(db, 'sales', 'notes', 'TEXT');
      await _addColumnIfNotExists(db, 'sales', 'created_at', 'TEXT');
      await _addColumnIfNotExists(db, 'sales', 'updated_at', 'TEXT');
      await _addColumnIfNotExists(db, 'shop_stock', 'shop_id', 'TEXT');
      await _addColumnIfNotExists(db, 'shop_stock', 'shop_name', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'shop_stock',
        'last_stocked_in_at',
        'TEXT',
      );
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
      await _addColumnIfNotExists(
        db,
        'staff_contracts',
        'pay_frequency',
        'TEXT',
      );
      await _addColumnIfNotExists(db, 'staff_contracts', 'start_date', 'TEXT');
      await _addColumnIfNotExists(db, 'staff_contracts', 'end_date', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'staff_contracts',
        'is_active',
        'INTEGER',
      );
      await _addColumnIfNotExists(db, 'staff_contracts', 'created_at', 'TEXT');
      await _addColumnIfNotExists(db, 'staff_contracts', 'updated_at', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'inventory_operations',
        'client_operation_id',
        'TEXT',
      );
      await _addColumnIfNotExists(
        db,
        'inventory_operations',
        'operation_type',
        'TEXT',
      );
      await _addColumnIfNotExists(
        db,
        'inventory_operations',
        'actor_id',
        'TEXT',
      );
      await _addColumnIfNotExists(
        db,
        'inventory_operations',
        'shop_id',
        'TEXT',
      );
      await _addColumnIfNotExists(
        db,
        'inventory_operations',
        'created_at',
        'TEXT',
      );
      await _addColumnIfNotExists(db, 'promotions', 'updated_at', 'TEXT');
      await _addColumnIfNotExists(
        db,
        'inventory_items',
        'is_archived',
        'INTEGER',
      );
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
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info('[LocalDatabase] Schema init failed: $e');
      }
    }
  }

  Future<void> _addColumnIfNotExists(
    dynamic db,
    String table,
    String column,
    String columnType,
  ) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info('$table')");
    final hasColumn = tableInfo.any((row) => row['name'] == column);
    if (!hasColumn) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $columnType');
      } catch (_) {}
    }
  }

  @override
  Future<dynamic> get database async => await _db.database;

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    return await _db.getAll(table);
  }

  @override
  Future<List<Map<String, dynamic>>> listAllUsers({String? role}) async {
    final rows = await _db.getAll('users');
    if (role == null) return rows;
    return rows.where((row) => row['role'] == role).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listUsersForMerchant(
    String merchantId,
  ) async {
    final rows = await _db.getAll('users');
    return rows
        .where(
          (row) =>
              row['merchantId']?.toString() == merchantId ||
              row['merchant_id']?.toString() == merchantId,
        )
        .toList();
  }

  @override
  Future<dynamic> createUserLocal(Map<String, dynamic> user) async {
    final normalized = _normalizeUserRow(user);
    if (!normalized.containsKey('id')) normalized['id'] = UniqueKey().toString();
    await _db.insertOrReplace('users', normalized);
    return normalized;
  }

  @override
  Future<void> upsertUser(Map<String, dynamic> user) async {
    final normalized = _normalizeUserRow(user);
    final id = normalized['id']?.toString();
    if (id != null && id.isNotEmpty) {
      final existing = await getUserById(id);
      if (existing != null) {
        normalized.addAll(existing);
        normalized.addAll(_normalizeUserRow(user));
      }
    }
    await _db.insertOrReplace('users', normalized);
  }

  @override
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final rows = await _db.getAll('users');
    return helpers.findById(rows, userId);
  }

  @override
  Future<Map<String, dynamic>?> findUserByEmail(
    String email, {
    String? role,
  }) async {
    final rows = await _db.getAll('users');
    try {
      return rows.firstWhere(
        (row) => row['email'] == email && (role == null || row['role'] == role),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listShopsForMerchant(
    String merchantId,
  ) async {
    final rows = await _db.getAll('shops');
    return rows
        .where(
          (shop) =>
              shop['merchantId']?.toString() == merchantId ||
              shop['merchant_id']?.toString() == merchantId,
        )
        .toList();
  }

  @override
  Future<void> upsertShop(Map<String, dynamic> shop) async {
    try {
      if (shop.containsKey('merchant_id') && !shop.containsKey('merchantId')) {
        shop['merchantId'] = shop['merchant_id'];
      }
      if (shop.containsKey('merchantId') && !shop.containsKey('merchant_id')) {
        shop['merchant_id'] = shop['merchantId'];
      }
      if (shop.containsKey('created_at') && !shop.containsKey('createdAt')) {
        shop['createdAt'] = shop['created_at'];
      }
      if (shop.containsKey('createdAt') && !shop.containsKey('created_at')) {
        shop['created_at'] = shop['createdAt'];
      }
      if (shop.containsKey('updated_at') && !shop.containsKey('updatedAt')) {
        shop['updatedAt'] = shop['updated_at'];
      }
      if (shop.containsKey('updatedAt') && !shop.containsKey('updated_at')) {
        shop['updated_at'] = shop['updatedAt'];
      }
    } catch (_) {}
    await _db.insertOrReplace('shops', shop);
  }

  @override
  Future<void> deleteShop(String shopId) async {
    await _db.deleteById('shops', shopId);
  }

  @override
  Future<Map<String, dynamic>?> getShopById(String shopId) async {
    final rows = await _db.getAll('shops');
    return helpers.findById(rows, shopId);
  }

  @override
  Future<List<Map<String, dynamic>>> listCustomersForShop(String shopId) async {
    final rows = await _db.getAll('shop_customers');
    return rows
        .where(
          (customer) =>
              customer['shopId']?.toString() == shopId ||
              customer['shop_id']?.toString() == shopId,
        )
        .toList();
  }

  @override
  Future<dynamic> createCustomerLocal(Map<String, dynamic> customer) async {
    if (!customer.containsKey('id')) customer['id'] = UniqueKey().toString();
    await _db.insertOrReplace('shop_customers', customer);
    return customer;
  }

  Map<String, dynamic> _normalizeUserRow(Map<String, dynamic> user) {
    final normalized = Map<String, dynamic>.from(user);
    final rawPasswordHash = normalized['password_hash']?.toString();
    final rawPassword = normalized['password']?.toString();

    if (rawPasswordHash != null && rawPasswordHash.isNotEmpty) {
      if (!RegExp(r'^\$2[aby]\$\d\d\$').hasMatch(rawPasswordHash)) {
        normalized['password_hash'] = BCrypt.hashpw(rawPasswordHash, BCrypt.gensalt());
      }
    } else if (rawPassword != null && rawPassword.isNotEmpty) {
      normalized['password_hash'] = BCrypt.hashpw(rawPassword, BCrypt.gensalt());
    }

    normalized.remove('password');
    if (normalized.containsKey('merchantId') && !normalized.containsKey('merchant_id')) {
      normalized['merchant_id'] = normalized['merchantId'];
    }
    if (normalized.containsKey('merchant_id') && !normalized.containsKey('merchantId')) {
      normalized['merchantId'] = normalized['merchant_id'];
    }
    if (normalized.containsKey('createdAt') && !normalized.containsKey('created_at')) {
      normalized['created_at'] = normalized['createdAt'];
    }
    if (normalized.containsKey('created_at') && !normalized.containsKey('createdAt')) {
      normalized['createdAt'] = normalized['created_at'];
    }
    if (normalized.containsKey('updatedAt') && !normalized.containsKey('updated_at')) {
      normalized['updated_at'] = normalized['updatedAt'];
    }
    if (normalized.containsKey('updated_at') && !normalized.containsKey('updatedAt')) {
      normalized['updatedAt'] = normalized['updated_at'];
    }
    return normalized;
  }

  Future<Map<String, dynamic>> _mergeExistingRow(
    String table,
    Map<String, dynamic> row,
  ) async {
    final normalized = Map<String, dynamic>.from(row);
    final id = normalized['id']?.toString();
    if (id == null || id.isEmpty) {
      return normalized;
    }

    final existing = await _db.getAll(table).then((rows) => helpers.findById(rows, id));
    if (existing != null) {
      final merged = <String, dynamic>{...existing, ...normalized};
      if (merged.containsKey('merchantId') && !merged.containsKey('merchant_id')) {
        merged['merchant_id'] = merged['merchantId'];
      }
      if (merged.containsKey('merchant_id') && !merged.containsKey('merchantId')) {
        merged['merchantId'] = merged['merchant_id'];
      }
      return merged;
    }
    return normalized;
  }

  String _safeMerchantTableName(String prefix, String merchantId) {
    final safeMerchant = merchantId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${prefix}_$safeMerchant';
  }

  @override
  Future<void> cacheProducts(
    List<Map<String, dynamic>> products,
    String merchantId,
  ) async {
    final table = _safeMerchantTableName('cached_products', merchantId);
    await _db.clearTable(table);
    for (final product in products) {
      await _db.insertOrReplace(table, product);
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedProducts(
    String merchantId,
  ) async {
    final table = _safeMerchantTableName('cached_products', merchantId);
    return await _db.getAll(table);
  }

  @override
  Future<void> cachePromotions(
    List<Map<String, dynamic>> promotions,
    String merchantId,
  ) async {
    final table = _safeMerchantTableName('cached_promotions', merchantId);
    await _db.clearTable(table);
    for (final promotion in promotions) {
      await _db.insertOrReplace(table, promotion);
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getCachedPromotions(
    String merchantId,
  ) async {
    final table = _safeMerchantTableName('cached_promotions', merchantId);
    return await _db.getAll(table);
  }

  @override
  Future<void> cacheShopInfo(
    Map<String, dynamic> shopInfo,
    String merchantId,
  ) async {
    final shopId =
        shopInfo['id']?.toString() ?? shopInfo['shop_id']?.toString();
    final merchantTable = 'cached_shop_info_$merchantId';
    await _db.clearTable(merchantTable);
    await _db.insertOrReplace(merchantTable, shopInfo);

    if (shopId != null && shopId.isNotEmpty && shopId != merchantId) {
      final shopTable = 'cached_shop_info_$shopId';
      await _db.clearTable(shopTable);
      await _db.insertOrReplace(shopTable, shopInfo);
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedShopInfo(String shopId) async {
    final directRows = await _db.getAll('cached_shop_info_$shopId');
    if (directRows.isNotEmpty) return directRows.first;

    final safeRows = await _db.getAll(
      'cached_shop_info_${shopId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}',
    );
    if (safeRows.isNotEmpty) return safeRows.first;

    return null;
  }

  @override
  Future<bool> isCacheExpired(String cacheType) async {
    return false;
  }

  @override
  Future<void> clearExpiredCache() async {}

  @override
  Future<void> clearAllCache() async {
    await _db.dropTablesByPrefix('cached_');
  }

  @override
  Future<int> calculateCacheSize() async {
    final db = await _db.database;
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE ?",
      ['cached_%'],
    );
    var size = 0;
    for (final row in res) {
      final name = row['name'] as String?;
      if (name != null) {
        size += await _db.count(name);
      }
    }
    return size;
  }

  @override
  Future<void> upsertCategory(Map<String, dynamic> category) async {
    final normalized = await _mergeExistingRow('categories', category);
    await _db.insertOrReplace('categories', normalized);
  }

  @override
  Future<void> upsertBrand(Map<String, dynamic> brand) async {
    final normalized = await _mergeExistingRow('brands', brand);
    await _db.insertOrReplace('brands', normalized);
  }

  @override
  Future<void> upsertSupplier(Map<String, dynamic> supplier) async {
    final normalized = await _mergeExistingRow('suppliers', supplier);
    await _db.insertOrReplace('suppliers', normalized);
  }

  @override
  Future<Map<String, dynamic>?> getSupplierById(String supplierId) async {
    final rows = await _db.getAll('suppliers');
    return helpers.findById(rows, supplierId);
  }

  @override
  Future<void> insertInventoryItem(Map<String, dynamic> item) async {
    final normalized = await _mergeExistingRow('inventory_items', item);
    if (!normalized.containsKey('id')) normalized['id'] = UniqueKey().toString();
    await _db.insertOrReplace('inventory_items', normalized);

    try {
      final merchantId = normalized['merchantId'] ?? normalized['merchant_id'];
      if (merchantId != null) {
        final shops = await listShopsForMerchant(merchantId.toString());
        for (final shop in shops) {
          await _db.insertOrReplace('shop_stock', {
            'id': UniqueKey().toString(),
            'inventory_item_id': normalized['id'],
            'shop_id': shop['id'],
            'shop_name': shop['name'],
            'quantity': 0,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').warning(
          '[LocalDatabase] insertInventoryItem: failed to create shop_stock rows: $e',
        );
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInventoryForShopLocal(
    String shopId,
  ) async {
    final stockRows = await _db.getAll('shop_stock');
    final inventoryRows = await _db.getAll('inventory_items');
    final shopStocks = stockRows
        .where(
          (stock) =>
              stock['shop_id']?.toString() == shopId ||
              stock['shopId']?.toString() == shopId,
        )
        .toList();

    final now = DateTime.now().toIso8601String();
    return shopStocks.map((stock) {
      final itemId =
          stock['inventory_item_id']?.toString() ??
          stock['inventoryItemId']?.toString() ??
          '';
      final inventoryItem = inventoryRows.firstWhere(
        (item) => item['id']?.toString() == itemId,
        orElse: () => <String, dynamic>{},
      );

      final merchantId =
          inventoryItem['merchant_id'] ?? inventoryItem['merchantId'] ?? '';
      final sellingPrice =
          (inventoryItem['selling_price'] as num?)?.toDouble() ??
          (inventoryItem['sellingPrice'] as num?)?.toDouble() ??
          0.0;
      final originalPrice =
          (inventoryItem['original_price'] as num?)?.toDouble() ??
          (inventoryItem['originalPrice'] as num?)?.toDouble();

      return {
        'id': itemId,
        'merchantId': merchantId,
        'merchant_id': merchantId,
        'name': inventoryItem['name'] ?? '',
        'sku': inventoryItem['sku'] ?? '',
        'sellingPrice': sellingPrice,
        'selling_price': sellingPrice,
        'originalPrice': originalPrice,
        'original_price': originalPrice,
        'lowStockThreshold':
            inventoryItem['low_stock_threshold'] ??
            inventoryItem['lowStockThreshold'],
        'category': inventoryItem['category'],
        'category_id':
            inventoryItem['category_id'] ?? inventoryItem['categoryId'],
        'subcategory_id':
            inventoryItem['subcategory_id'] ?? inventoryItem['subcategoryId'],
        'brand_id': inventoryItem['brand_id'] ?? inventoryItem['brandId'],
        'supplier_id':
            inventoryItem['supplier_id'] ?? inventoryItem['supplier'],
        'created_at':
            inventoryItem['created_at'] ?? inventoryItem['createdAt'] ?? now,
        'updated_at':
            inventoryItem['updated_at'] ?? inventoryItem['updatedAt'] ?? now,
        'quantity': (stock['quantity'] as num?)?.toInt() ?? 0,
        'stockInfo': [
          {
            'quantity': (stock['quantity'] as num?)?.toInt() ?? 0,
            'shopId': stock['shop_id'] ?? stock['shopId'] ?? '',
            'shop_name': stock['shop_name'] ?? stock['shopName'] ?? '',
          },
        ],
      };
    }).toList();
  }

  @override
  Future<void> adjustStockLocal({
    required String shopId,
    required String itemId,
    required num quantity,
    String? actorId,
    String? reason,
    String? clientOperationId,
  }) async {
    final inventoryRows = await _db.getAll('inventory_items');
    final existingItem = helpers.findById(inventoryRows, itemId);
    if (existingItem != null) {
      await _db.insertOrReplace('inventory_items', existingItem);
    }

    final stockRows = await _db.getAll('shop_stock');
    final stockRow = stockRows.firstWhere(
      (row) =>
          (row['shop_id'] ?? row['shopId'])?.toString() == shopId &&
          (row['inventory_item_id'] ??
                      row['inventoryItemId'] ??
                      row['product_id'] ??
                      row['productId'])
                  ?.toString() ==
              itemId,
      orElse: () => <String, dynamic>{},
    );

    final previousQty = (stockRow['quantity'] as num?)?.toInt() ?? 0;
    final newQty = previousQty + quantity.toInt();
    final resolvedMovementType = (() {
      switch (reason) {
        case 'stock_in':
        case 'sale':
        case 'return':
        case 'adjustment':
          return reason!;
        case 'inventory_correction':
        case 'damaged_goods':
        case 'expired_goods':
        case 'theft_loss':
        case 'correction_add':
        case 'correction_remove':
        case 'found_item':
        case 'spoilage':
        case 'damage':
        case 'theft':
        case 'other_add':
        case 'other_remove':
          return 'adjustment';
        case 'return_to_supplier':
          return 'return';
        default:
          return quantity < 0 ? 'adjustment' : 'stock_in';
      }
    })();

    final now = DateTime.now().toIso8601String();
    await _db.insertOrReplace('stock_movements', {
      'id': UniqueKey().toString(),
      'shopId': shopId,
      'shop_id': shopId,
      'itemId': itemId,
      'item_id': itemId,
      'inventoryItemId': itemId,
      'inventory_item_id': itemId,
      'movementType': resolvedMovementType,
      'movement_type': resolvedMovementType,
      'quantityChanged': quantity.toInt(),
      'quantity_changed': quantity.toInt(),
      'quantity': quantity.toDouble(),
      'newQuantity': newQty,
      'new_quantity': newQty,
      'userId': actorId ?? 'local-user',
      'user_id': actorId ?? 'local-user',
      'actorId': actorId ?? 'local-user',
      'actor_id': actorId ?? 'local-user',
      'userName': null,
      'user_name': null,
      'reason': reason ?? resolvedMovementType,
      'movementDate': now,
      'movement_date': now,
      'time': now,
      'clientOperationId': clientOperationId,
    });

    if (stockRow.isNotEmpty) {
      final updated = Map<String, dynamic>.from(stockRow);
      updated['quantity'] = newQty;
      await _db.insertOrReplace('shop_stock', updated);
    } else {
      await _db.insertOrReplace('shop_stock', {
        'id': UniqueKey().toString(),
        'inventory_item_id': itemId,
        'shop_id': shopId,
        'shop_name': '',
        'quantity': quantity.toInt(),
      });
    }
  }

  @override
  Future<bool> addStockToShopLocal({
    required String shopId,
    String? inventoryItemId,
    String? productId,
    required num quantity,
    String? actorId,
    String? clientOperationId,
  }) async {
    final id = inventoryItemId ?? productId ?? UniqueKey().toString();
    await adjustStockLocal(
      shopId: shopId,
      itemId: id,
      quantity: quantity,
      actorId: actorId,
      clientOperationId: clientOperationId,
    );
    return true;
  }

  @override
  Future<void> bulkStockInLocal({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String? actorId,
    String? clientOperationId,
  }) async {
    for (final item in items) {
      final itemId =
          item['productId'] ??
          item['product_id'] ??
          item['id'] ??
          item['inventory_item_id'];
      final qty = item['quantity'] ?? item['qty'] ?? 0;
      if (itemId == null) continue;

      final upsert = <String, dynamic>{'id': itemId};
      if (item.containsKey('merchantId'))
        upsert['merchant_id'] = item['merchantId'];
      if (item.containsKey('merchant_id'))
        upsert['merchant_id'] = item['merchant_id'];
      if (item.containsKey('name')) upsert['name'] = item['name'];
      if (item.containsKey('description'))
        upsert['description'] = item['description'];
      if (item.containsKey('sku')) upsert['sku'] = item['sku'];
      if (item.containsKey('sellingPrice'))
        upsert['selling_price'] = item['sellingPrice'];
      if (item.containsKey('selling_price'))
        upsert['selling_price'] = item['selling_price'];
      if (item.containsKey('originalPrice'))
        upsert['original_price'] = item['originalPrice'];
      if (item.containsKey('original_price'))
        upsert['original_price'] = item['original_price'];
      if (item.containsKey('lowStockThreshold'))
        upsert['low_stock_threshold'] = item['lowStockThreshold'];
      if (item.containsKey('low_stock_threshold'))
        upsert['low_stock_threshold'] = item['low_stock_threshold'];
      if (item.containsKey('category')) upsert['category'] = item['category'];
      if (item.containsKey('categoryId'))
        upsert['category_id'] = item['categoryId'];
      if (item.containsKey('category_id'))
        upsert['category_id'] = item['category_id'];
      if (item.containsKey('subcategoryId'))
        upsert['subcategory_id'] = item['subcategoryId'];
      if (item.containsKey('subcategory_id'))
        upsert['subcategory_id'] = item['subcategory_id'];
      if (item.containsKey('brandId')) upsert['brand_id'] = item['brandId'];
      if (item.containsKey('brand_id')) upsert['brand_id'] = item['brand_id'];
      if (item.containsKey('supplier'))
        upsert['supplier_id'] = item['supplier'];
      if (item.containsKey('supplier_id'))
        upsert['supplier_id'] = item['supplier_id'];

      if (upsert.length > 1) {
        await upsertInventoryItem(upsert);
      }

      await addStockToShopLocal(
        shopId: shopId,
        productId: itemId.toString(),
        quantity: qty as num,
        actorId: actorId,
        clientOperationId: clientOperationId,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMovementHistoryLocal(
    String shopId, [
    String? itemId,
    int page = 1,
    int pageSize = 50,
  ]) async {
    var all = await _db.getAll('stock_movements');
    all = all
        .map((movement) {
          final resolvedUserId =
              movement['userId'] ??
              movement['user_id'] ??
              movement['actorId'] ??
              movement['actor_id'];
          final resolvedItemId =
              movement['itemId'] ??
              movement['item_id'] ??
              movement['inventoryItemId'] ??
              movement['inventory_item_id'];
          final resolvedShopId = movement['shopId'] ?? movement['shop_id'];
          final rawMovementType =
              movement['movementType'] ??
              movement['movement_type'] ??
              movement['reason'];
          final resolvedMovementType = (() {
            switch (rawMovementType) {
              case 'inventory_correction':
              case 'damaged_goods':
              case 'expired_goods':
              case 'theft_loss':
              case 'correction_add':
              case 'correction_remove':
              case 'found_item':
              case 'spoilage':
              case 'damage':
              case 'theft':
              case 'other_add':
              case 'other_remove':
                return 'adjustment';
              case 'return_to_supplier':
                return 'return';
              default:
                return rawMovementType;
            }
          })();
          final resolvedChanged =
              movement['quantityChanged'] ??
              movement['quantity_changed'] ??
              movement['quantity'];
          final resolvedNew =
              movement['newQuantity'] ?? movement['new_quantity'];
          final resolvedDate =
              movement['movementDate'] ??
              movement['movement_date'] ??
              movement['time'];
          final resolvedName = movement['userName'] ?? movement['user_name'];

          return {
            'id': movement['id'],
            'shopId': resolvedShopId,
            'shop_id': resolvedShopId,
            'itemId': resolvedItemId,
            'item_id': resolvedItemId,
            'inventoryItemId': resolvedItemId,
            'inventory_item_id': resolvedItemId,
            'movementType': resolvedMovementType,
            'movement_type': resolvedMovementType,
            'quantityChanged': resolvedChanged,
            'quantity_changed': resolvedChanged,
            'quantity': movement['quantity'] ?? resolvedChanged,
            'newQuantity': resolvedNew,
            'new_quantity': resolvedNew,
            'userId': resolvedUserId,
            'user_id': resolvedUserId,
            'actorId': movement['actorId'],
            'actor_id': movement['actor_id'],
            'userName': resolvedName,
            'user_name': resolvedName,
            'reason': movement['reason'],
            'notes': movement['notes'],
            'movementDate': resolvedDate,
            'movement_date': resolvedDate,
            'time': resolvedDate,
            'clientOperationId':
                movement['clientOperationId'] ??
                movement['client_operation_id'],
          };
        })
        .where((movement) => movement['shopId']?.toString() == shopId)
        .toList();

    if (itemId != null) {
      all = all.where((movement) {
        final rowItemId =
            movement['itemId'] ??
            movement['item_id'] ??
            movement['inventoryItemId'] ??
            movement['inventory_item_id'];
        return rowItemId?.toString() == itemId;
      }).toList();
    }

    final start = (page - 1) * pageSize;
    if (start >= all.length) return <Map<String, dynamic>>[];
    return all.skip(start).take(pageSize).toList();
  }

  @override
  Future<void> upsertInventoryItem(Map<String, dynamic> item) async {
    if (!item.containsKey('id')) item['id'] = UniqueKey().toString();
    await _db.insertOrReplace('inventory_items', item);
  }

  @override
  Future<void> upsertPromotion(Map<String, dynamic> promotion) async {
    if (!promotion.containsKey('id')) promotion['id'] = UniqueKey().toString();

    if (promotion.containsKey('merchant_id') &&
        !promotion.containsKey('merchantId')) {
      promotion['merchantId'] = promotion['merchant_id'];
    }
    if (promotion.containsKey('merchantId') &&
        !promotion.containsKey('merchant_id')) {
      promotion['merchant_id'] = promotion['merchantId'];
    }
    if (promotion.containsKey('shop_id') && !promotion.containsKey('shopId')) {
      promotion['shopId'] = promotion['shop_id'];
    }
    if (promotion.containsKey('shopId') && !promotion.containsKey('shop_id')) {
      promotion['shop_id'] = promotion['shopId'];
    }
    if (promotion.containsKey('is_active') &&
        !promotion.containsKey('active')) {
      promotion['active'] = promotion['is_active'];
    }
    if (promotion.containsKey('active') &&
        !promotion.containsKey('is_active')) {
      promotion['is_active'] = promotion['active'];
    }
    if (promotion.containsKey('isActive') && !promotion.containsKey('active')) {
      promotion['active'] = promotion['isActive'];
    }
    if (promotion.containsKey('isActive') &&
        !promotion.containsKey('is_active')) {
      promotion['is_active'] = promotion['isActive'];
    }

    await _db.insertOrReplace('promotions', promotion);
  }

  bool _isPromotionActive(Map<String, dynamic> promotion) {
    final active =
        promotion['active'] ?? promotion['is_active'] ?? promotion['isActive'];
    return active == true || active == 1 || active == '1' || active == 'true';
  }

  @override
  Future<List<Map<String, dynamic>>> listPromotionsForMerchant(
    String merchantId, {
    bool onlyActive = true,
  }) async {
    final rows = await _db.getAll('promotions');
    final result = rows.where((promotion) {
      final rowMerchantId =
          (promotion['merchantId'] ?? promotion['merchant_id'])?.toString();
      return rowMerchantId == merchantId;
    }).toList();

    if (onlyActive) {
      return result.where(_isPromotionActive).toList();
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> listActivePromotionsForShop(
    String shopId,
  ) async {
    if (shopId.isEmpty) return <Map<String, dynamic>>[];

    final shopRow = await getShopById(shopId);
    final merchantId = (shopRow?['merchantId'] ?? shopRow?['merchant_id'])
        ?.toString();
    if (merchantId == null || merchantId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final now = DateTime.now();
    final rows = await _db.getAll('promotions');

    return rows.where((promotion) {
      final rowShopId = (promotion['shopId'] ?? promotion['shop_id'])
          ?.toString();
      final rowMerchantId =
          (promotion['merchantId'] ?? promotion['merchant_id'])?.toString();
      final startDateRaw = promotion['startDate'] ?? promotion['start_date'];
      final endDateRaw = promotion['endDate'] ?? promotion['end_date'];

      if (rowMerchantId != merchantId) return false;
      if (rowShopId != null && rowShopId.isNotEmpty && rowShopId != shopId)
        return false;
      if (!_isPromotionActive(promotion)) return false;

      if (startDateRaw != null) {
        try {
          final startDate = DateTime.parse(startDateRaw.toString());
          if (startDate.isAfter(now)) return false;
        } catch (_) {
          return false;
        }
      }

      if (endDateRaw != null) {
        try {
          final endDate = DateTime.parse(endDateRaw.toString());
          if (endDate.isBefore(now)) return false;
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listInvoicesForMerchantLocal(
    String merchantId, {
    int page = 1,
    int pageSize = 10,
    String? shopId,
  }) async {
    final rows = (await _db.getAll('invoices'))
        .where(
          (invoice) =>
              (invoice['merchantId']?.toString() == merchantId ||
                  invoice['merchant_id']?.toString() == merchantId) &&
              (shopId == null ||
                  invoice['shopId']?.toString() == shopId ||
                  invoice['shop_id']?.toString() == shopId),
        )
        .toList();

    final start = (page - 1) * pageSize;
    if (start >= rows.length) return <Map<String, dynamic>>[];
    return rows.skip(start).take(pageSize).toList();
  }

  @override
  Future<Map<String, dynamic>?> getInvoiceByIdLocal(String invoiceId) async {
    final rows = await _db.getAll('invoices');
    return helpers.findById(rows, invoiceId);
  }

  @override
  Future<Map<String, dynamic>?> getInvoiceBySaleIdLocal(String saleId) async {
    try {
      final rows = await _db.getAll('invoices');
      return rows.firstWhere(
        (invoice) =>
            invoice['saleId']?.toString() == saleId ||
            invoice['sale_id']?.toString() == saleId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createInvoiceLocal(Map<String, dynamic> invoice) async {
    if (!invoice.containsKey('id')) invoice['id'] = UniqueKey().toString();
    await _db.insertOrReplace('invoices', invoice);
  }

  @override
  Future<dynamic> createSaleLocal(Map<String, dynamic> sale) async {
    if (!sale.containsKey('id')) sale['id'] = UniqueKey().toString();
    await _db.insertOrReplace('sales', sale);
    return sale['id'];
  }

  @override
  Future<void> createSaleItemLocal(Map<String, dynamic> saleItem) async {
    if (!saleItem.containsKey('id')) saleItem['id'] = UniqueKey().toString();
    await _db.insertOrReplace('sale_items', saleItem);
  }

  @override
  Future<Map<String, dynamic>?> getSaleById(String saleId) async {
    final rows = await _db.getAll('sales');
    return helpers.findById(rows, saleId);
  }

  @override
  Future<List<Map<String, dynamic>>> getSaleItemsForSale(String saleId) async {
    final rows = await _db.getAll('sale_items');
    return rows
        .where(
          (saleItem) =>
              saleItem['sale_id']?.toString() == saleId ||
              saleItem['saleId']?.toString() == saleId,
        )
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listSalesForShop(
    String shopId, {
    int? limit,
  }) async {
    final rows = (await _db.getAll('sales'))
        .where(
          (sale) =>
              sale['shopId']?.toString() == shopId ||
              sale['shop_id']?.toString() == shopId,
        )
        .toList();

    if (limit != null && rows.length > limit) {
      return rows.sublist(0, limit);
    }
    return rows;
  }

  @override
  Future<void> queueSale(Map<String, dynamic> saleData) async {
    if (!saleData.containsKey('id')) saleData['id'] = UniqueKey().toString();
    await _db.insertOrReplace('pending_sales', saleData);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSales() async {
    return await _db.getAll('pending_sales');
  }

  @override
  Future<List<Map<String, dynamic>>> getFailedSales() async {
    return await _db.getAll('failed_sales');
  }

  @override
  Future<void> markSaleAsSynced(String saleId, dynamic serverSaleId) async {
    await _db.deleteById('pending_sales', saleId);
  }

  @override
  Future<void> markSaleFailed(String saleId, String? errorMsg) async {
    final rows = await _db.getAll('pending_sales');
    final existing = helpers.findById(rows, saleId);
    if (existing != null) {
      existing['error'] = errorMsg;
      await _db.insertOrReplace('failed_sales', existing);
      await _db.deleteById('pending_sales', saleId);
    }
  }

  @override
  Future<int> getPendingSalesCount() async {
    return await _db.count('pending_sales');
  }

  @override
  Future<void> deleteSale(String saleId) async {
    await _db.deleteById('sales', saleId);
  }

  @override
  Future<void> clearAllSales() async {
    await _db.clearTable('sales');
    await _db.clearTable('pending_sales');
    await _db.clearTable('failed_sales');
  }

  @override
  Future<void> queueOperation(Map<String, dynamic> operation) async {
    if (!operation.containsKey('id')) operation['id'] = UniqueKey().toString();
    await _db.insertOrReplace('operations', operation);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return await _db.getAll('operations');
  }

  @override
  Future<void> markOperationAsSynced(String operationId) async {
    await _db.deleteById('operations', operationId);
  }

  @override
  Future<void> markOperationFailed(String operationId, String? errorMsg) async {
    final rows = await _db.getAll('operations');
    final existing = helpers.findById(rows, operationId);
    if (existing != null) {
      existing['error'] = errorMsg;
      await _db.insertOrReplace('operations', existing);
    }
  }

  @override
  Future<int> getPendingOperationsCount() async {
    return await _db.count('operations');
  }

  @override
  Future<void> logSyncAttempt(Map<String, dynamic> log) async {
    if (!log.containsKey('id')) log['id'] = UniqueKey().toString();
    log['time'] ??= DateTime.now().toIso8601String();
    await _db.insertOrReplace('sync_logs', log);
  }

  @override
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 50}) async {
    final rows = await _db.getAll('sync_logs');
    if (rows.length <= limit) return rows;
    return rows.reversed.take(limit).toList();
  }

  @override
  Future<int> getSyncSuccessCount() async {
    final rows = await _db.getAll('sync_logs');
    return rows.where((log) => log['status'] == 'success').length;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _db.insertOrReplace('__last_sync_time__', {
      'id': 'last',
      'time': time.toIso8601String(),
    });
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final rows = await _db.getAll('__last_sync_time__');
    if (rows.isEmpty) return null;
    try {
      return DateTime.parse(rows.first['time'].toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    await _db.insertOrReplace('settings', {
      'id': key,
      'key': key,
      'value': value,
    });
  }

  @override
  Future<dynamic> getSetting(String key) async {
    final rows = await _db.getAll('settings');
    try {
      return rows.firstWhere((row) => row['key'] == key)['value'];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> closeDatabase() async {
    await _db.close();
  }
}
