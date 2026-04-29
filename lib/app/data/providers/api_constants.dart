
class ApiConstants {
  // Preferred source: compile-time value.
  // Example: flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // String normalize(String value) {
    //   if (value.endsWith('/')) {
    //     return value.substring(0, value.length - 1);
    //   }
    //   return value;
    // }

    // if (_definedBaseUrl.trim().isNotEmpty) {
    //   return normalize(_definedBaseUrl.trim());
    // }

    // final envBaseUrl = dotenv.env['API_BASE_URL']?.trim();
    // if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
    //   return normalize(envBaseUrl);
    // }

    // Last-resort local fallback for development.
    return 'http://192.168.18.2:5000/api/v1';
  }
}
