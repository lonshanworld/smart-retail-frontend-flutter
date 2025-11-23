import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'local_database_service.dart';
import 'noop_local_database_service.dart';
import 'connectivity_service.dart';
import 'offline_mode_manager.dart';
import 'cache_manager_service.dart';
import 'offline_sales_service.dart';
import 'sync_service.dart';

class OfflineBindings extends Bindings {
  @override
  void dependencies() {
    // 1. Initialize LocalDatabaseService first (foundation)
    // On web builds we register a no-op implementation to avoid
    // initializing sqflite / web worker machinery. Offline features
    // remain available on Android, iOS and desktop only.
    if (kIsWeb) {
      // Register the noop implementation under the LocalDatabaseService
      // type so callers using Get.find<LocalDatabaseService>() continue
      // to work on web without initializing sqflite.
      Get.put<LocalDatabaseService>(NoopLocalDatabaseService(), permanent: true);
    } else {
      Get.put<LocalDatabaseService>(LocalDatabaseService(), permanent: true);
    }

    // 2. Initialize ConnectivityService (network monitoring)
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);

    // 3. Initialize OfflineModeManager (feature gating)
    Get.put<OfflineModeManager>(OfflineModeManager(), permanent: true);

    // 4. Initialize CacheManagerService (cache operations)
    // CacheManagerService uses LocalDatabaseService under the hood and will
    // work with the NoopLocalDatabaseService on web (returns empty results).
    Get.put<CacheManagerService>(CacheManagerService(), permanent: true);

    // 5. Initialize OfflineSalesService (sales queueing)
    // OfflineSalesService will operate in a no-op mode on web because the
    // underlying LocalDatabaseService is the no-op implementation.
    Get.put<OfflineSalesService>(OfflineSalesService(), permanent: true);

    // 6. Initialize SyncService (sync orchestration)
    Get.put<SyncService>(SyncService(), permanent: true);
  }
}
