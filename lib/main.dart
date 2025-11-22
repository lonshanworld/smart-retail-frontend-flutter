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
import 'package:smart_retail/app/services/theme_service.dart';
import 'package:smart_retail/app/services/offline_bindings.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/global_theme_toggle_wrapper.dart';

// For sqflite web and desktop support
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
  Get.lazyPut<ShopDashboardApiService>(() => ShopDashboardApiService()); // ADDED
  Get.lazyPut<ShopSalesApiService>(() => ShopSalesApiService());
  Get.lazyPut<ShopInventoryApiService>(() => ShopInventoryApiService());
  Get.lazyPut<ShopProfileApiService>(() => ShopProfileApiService());
  Get.lazyPut<ShopItemsApiService>(() => ShopItemsApiService());
  Get.lazyPut<MerchantPosApiService>(() => MerchantPosApiService());

  // Initialize Offline-First Services
  OfflineBindings().dependencies();

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
    primarySwatch: Colors.deepPurple,
    colorScheme: ColorScheme.light(
      primary: Colors.deepPurple,
      onPrimary: Colors.white,
      secondary: Colors.deepOrange,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      background: Colors.grey[100]!,
      onBackground: Colors.black,
      error: Colors.red,
      onError: Colors.white,
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
      backgroundColor: Colors.blueGrey[700],
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.grey[300]!,
      onSecondary: Colors.black,
      surface: Colors.grey[900]!,
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ).copyWith(
          headlineMedium: ThemeData.dark().textTheme.headlineMedium?.copyWith(color: Colors.white),
          titleMedium: ThemeData.dark().textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[700]!),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[850],
      hintStyle: TextStyle(color: Colors.grey[600]),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[900],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.tealAccent[400],
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
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: (context, child) {
        return GlobalThemeToggleWrapper(child: child);
      },
    );
  }
}
