/// Web/stub implementation for getting a preferred directory for storing DB files.
/// On web we do not have a real filesystem path; return empty string to signal
/// the database code to use a name-only path (handled by sqflite_web or in-memory).
Future<String> getPreferredDatabaseDirectory() async {
  return '';
}
