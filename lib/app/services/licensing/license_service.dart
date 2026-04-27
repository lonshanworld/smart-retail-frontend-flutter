import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'package:smart_retail/app/services/licensing/crypto_service.dart';
import 'package:smart_retail/app/services/licensing/device_service.dart';
import 'package:smart_retail/app/services/licensing/license_model.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class LicenseService extends GetxService {
  static const String _licenseStorageKey = 'offline_device_license';

  LicenseService({
    FlutterSecureStorage? storage,
    DeviceService? deviceService,
    LicenseCryptoService? cryptoService,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _deviceService = deviceService ?? DeviceService(),
        _cryptoService = cryptoService ??
            LicenseCryptoService(publicKeyPem: dotenv.env['LICENSE_PUBLIC_KEY_PEM']);

  final FlutterSecureStorage _storage;
  final DeviceService _deviceService;
  final LicenseCryptoService _cryptoService;

  Future<LicenseValidationResult> validateInstalledLicense() async {
    try {
      final tamperReason = await _detectTampering();
      if (tamperReason != null) {
        return LicenseValidationResult.invalid(
          tamperReason,
          isTamperSuspected: true,
        );
      }

      final licenseJson = await _storage.read(key: _licenseStorageKey);
      if (licenseJson == null || licenseJson.trim().isEmpty) {
        return LicenseValidationResult.invalid(
          'No license found. Install a valid offline license first.',
        );
      }

      final license = LicenseModel.fromJson(
        jsonDecode(licenseJson) as Map<String, dynamic>,
      );
      final currentDeviceFingerprint = await _deviceService.generateDeviceFingerprint();

      if (!_cryptoService.verifySignature(
        payload: license.toSignedPayload(),
        signatureBase64: license.signature,
      )) {
        return LicenseValidationResult.invalid(
          'License signature is invalid.',
          license: license,
          currentDeviceFingerprint: currentDeviceFingerprint,
        );
      }

      if (license.device != currentDeviceFingerprint) {
        return LicenseValidationResult.invalid(
          'This license is not authorized for the current device.',
          license: license,
          currentDeviceFingerprint: currentDeviceFingerprint,
        );
      }

      if (_isExpired(license.expiry)) {
        return LicenseValidationResult.invalid(
          'The installed license has expired.',
          license: license,
          currentDeviceFingerprint: currentDeviceFingerprint,
        );
      }

      getLogger('license').info(
        '[LICENSE] Valid license loaded for ${license.user}',
      );
      return LicenseValidationResult.valid(
        license: license,
        currentDeviceFingerprint: currentDeviceFingerprint,
      );
    } catch (e, st) {
      getLogger('license').info('[LICENSE] Validation error: $e', e, st);
      return LicenseValidationResult.invalid(
        'License validation failed: $e',
      );
    }
  }

  Future<void> saveLicense(LicenseModel license) async {
    await _storage.write(key: _licenseStorageKey, value: license.toJsonString());
  }

  Future<void> saveLicenseJson(String licenseJson) async {
    await _storage.write(key: _licenseStorageKey, value: licenseJson);
  }

  Future<LicenseModel?> loadLicense() async {
    final rawLicense = await _storage.read(key: _licenseStorageKey);
    if (rawLicense == null || rawLicense.trim().isEmpty) {
      return null;
    }

    return LicenseModel.fromJson(
      jsonDecode(rawLicense) as Map<String, dynamic>,
    );
  }

  Future<void> clearLicense() async {
    await _storage.delete(key: _licenseStorageKey);
  }

  Future<String?> readRawLicense() {
    return _storage.read(key: _licenseStorageKey);
  }

  Future<String> getDeviceFingerprint() {
    return _deviceService.generateDeviceFingerprint();
  }

  Future<String?> _detectTampering() async {
    final suspicious = await _deviceService.isSuspiciousEnvironment();
    if (suspicious) {
      return 'Debug mode, emulator, or unsupported environment detected.';
    }
    return null;
  }

  bool _isExpired(DateTime expiry) {
    final today = DateTime.now().toLocal();
    final currentDate = DateTime(today.year, today.month, today.day);
    final expiryDate = DateTime(expiry.toLocal().year, expiry.toLocal().month, expiry.toLocal().day);
    return currentDate.isAfter(expiryDate);
  }
}