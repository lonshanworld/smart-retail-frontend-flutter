import 'dart:convert';
import 'package:smart_retail/app/utils/app_logger.dart';

/// Helpers to defensively normalize GetConnect response bodies that may
/// contain JS interop objects on web (JSArray/JSObject) or nested strings.

dynamic normalizeResponseBody(dynamic raw) {
  try {
    final encoded = jsonEncode(raw);
    final decoded = jsonDecode(encoded);
    getLogger('app').info(
      '[response_utils] normalizeResponseBody: rawType=${raw.runtimeType}, normalizedType=${decoded.runtimeType}',
    );
    return decoded;
  } catch (_) {
    getLogger('app').info(
      '[response_utils] normalizeResponseBody: normalization failed for type=${raw.runtimeType}',
    );
    return raw;
  }
}

Map<String, dynamic> asMap(dynamic raw) {
  final n = normalizeResponseBody(raw);
  if (n == null) {
    getLogger('app').info('[response_utils] asMap: normalized is null');
    return <String, dynamic>{};
  }
  if (n is Map) {
    getLogger('app').info('[response_utils] asMap: normalized map keys=${n.keys.length}');
    return Map<String, dynamic>.from(n);
  }
  getLogger('app').info(
    '[response_utils] asMap: normalized is not Map (type=${n.runtimeType})',
  );
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic raw) {
  final n = normalizeResponseBody(raw);
  if (n == null) {
    getLogger('app').info('[response_utils] asList: normalized is null');
    return <dynamic>[];
  }
  // If already a list, return it
  if (n is List) {
    getLogger('app').info('[response_utils] asList: normalized list length=${n.length}');
    return List<dynamic>.from(n);
  }

  // If it's a Map wrapper, try common keys that hold lists
  if (n is Map) {
    const candidateKeys = ['data', 'items', 'results', 'rows', 'payload'];
    for (final k in candidateKeys) {
      if (n.containsKey(k) && n[k] is List) {
        final list = List<dynamic>.from(n[k]);
        getLogger('app').info(
          '[response_utils] asList: extracted list from Map key="$k", length=${list.length}',
        );
        return list;
      }
    }
  }

  getLogger('app').info(
    '[response_utils] asList: normalized is not List (type=${n.runtimeType})',
  );
  return <dynamic>[];
}

