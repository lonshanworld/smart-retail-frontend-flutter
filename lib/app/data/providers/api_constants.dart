class ApiConstants {
  // Replace with your actual backend server address and port
  // For local development with Android Emulator, use 10.0.2.2 for localhost on your machine.
  // For local development with iOS Simulator or web, use localhost or 127.0.0.1.
  // If testing on a physical device, use your machine's local network IP address.
  static const String _localDevBaseUrl = "http://10.0.2.2:5000"; // Updated to port 3000 for Android Emulator
  // static const String _localWebDevBaseUrl = "http://localhost:3000"; // Example for Web testing (updated port)
  static const String _productionBaseUrl = "https://your-production-api.com"; // Replace with your production URL

  // Determine base URL based on environment (you can make this more sophisticated)
  static String get baseUrl {
    return "$_localDevBaseUrl/api/v1";
    // In a real app, you might use flutter_dotenv or similar to manage environments
    // bool isProduction = const bool.fromEnvironment('dart.vm.product');
    // if (isProduction) {
    //   return "$_productionBaseUrl/api/v1";
    // } else {
    //   // // For web debugging, you might want to switch to localhost
    //   // // Note: kIsWeb requires: import 'package:flutter/foundation.dart';
    //   // if (kIsWeb) {
    //   //  return "$_localWebDevBaseUrl/api/v1"; // Ensure _localWebDevBaseUrl is appropriate if uncommented
    //   // }
    //   return "$_localDevBaseUrl/api/v1";
    // }
  }
}
