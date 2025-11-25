import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'package:smart_retail/app/data/services/admin_admins_api_service.dart';
import 'package:smart_retail/app/data/services/admin_dashboard_service.dart';
import 'package:smart_retail/app/data/services/admin_merchant_service.dart';
import 'package:smart_retail/app/data/services/admin_profile_api_service.dart';
import 'package:smart_retail/app/data/services/admin_staff_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/bluetooth_printer_service.dart';
import 'package:smart_retail/app/data/services/customer_api_service.dart';
import 'package:smart_retail/app/data/services/database_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';
import 'package:smart_retail/app/data/services/notification_api_service.dart';
import 'package:smart_retail/app/data/services/notification_center_service.dart';
import 'package:smart_retail/app/data/services/payment_api_service.dart';
import 'package:smart_retail/app/data/services/pos_api_service.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/data/services/report_api_service.dart';
import 'package:smart_retail/app/data/services/sales_analysis_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/data/services/shop_dashboard_api_service.dart'; // ADDED
import 'package:smart_retail/app/data/services/shop_sales_api_service.dart';
import 'package:smart_retail/app/data/services/shop_inventory_api_service.dart';
import 'package:smart_retail/app/data/services/shop_items_api_service.dart';
import 'package:smart_retail/app/data/services/shop_profile_api_service.dart';
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/services/theme_service.dart';
import 'package:smart_retail/app/services/offline_bindings.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/global_theme_toggle_wrapper.dart';
import 'package:smart_retail/app/services/ui_keys.dart';

// For sqflite web and desktop support
import 'dart:convert';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

// Import flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Core Services
  await Get.putAsync(() => AppConfig().init());
  Get.put(GetConnect());
  // Normalize responses globally to handle web JS interop types (JSArray/JSObject)
  try {
    final _gc = Get.find<GetConnect>();
    _gc.httpClient.addResponseModifier((request, response) async {
      try {
        if (response.body != null) {
          final normalized = jsonDecode(jsonEncode(response.body));
          // Return a new Response copying existing metadata but with the normalized body
          return Response(
            request: response.request,
            body: normalized,
            statusCode: response.statusCode,
            statusText: response.statusText,
            headers: response.headers,
          );
        }
      } catch (_) {
        // ignore normalization failures; fall through to return original response
      }
      return response;
    });
  } catch (_) {}
  Get.lazyPut<DatabaseService>(() => DatabaseService());
  Get.lazyPut<ThemeService>(() => ThemeService());

  // Initialize Other Services Globally
  await Get.putAsync(() async => AuthService());
  Get.lazyPut<UserApiService>(() => UserApiService());
  Get.lazyPut<ShopApiService>(() => ShopApiService());
  Get.lazyPut<AdminDashboardApiService>(() => AdminDashboardApiService());
  Get.lazyPut<AdminMerchantService>(() => AdminMerchantService());
  Get.lazyPut<AdminAdminsApiService>(() => AdminAdminsApiService());
  Get.lazyPut<AdminStaffApiService>(() => AdminStaffApiService());
  Get.lazyPut<AdminProfileApiService>(() => AdminProfileApiService());
  Get.lazyPut<InventoryApiService>(() => InventoryApiService());
  Get.lazyPut<CustomerApiService>(() => CustomerApiService());
  Get.lazyPut<MerchantStaffApiService>(() => MerchantStaffApiService());
  Get.lazyPut<BluetoothPrinterService>(() => BluetoothPrinterService());
  Get.lazyPut<NotificationApiService>(() => NotificationApiService());
  Get.lazyPut<NotificationCenterService>(() => NotificationCenterService());
  Get.lazyPut<PaymentApiService>(() => PaymentApiService());
  Get.lazyPut<PromotionApiService>(() => PromotionApiService());
  Get.lazyPut<ReportApiService>(() => ReportApiService());
  Get.lazyPut<SalesAnalysisApiService>(() => SalesAnalysisApiService());
  Get.lazyPut<ShopDashboardApiService>(
    () => ShopDashboardApiService(),
  ); // ADDED
  Get.lazyPut<ShopSalesApiService>(() => ShopSalesApiService());
  Get.lazyPut<ShopInventoryApiService>(() => ShopInventoryApiService());
  Get.lazyPut<ShopProfileApiService>(() => ShopProfileApiService());
  Get.lazyPut<ShopItemsApiService>(() => ShopItemsApiService());
  Get.lazyPut<InvoiceApiService>(() => InvoiceApiService());
  Get.lazyPut<MerchantPosApiService>(() => MerchantPosApiService());

  // Initialize Offline-First Services
  // Guard offline initialization on web because sqflite web worker may not be present
  try {
    OfflineBindings().dependencies();
  } catch (e, st) {
    print('⚠️ Offline bindings failed to initialize: $e');
    print(st);
  }

  // Initialize SQLite for different platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Desktop platforms: Windows, Linux, macOS
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print("SQLite FFI factory initialized for desktop platform.");
  } else if (kIsWeb) {
    // Web platform
    databaseFactory = databaseFactoryFfiWeb;
    print("SQLite FFI Web factory initialized for web platform.");
  }
  // Mobile platforms (Android/iOS) use default sqflite, no initialization needed

  runApp(const MyApp());
}

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[50],
    primarySwatch: Colors.deepPurple,
    colorScheme: ColorScheme.light(
      primary: Colors.deepPurple,
      onPrimary: Colors.white,
      secondary: Colors.deepOrange,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
      background: Colors.grey[100]!,
      onBackground: Colors.black87,
      error: Colors.red,
      onError: Colors.white,
    ),
    textTheme: ThemeData.light().textTheme
        .apply(bodyColor: Colors.black87, displayColor: Colors.black87)
        .copyWith(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(color: Colors.black87),
          labelMedium: TextStyle(color: Colors.black87),
          labelSmall: TextStyle(color: Colors.black87),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 4.0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        side: BorderSide(color: Colors.deepPurple),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      hintStyle: TextStyle(color: Colors.grey[500]),
      labelStyle: TextStyle(color: Colors.black87),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurple, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Retail',
      theme: AppThemes.lightTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
