import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// IO implementation for getting a preferred directory for storing DB files.
Future<String> getPreferredDatabaseDirectory() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  } catch (e) {
    // Fallback to system temp directory if application documents isn't available
    return Directory.systemTemp.path;
  }
}
