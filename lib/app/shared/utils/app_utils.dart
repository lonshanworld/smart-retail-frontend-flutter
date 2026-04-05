// lib/app/shared/utils/app_utils.dart
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:intl/intl.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class AppUtils {
  // --- JSON Parsing Helpers ---

  static String safeJsonString(
    Map<String, dynamic> json,
    String key, {
    String defaultValue = '',
  }) {
    try {
      return json[key]?.toString() ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonString] Error parsing key "$key": $e. Returning default: "$defaultValue"',
        );
      }
      return defaultValue;
    }
  }

  static String? safeJsonStringOrNull(Map<String, dynamic> json, String key) {
    try {
      return json[key]?.toString();
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonStringOrNull] Error parsing key "$key": $e. Returning null.',
        );
      }
      return null;
    }
  }

  static int safeJsonInt(
    Map<String, dynamic> json,
    String key, {
    int defaultValue = 0,
  }) {
    try {
      final value = json[key];
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      } else if (value is double) {
        return value.toInt();
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonInt] Error parsing key "$key": $e. Returning default: $defaultValue',
        );
      }
      return defaultValue;
    }
  }

  static double safeJsonDouble(
    Map<String, dynamic> json,
    String key, {
    double defaultValue = 0.0,
  }) {
    try {
      final value = json[key];
      if (value is double) {
        return value;
      } else if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      } else if (value is int) {
        return value.toDouble();
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonDouble] Error parsing key "$key": $e. Returning default: $defaultValue',
        );
      }
      return defaultValue;
    }
  }

  static bool safeJsonBool(
    Map<String, dynamic> json,
    String key, {
    bool defaultValue = false,
  }) {
    try {
      final value = json[key];
      if (value is bool) {
        return value;
      } else if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      } else if (value is int) {
        if (value == 1) return true;
        if (value == 0) return false;
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonBool] Error parsing key "$key": $e. Returning default: $defaultValue',
        );
      }
      return defaultValue;
    }
  }

  static DateTime safeJsonDateTime(
    Map<String, dynamic> json,
    String key, {
    DateTime? defaultValue,
  }) {
    try {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return defaultValue ??
          DateTime.now().toLocal(); // Fallback to now or a specific default
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonDateTime] Error parsing key "$key": $e. Returning default.',
        );
      }
      return defaultValue ?? DateTime.now().toLocal();
    }
  }

  static DateTime? safeJsonDateTimeOrNull(
    Map<String, dynamic> json,
    String key,
  ) {
    try {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonDateTimeOrNull] Error parsing key "$key": $e. Returning null.',
        );
      }
      return null;
    }
  }

  static List<T> safeJsonList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(dynamic) parser,
  ) {
    try {
      final list = json[key] as List?;
      return list?.map((item) => parser(item)).toList() ?? [];
    } catch (e) {
      if (kDebugMode) {
        getLogger('app').info(
          '[AppUtils.safeJsonList] Error parsing list key "$key": $e. Returning empty list.',
        );
      }
      return [];
    }
  }

  // --- Date Formatting ---
  static String toIso8601String(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  static String formatDate(DateTime? date, {String format = 'yyyy-MM-dd'}) {
    if (date == null) return 'N/A';
    return DateFormat(format).format(date);
  }

  static String formatDateTime(
    DateTime? dateTime, {
    String format = 'yyyy-MM-dd HH:mm:ss',
  }) {
    if (dateTime == null) return 'N/A';
    return DateFormat(format).format(dateTime.toLocal());
  }

  // Add other utility functions as needed
}

