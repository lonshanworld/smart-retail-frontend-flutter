import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';

/// A thin wrapper around `GetConnect` that prevents any network
/// requests when the app is running in `localStorageOnly` mode.
///
/// Register this in place of `GetConnect()` so existing code that
/// uses `Get.find<GetConnect>()` will receive this safe implementation.
class SafeGetConnect extends GetConnect {
  SafeGetConnect() : super();

  AppConfig get _appConfig {
    if (Get.isRegistered<AppConfig>()) {
      return Get.find<AppConfig>();
    }
    // If AppConfig is not available yet, be conservative and allow requests.
    // In practice AppConfig is initialized before this service is registered.
    throw Exception('AppConfig not registered');
  }

  void _guard() {
    if (_appConfig.localStorageOnly) {
      throw Exception('Network calls are disabled in local-storage-only mode');
    }
  }

  @override
  Future<Response<T>> get<T>(String? url,
      {String? contentType,
      Decoder<T>? decoder,
      Map<String, String>? headers,
      Map<String, dynamic>? query}) async {
    _guard();
    if (url == null) {
      throw ArgumentError.notNull('url');
    }
    return super.get<T>(url,
        contentType: contentType, decoder: decoder, headers: headers, query: query);
  }

  @override
  Future<Response<T>> post<T>(String? url, dynamic body,
      {String? contentType,
      Decoder<T>? decoder,
      Map<String, String>? headers,
      Map<String, dynamic>? query,
      Progress? uploadProgress}) async {
    _guard();
    if (url == null) {
      throw ArgumentError.notNull('url');
    }
    return super.post<T>(url, body,
        contentType: contentType,
        decoder: decoder,
        headers: headers,
        query: query,
        uploadProgress: uploadProgress);
  }

  @override
  Future<Response<T>> put<T>(String? url, dynamic body,
      {String? contentType,
      Decoder<T>? decoder,
      Map<String, String>? headers,
      Map<String, dynamic>? query,
      Progress? uploadProgress}) async {
    _guard();
    if (url == null) {
      throw ArgumentError.notNull('url');
    }
    return super.put<T>(url, body,
        contentType: contentType,
        decoder: decoder,
        headers: headers,
        query: query,
        uploadProgress: uploadProgress);
  }

  @override
  Future<Response<T>> delete<T>(String? url,
      {String? contentType,
      Decoder<T>? decoder,
      Map<String, String>? headers,
      Map<String, dynamic>? query}) async {
    _guard();
    if (url == null) {
      throw ArgumentError.notNull('url');
    }
    return super.delete<T>(url,
        contentType: contentType, decoder: decoder, headers: headers, query: query);
  }

  @override
  Future<Response<T>> patch<T>(String? url, dynamic body,
      {String? contentType,
      Decoder<T>? decoder,
      Map<String, String>? headers,
      Map<String, dynamic>? query,
      Progress? uploadProgress}) async {
    _guard();
    if (url == null) {
      throw ArgumentError.notNull('url');
    }
    return super.patch<T>(url, body,
        contentType: contentType,
        decoder: decoder,
        headers: headers,
        query: query,
        uploadProgress: uploadProgress);
  }
}
