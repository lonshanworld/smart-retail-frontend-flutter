import 'package:get/get.dart';
import 'package:smart_retail/app/core/config/app_config.dart';
import 'connectivity_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class OfflineModeManager extends GetxService {
  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();
  final AppConfig _appConfig = Get.find<AppConfig>();

  bool canProcessSales() => true; // Always allowed, will be queued offline
  bool canViewDashboard() => true; // Cached data available
  bool canViewProducts() => true; // Cached data available
  bool canViewPromotions() => true; // Cached data available
  bool canAddStock() => _connectivityService.isOnline.value; // Requires online
  bool canModifyInventory() =>
      _connectivityService.isOnline.value; // Requires online
  bool canModifyCustomers() =>
      _connectivityService.isOnline.value; // Requires online
  bool canAccessReports() => true; // Can view local cache
  bool canViewSalesHistory() => true; // Local history available
  bool canSync() => _connectivityService.isOnline.value && !_appConfig.localStorageOnly;

  bool get isLocalStorageOnly => _appConfig.localStorageOnly;

  bool isOnlineMode() => _connectivityService.isOnline.value && !_appConfig.localStorageOnly;
  bool isOfflineMode() => !_connectivityService.isOnline.value;

  String getFeatureStatus(String feature) {
    if (isOnlineMode()) {
      return 'Online - All features available';
    }

    if (isLocalStorageOnly) {
      return 'Local storage only - Cloud sync disabled';
    }

    switch (feature) {
      case 'add_stock':
      case 'modify_inventory':
      case 'modify_customers':
        return 'Offline - Feature disabled. Connect to internet to use this feature.';
      case 'process_sales':
      case 'view_dashboard':
      case 'view_products':
      case 'view_promotions':
      case 'view_history':
        return 'Offline - Using cached data. Sales will be synced when online.';
      default:
        return 'Offline Mode Active';
    }
  }

  String getOnlineStatus() {
    return isOnlineMode() ? 'Online ðŸŸ¢' : 'Offline âšª';
  }

  void disableFeature(String feature) {
    // Log disabled feature for analytics
    getLogger('app').info('Feature disabled (offline): $feature');
  }

  void enableFeature(String feature) {
    // Log enabled feature for analytics
    getLogger('app').info('Feature enabled (online): $feature');
  }

  // Observe connectivity changes
  Stream<bool> get onConnectivityChanged =>
      _connectivityService.onConnectivityChanged;
}

