import 'dart:convert';

class LicenseModel {
  final String user;
  final String device;
  final DateTime expiry;
  final String signature;

  const LicenseModel({
    required this.user,
    required this.device,
    required this.expiry,
    required this.signature,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    final expiryValue = json['expiry']?.toString();
    if (expiryValue == null || expiryValue.isEmpty) {
      throw FormatException('License expiry is missing');
    }

    return LicenseModel(
      user: json['user']?.toString() ?? '',
      device: json['device']?.toString() ?? '',
      expiry: DateTime.parse(expiryValue),
      signature: json['signature']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'device': device,
      'expiry': _formatDate(expiry),
      'signature': signature,
    };
  }

  Map<String, dynamic> toSignedPayloadJson() {
    return {
      'user': user,
      'device': device,
      'expiry': _formatDate(expiry),
    };
  }

  String toSignedPayload() => jsonEncode(toSignedPayloadJson());

  String toJsonString() => jsonEncode(toJson());

  String _formatDate(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class LicenseValidationResult {
  final bool isValid;
  final bool isTamperSuspected;
  final String message;
  final LicenseModel? license;
  final String? currentDeviceFingerprint;

  const LicenseValidationResult._({
    required this.isValid,
    required this.isTamperSuspected,
    required this.message,
    required this.license,
    required this.currentDeviceFingerprint,
  });

  factory LicenseValidationResult.valid({
    required LicenseModel license,
    required String currentDeviceFingerprint,
  }) {
    return LicenseValidationResult._(
      isValid: true,
      isTamperSuspected: false,
      message: 'License is valid',
      license: license,
      currentDeviceFingerprint: currentDeviceFingerprint,
    );
  }

  factory LicenseValidationResult.invalid(
    String message, {
    LicenseModel? license,
    String? currentDeviceFingerprint,
    bool isTamperSuspected = false,
  }) {
    return LicenseValidationResult._(
      isValid: false,
      isTamperSuspected: isTamperSuspected,
      message: message,
      license: license,
      currentDeviceFingerprint: currentDeviceFingerprint,
    );
  }
}