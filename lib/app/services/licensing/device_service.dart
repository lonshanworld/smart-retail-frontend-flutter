import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class DeviceService extends GetxService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String> generateDeviceFingerprint() async {
    final rawFingerprint = await _buildRawFingerprint();
    return _sha256Hex(rawFingerprint);
  }

  Future<bool> isSuspiciousEnvironment() async {
    if (kDebugMode) {
      return true;
    }

    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return !androidInfo.isPhysicalDevice ||
            _looksLikeEmulator(androidInfo.model) ||
            _looksLikeEmulator(androidInfo.brand) ||
            _looksLikeEmulator(androidInfo.device) ||
            _looksLikeEmulator(androidInfo.product);
      case TargetPlatform.iOS:
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return !iosInfo.isPhysicalDevice;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Future<String> _buildRawFingerprint() async {
    if (kIsWeb) {
      throw UnsupportedError('Device locking is not supported on web');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _deviceInfoPlugin.androidInfo;
        return [
          'android',
          info.id,
          info.model,
          info.brand,
        ].join('|');
      case TargetPlatform.iOS:
        final info = await _deviceInfoPlugin.iosInfo;
        return [
          'ios',
          info.identifierForVendor ?? '',
          info.model,
          info.systemName,
        ].join('|');
      case TargetPlatform.macOS:
        final info = await _deviceInfoPlugin.macOsInfo;
        return [
          'macos',
          info.systemGUID ?? '',
          info.model,
          info.computerName,
        ].join('|');
      case TargetPlatform.windows:
        final info = await _deviceInfoPlugin.windowsInfo;
        return [
          'windows',
          info.computerName,
          info.userName,
          info.majorVersion.toString(),
          info.minorVersion.toString(),
          info.buildNumber.toString(),
        ].join('|');
      case TargetPlatform.linux:
        final info = await _deviceInfoPlugin.linuxInfo;
        return [
          'linux',
          info.machineId ?? '',
          info.prettyName,
          info.name,
        ].join('|');
      case TargetPlatform.fuchsia:
        return 'fuchsia|unsupported';
    }
  }

  bool _looksLikeEmulator(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    const suspiciousTokens = [
      'emulator',
      'generic',
      'sdk',
      'genymotion',
      'google_sdk',
      'x86',
      'unknown',
      'test-keys',
    ];

    return suspiciousTokens.any(normalized.contains);
  }

  String _sha256Hex(String value) {
    final digest = sha256.convert(utf8.encode(value));
    return digest.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}