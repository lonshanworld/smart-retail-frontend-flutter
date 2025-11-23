import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/inventory_item_model.dart';
import '../models/shop_model.dart';
import '../models/shop_stock_model.dart'; // For type hints, though we might store simpler structure in DB
import 'dart:math';

class DatabaseService extends GetxService {
  static const String _dbName = kIsWeb
      ? 'smart_retail_web.db'
      : 'smart_retail_mobile.db';
  static const int _dbVersion = 2; // Incremented version due to schema changes

  static const String _inventoryTableName = 'inventory_items';
  static const String _shopsTableName = 'shops';
  static const String _shopStockTableName = 'shop_stock';

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path;
    if (kIsWeb) {
      print("Initializing database for WEB (using sqflite_common_ffi_web).");
      path = _dbName; // sqflite_common_ffi_web handles this as IndexedDB name
    } else {
      print("Initializing database for Mobile/Desktop.");
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
    }
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreateDB,
        onUpgrade: _onUpgradeDB, // Added for schema migrations
        onOpen: (db) async {
          await db.execute(
            'PRAGMA foreign_keys = ON;',
          ); // Enable foreign key support
        },
      ),
    );
  }

  Future<void> _onCreateDB(Database db, int version) async {
    await db.execute(
      'PRAGMA foreign_keys = ON;',
    ); // Ensure FKs are on during creation too
    await _createInventoryTable(db);
    await _createShopsTable(db);
    await _createShopStockTable(db);
    print("All tables created for version $version.");
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    if (oldVersion < 2) {
      // Migrations for version 2:
      // 1. Modify inventory_items: remove quantity (data loss for that column is acceptable for this example)
      //    A more robust migration might copy data to a new table.
      //    For simplicity, we'll recreate it if it exists from an older schema without this structure.
      // 2. Create shops table
      // 3. Create shop_stock table

      // Recreate inventory table with new schema (simplest for this change)
      await db.execute('DROP TABLE IF EXISTS $_inventoryTableName;');
      await _createInventoryTable(db);
      print("Inventory table recreated for v2.");

      await _createShopsTable(db);
      await _createShopStockTable(db);
      print("Shops and ShopStock tables created for v2.");
    }
    // Add more migrations for future versions here
  }

  Future<void> _createInventoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_inventoryTableName (
        id TEXT PRIMARY KEY,
        merchantId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        sku TEXT,
        -- quantity INTEGER NOT NULL, -- REMOVED
        unitPrice REAL NOT NULL,
        costPrice REAL,
        lowStockThreshold INTEGER,
        category TEXT,
        supplier TEXT,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        needsUpdate INTEGER NOT NULL DEFAULT 0,
        needsCreate INTEGER NOT NULL DEFAULT 0
      )
    ''');
    print("Table '$_inventoryTableName' created or verified.");
  }

  Future<void> _createShopsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_shopsTableName (
        id TEXT PRIMARY KEY,
        merchantId TEXT NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
        -- Add sync flags (isSynced, needsUpdate, needsCreate) if shops are to be synced
      )
    ''');
    print("Table '$_shopsTableName' created or verified.");
  }

  Future<void> _createShopStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_shopStockTableName (
        id TEXT PRIMARY KEY, -- Can be a composite key of (shopId, inventoryItemId) in some designs
        shopId TEXT NOT NULL,
        inventoryItemId TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        lastStockedInAt TEXT NOT NULL, -- From backend, or set locally on stock-in
        createdAt TEXT NOT NULL, 
        updatedAt TEXT NOT NULL,
        -- Add sync flags if individual stock entries need fine-grained sync management
        FOREIGN KEY (shopId) REFERENCES $_shopsTableName(id) ON DELETE CASCADE,
        FOREIGN KEY (inventoryItemId) REFERENCES $_inventoryTableName(id) ON DELETE CASCADE
      )
    ''');
    print("Table '$_shopStockTableName' created or verified.");
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_shop_item ON $_shopStockTableName (shopId, inventoryItemId);',
    );
  }

  // --- Inventory Item (Master Product) CRUD Operations ---
  Future<int> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.insert(
      _inventoryTableName,
      item.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<InventoryItem?> getInventoryItemById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inventoryTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? InventoryItem.fromDbMap(maps.first) : null;
  }

  Future<List<InventoryItem>> getAllInventoryItems(String merchantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inventoryTableName,
      where: 'merchantId = ?',
      whereArgs: [merchantId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => InventoryItem.fromDbMap(maps[i]));
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      _inventoryTableName,
      item.toDbMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(String id) async {
    final db = await database;
    // Deleting an inventory item will cascade delete related shop_stock entries due to FK constraint
    return await db.delete(
      _inventoryTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<InventoryItem>> getItemsToCreate({
    required String merchantId,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inventoryTableName,
      where: 'merchantId = ? AND needsCreate = ? AND isSynced = ?',
      whereArgs: [merchantId, 1, 0],
    );
    return List.generate(maps.length, (i) => InventoryItem.fromDbMap(maps[i]));
  }

  Future<List<InventoryItem>> getItemsToUpdate({
    required String merchantId,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _inventoryTableName,
      where: 'merchantId = ? AND needsUpdate = ? AND needsCreate = ?',
      whereArgs: [merchantId, 1, 0],
    );
    return List.generate(maps.length, (i) => InventoryItem.fromDbMap(maps[i]));
  }

  Future<int> markItemAsSynced(
    String localId,
    String backendId,
    DateTime updatedAt,
  ) async {
    final db = await database;
    InventoryItem? itemToUpdate = await getInventoryItemById(localId);
    if (itemToUpdate == null) return 0;

    if (localId != backendId) {
      // Item was newly created
      await deleteInventoryItem(localId); // Delete temp local record
      InventoryItem syncedItem = itemToUpdate.copyWith(
        id: backendId,
        isSynced: true,
        needsCreate: false,
        needsUpdate: false,
        updatedAt: updatedAt,
      );
      return await insertInventoryItem(syncedItem); // Insert with backend ID
    } else {
      // Item was updated
      return await db.update(
        _inventoryTableName,
        {
          'isSynced': 1,
          'needsCreate': 0,
          'needsUpdate': 0,
          'updatedAt': updatedAt.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [backendId],
      );
    }
  }

  Future<void> clearAllInventoryForMerchant(String merchantId) async {
    final db = await database;
    // This will also delete related shop_stock entries due to ON DELETE CASCADE
    await db.delete(
      _inventoryTableName,
      where: 'merchantId = ?',
      whereArgs: [merchantId],
    );
    print(
      "All master inventory items (and their shop stock) cleared for merchant $merchantId from local DB.",
    );
  }

  // --- Shop CRUD Operations ---
  Future<int> insertShop(Shop shop) async {
    final db = await database;
    return await db.insert(
      _shopsTableName,
      shop.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Shop?> getShopById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _shopsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Shop.fromDbMap(maps.first) : null;
  }

  Future<List<Shop>> getAllShopsByMerchantId(String merchantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _shopsTableName,
      where: 'merchantId = ?',
      whereArgs: [merchantId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Shop.fromDbMap(maps[i]));
  }

  Future<int> updateShop(Shop shop) async {
    final db = await database;
    return await db.update(
      _shopsTableName,
      shop.toDbMap(),
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  Future<int> deleteShop(String id) async {
    final db = await database;
    // Deleting a shop will cascade delete related shop_stock entries
    return await db.delete(_shopsTableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllShopsForMerchant(String merchantId) async {
    final db = await database;
    // This will also delete related shop_stock entries due to ON DELETE CASCADE
    await db.delete(
      _shopsTableName,
      where: 'merchantId = ?',
      whereArgs: [merchantId],
    );
    print(
      "All shops (and their stock) cleared for merchant $merchantId from local DB.",
    );
  }

  // --- ShopStock Operations ---
  // Note: ShopStockItem from model is enriched. Local DB might store simpler version or just IDs and quantity.
  // For simplicity, toDbMap/fromDbMap for ShopStockItem are not in the model, handle here or add to model.

  Future<int> upsertShopStock({
    required String shopId,
    required String inventoryItemId,
    required int quantity,
    required DateTime
    lastStockedInAt, // Usually from server on successful stock-in/sync
    String? existingShopStockId, // if known, for update
  }) async {
    final db = await database;
    final now = DateTime.now();
    Map<String, dynamic> stockData = {
      'shopId': shopId,
      'inventoryItemId': inventoryItemId,
      'quantity': quantity,
      'lastStockedInAt': lastStockedInAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    // Check if stock entry already exists
    final List<Map<String, dynamic>> existing = await db.query(
      _shopStockTableName,
      columns: ['id', 'createdAt'],
      where: 'shopId = ? AND inventoryItemId = ?',
      whereArgs: [shopId, inventoryItemId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing stock record
      stockData['id'] = existing.first['id'] as String; // Use existing ID
      // stockData['createdAt'] = existing.first['createdAt'] as String; // Keep original createdAt
      return await db.update(
        _shopStockTableName,
        stockData,
        where: 'id = ?',
        whereArgs: [stockData['id']],
      );
    } else {
      // Insert new stock record
      stockData['id'] = Uuid().v4(); // Generate new UUID for shop_stock entry
      stockData['createdAt'] = now.toIso8601String();
      return await db.insert(
        _shopStockTableName,
        stockData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Gets a simple map representing the raw shop stock record
  Future<Map<String, dynamic>?> getRawShopStock(
    String shopId,
    String inventoryItemId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _shopStockTableName,
      where: 'shopId = ? AND inventoryItemId = ?',
      whereArgs: [shopId, inventoryItemId],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // Clears all stock for a specific shop (e.g., when shop is deleted, though cascade should handle)
  Future<void> clearStockForShop(String shopId) async {
    final db = await database;
    await db.delete(
      _shopStockTableName,
      where: 'shopId = ?',
      whereArgs: [shopId],
    );
    print("Stock cleared for shop $shopId.");
  }

  // Clears all stock for a specific inventory item across all shops (e.g. item deleted, though cascade should handle)
  Future<void> clearStockForInventoryItem(String inventoryItemId) async {
    final db = await database;
    await db.delete(
      _shopStockTableName,
      where: 'inventoryItemId = ?',
      whereArgs: [inventoryItemId],
    );
    print(
      "Stock cleared for inventory item $inventoryItemId across all shops.",
    );
  }

  Future<void> clearAllDataForMerchant(String merchantId) async {
    // Order matters if not relying solely on CASCADE or if FKs were off.
    // With ON DELETE CASCADE, deleting from `shops` and `inventory_items` should clean up `shop_stock`.
    await clearAllShopsForMerchant(
      merchantId,
    ); // This will cascade to shop_stock related to these shops
    await clearAllInventoryForMerchant(
      merchantId,
    ); // This will cascade to shop_stock related to these items
    print(
      "All data (shops, inventory, stock) cleared for merchant $merchantId from local DB.",
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
      print("Database closed.");
    }
  }

  // A simple UUID generator placeholder. Consider using the 'uuid' package.
  // Ensure you import 'dart:math' if you keep this.
  // static final _random = Random(); // Make it static if Uuid methods are static or Uuid is a singleton
}

// Basic Uuid class for generating IDs locally for new DB entries if needed.
// In a real app, use a proper UUID package e.g., 'uuid'
class Uuid {
  final _random = new Random();
  String v4() {
    // Basic pseudo-UUID - replace with a proper package like 'uuid' for production
    return '${_random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}-'
        '${_random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0')}-'
        '4${_random.nextInt(0xFFF).toRadixString(16).padLeft(3, '0')}-'
        // ignore: lines_longer_than_80_chars
        '${(_random.nextInt(0x3FFF) | 0x8000).toRadixString(16).padLeft(4, '0')}-'
        '${_random.nextInt(0xFFFFFFFFFFFF).toRadixString(16).padLeft(12, '0')}';
  }
}
