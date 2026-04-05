import 'dart:developer' as developer;
import 'package:logging/logging.dart';

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}

final bool _initialized = (() {
  _setupLogging();
  return true;
})();

Logger getLogger(String name) {
  // ensure initialization
  assert(_initialized == true);
  return Logger(name);
}
