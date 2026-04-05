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
import 'package:smart_retail/app/data/services/merchant_stocks_api_service.dart';
import 'package:smart_retail/app/data/services/notification_api_service.dart';
import 'package:smart_retail/app/data/services/notification_center_service.dart';
import 'package:smart_retail/app/data/services/payment_api_service.dart';
import 'package:smart_retail/app/data/services/pos_api_service.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/data/services/public_ai_chat_service.dart';
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
import 'package:smart_retail/app/services/safe_get_connect.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/core/theme/app_theme.dart';
import 'package:smart_retail/app/services/ui_keys.dart';
import 'package:smart_retail/app/core/config/runtime_portal.dart';

// For sqflite web and desktop support
import 'dart:convert';

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Import flutter_dotenv
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await startSmartRetailApp(envFile: '.env', forcedPortal: 'public');
}

Future<void> startSmartRetailApp({
  String envFile = '.env',
  String? forcedPortal,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: envFile);
  } catch (e) {
    // Fallback to default env so portal entrypoint asset issues do not blank the app.
    debugPrint('Failed to load $envFile: $e. Falling back to .env');
    await dotenv.load(fileName: '.env');
  }

  if (forcedPortal != null && forcedPortal.trim().isNotEmpty) {
    RuntimePortal.set(forcedPortal);
  } else {
    RuntimePortal.clear();
  }

  // Initialize Core Services
  await Get.putAsync(() => AppConfig().init());
  // Register a safe GetConnect that blocks network requests when
  // the app is configured as local-storage-only.
  try {
    Get.put<GetConnect>(SafeGetConnect());
  } catch (_) {
    // Fall back to the default GetConnect if registration fails
    Get.put<GetConnect>(GetConnect());
  }
  // Normalize responses globally to handle web JS interop types (JSArray/JSObject)
  try {
    final getConnect = Get.find<GetConnect>();
    getConnect.httpClient.addResponseModifier((request, response) async {
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
      final authService = Get.put(AuthService());
      await authService.initialize();
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
  Get.lazyPut<MerchantStocksApiService>(() => MerchantStocksApiService());
  Get.lazyPut<BluetoothPrinterService>(() => BluetoothPrinterService());
  Get.lazyPut<NotificationApiService>(() => NotificationApiService());
  Get.lazyPut<NotificationCenterService>(() => NotificationCenterService());
  Get.lazyPut<PaymentApiService>(() => PaymentApiService());
  Get.lazyPut<PromotionApiService>(() => PromotionApiService());
  Get.lazyPut<PublicAiChatService>(() => PublicAiChatService());
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
    debugPrint('⚠️ Offline bindings failed to initialize: $e');
    debugPrint('$st');
  }

  // Initialize SQLite for different platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Desktop platforms: Windows, Linux, macOS
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint("SQLite FFI factory initialized for desktop platfggorm.");
  } else if (kIsWeb) {
    // Web platform
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint("SQLite FFI Web factory initialized for web platform.");
  }
  // Mobile platforms (Android/iOS) use default sqflite, no initialization needed

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart Retail',
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: (context, child) {
        return SafeArea(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
