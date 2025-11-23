import 'dart:convert';

/// Helpers to defensively normalize GetConnect response bodies that may
/// contain JS interop objects on web (JSArray/JSObject) or nested strings.

dynamic normalizeResponseBody(dynamic raw) {
  try {
    final encoded = jsonEncode(raw);
    final decoded = jsonDecode(encoded);
    print('[response_utils] normalizeResponseBody: rawType=${raw.runtimeType}, normalizedType=${decoded.runtimeType}');
    return decoded;
  } catch (_) {
    print('[response_utils] normalizeResponseBody: normalization failed for type=${raw.runtimeType}');
    return raw;
  }
}

Map<String, dynamic> asMap(dynamic raw) {
  final n = normalizeResponseBody(raw);
  if (n == null) {
    print('[response_utils] asMap: normalized is null');
    return <String, dynamic>{};
  }
  if (n is Map) {
    print('[response_utils] asMap: normalized map keys=${(n as Map).keys.length}');
    return Map<String, dynamic>.from(n as Map);
  }
  print('[response_utils] asMap: normalized is not Map (type=${n.runtimeType})');
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic raw) {
  final n = normalizeResponseBody(raw);
  if (n == null) {
    print('[response_utils] asList: normalized is null');
    return <dynamic>[];
  }
  if (n is List) {
    print('[response_utils] asList: normalized list length=${(n as List).length}');
    return List<dynamic>.from(n as List);
  }
  print('[response_utils] asList: normalized is not List (type=${n.runtimeType})');
  return <dynamic>[];
}
