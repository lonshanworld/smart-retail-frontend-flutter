import 'package:flutter/foundation.dart';

class ApiConstants {
  // Replace with your actual backend server address and port
  // For local development with Android Emulator, use 10.0.2.2 for localhost on your machine.
  // For local development with iOS Simulator, Web, or Desktop, use localhost or 127.0.0.1.
  // If testing on a physical device, use your machine's local network IP address.
  static const String _androidEmulatorBaseUrl = "http://10.0.2.2:5000"; // Android Emulator only
  static const String _localHostBaseUrl = "http://localhost:5000"; // Web, Desktop, iOS Simulator
  static const String _productionBaseUrl = "https://your-production-api.com"; // Replace with your production URL

  // Determine base URL based on platform and environment
  static String get baseUrl {
    // For production builds
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    if (isProduction) {
      return "$_productionBaseUrl/api/v1";
    }

    // For development builds - determine based on platform
    if (kIsWeb) {
      // Web platform
      return "$_localHostBaseUrl/api/v1";
    }

    // For mobile/desktop platforms, check which one
    // On Android Emulator: use 10.0.2.2
    // On iOS Simulator, macOS, Windows, Linux: use localhost
    // This is a simple approach - you might want to add device detection
    return "$_androidEmulatorBaseUrl/api/v1";
    
    // Advanced: Use device IP for physical devices
    // String deviceIp = "192.168.x.x"; // Replace with your machine's IP
    // return "http://$deviceIp:5000/api/v1";
  }
}
