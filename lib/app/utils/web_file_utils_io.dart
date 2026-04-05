import 'dart:typed_data';

Future<void> downloadFile(Uint8List bytes, String filename) async {
  // Not supported on non-web platforms. Consumer should guard with kIsWeb.
  throw UnsupportedError('downloadFile is only supported on web');
}
