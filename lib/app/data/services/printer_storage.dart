import 'dart:async';

import 'package:sqflite/sqflite.dart';

class PrinterSelection {
  final String transport; // 'classic' or 'ble'
  final String deviceId;
  final String deviceName;
  final String? serviceUuid;
  final String? charUuid;

  PrinterSelection({required this.transport, required this.deviceId, required this.deviceName, this.serviceUuid, this.charUuid});

  Map<String, dynamic> toMap() {
    return {
      'transport': transport,
      'device_id': deviceId,
      'device_name': deviceName,
      'service_uuid': serviceUuid,
      'char_uuid': charUuid,
    };
  }

  static PrinterSelection? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return PrinterSelection(
      transport: m['transport'] as String,
      deviceId: m['device_id'] as String,
      deviceName: m['device_name'] as String,
      serviceUuid: m['service_uuid'] as String?,
      charUuid: m['char_uuid'] as String?,
    );
  }
}

class PrinterStorage {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath/printer_selection.db';
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE selection (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transport TEXT NOT NULL,
          device_id TEXT NOT NULL,
          device_name TEXT NOT NULL,
          service_uuid TEXT,
          char_uuid TEXT
        )
      ''');
    });
    return _db!;
  }

  static Future<void> saveSelection(PrinterSelection s) async {
    final db = await _open();
    // keep only one row - replace existing
    final existing = await db.query('selection');
    if (existing.isEmpty) {
      await db.insert('selection', s.toMap());
    } else {
      await db.update('selection', s.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
    }
  }

  static Future<PrinterSelection?> loadSelection() async {
    final db = await _open();
    final rows = await db.query('selection', limit: 1);
    if (rows.isEmpty) return null;
    return PrinterSelection.fromMap(rows.first);
  }

  static Future<void> clearSelection() async {
    final db = await _open();
    await db.delete('selection');
  }
}
