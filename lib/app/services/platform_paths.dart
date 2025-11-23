// Conditional export: use IO implementation on native platforms, stub on web.
export 'platform_paths_stub.dart' if (dart.library.io) 'platform_paths_io.dart';
