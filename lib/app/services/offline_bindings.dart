import 'package:get/get.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import 'offline_mode_manager.dart';
import 'cache_manager_service.dart';
import 'offline_sales_service.dart';
import 'sync_service.dart';

class OfflineBindings extends Bindings {
  @override
  void dependencies() {
    // 1. Initialize LocalDatabaseService first (foundation)
    Get.put<LocalDatabaseService>(
      LocalDatabaseService(),
      permanent: true,
    );

    // 2. Initialize ConnectivityService (network monitoring)
    Get.put<ConnectivityService>(
      ConnectivityService(),
      permanent: true,
    );

    // 3. Initialize OfflineModeManager (feature gating)
    Get.put<OfflineModeManager>(
      OfflineModeManager(),
      permanent: true,
    );

    // 4. Initialize CacheManagerService (cache operations)
    Get.put<CacheManagerService>(
      CacheManagerService(),
      permanent: true,
    );

    // 5. Initialize OfflineSalesService (sales queueing)
    Get.put<OfflineSalesService>(
      OfflineSalesService(),
      permanent: true,
    );

    // 6. Initialize SyncService (sync orchestration)
    Get.put<SyncService>(
      SyncService(),
      permanent: true,
    );
  }
}
