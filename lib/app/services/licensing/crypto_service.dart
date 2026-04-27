import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' show RSAKeyParser;
import 'package:pointycastle/export.dart';

class LicenseCryptoService {
  LicenseCryptoService({String? publicKeyPem})
  : publicKeyPem = publicKeyPem ?? _defaultPublicKeyPem;

  final String publicKeyPem;

  static const String _defaultPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw8bJ4E2s0j5uQ1z5x2dT
J9Cw1cZ9g1J3uU1HnK6l9eQk3D2wIuB7iXn1uW8W3r2K9h0D2sQ1sQ1sQ1sQ1sQ1
q3YQ3G9xw8Y2vB9lV4sG6mJm3KQ2gkq8vQ4q9Q8jYJgk0jQm4pR3v4c8yV9bK2mJ
JmQwIDAQAB
-----END PUBLIC KEY-----
''';

  static RSAPublicKey _parsePublicKey(String pem) {
    final parsed = RSAKeyParser().parse(pem);
    if (parsed is! RSAPublicKey) {
      throw FormatException('Expected RSA public key');
    }
    return parsed;
  }

  bool verifySignature({
    required String payload,
    required String signatureBase64,
  }) {
    try {
      final publicKey = _parsePublicKey(publicKeyPem);
      final signer = Signer('SHA-256/RSA');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final signatureBytes = base64Decode(signatureBase64);
      final messageBytes = Uint8List.fromList(utf8.encode(payload));
      return signer.verifySignature(messageBytes, RSASignature(signatureBytes));
    } catch (_) {
      return false;
    }
  }
}