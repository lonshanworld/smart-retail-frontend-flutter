// Simple in-memory DB provider used as a small, well-factored concrete
// implementation for LocalDatabaseService. This keeps the implementation
// modular and easy to replace with a full sqlite-backed provider later.
class LocalDbProvider {
  // Storage is a map of table name -> list of row maps
  final Map<String, List<Map<String, dynamic>>> _storage = {};

  Future<Map<String, List<Map<String, dynamic>>>> get database async {
    return _storage;
  }

  /// Expose a read-only view of the storage for callers that need to
  /// iterate or inspect entries. This avoids accessing a private field
  /// from other library files.
  Map<String, List<Map<String, dynamic>>> get storage => _storage;

  // Helpers to access named tables
  List<Map<String, dynamic>> table(String name) {
    return _storage.putIfAbsent(name, () => <Map<String, dynamic>>[]);
  }

  void clear() {
    _storage.clear();
  }
}
