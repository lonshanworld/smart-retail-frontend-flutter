import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/database_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/app_logger.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class MerchantStocksController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final InventoryApiService _inventoryApiService =
      Get.find<InventoryApiService>();

  final RxList<InventoryItem> inventoryItems = <InventoryItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSyncing = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchInventoryItems();
  }

  Future<void> fetchInventoryItems() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      getLogger('app').info('[MerchantStocks] Fetching inventory items...');
      final response = await _inventoryApiService.listInventoryItems();
      getLogger('app').info(
        '[MerchantStocks] Response received: ${response != null ? '${response.items.length} items' : 'null'}',
      );
      if (response != null) {
        inventoryItems.assignAll(response.items);
        getLogger(
          'app',
        ).info('[MerchantStocks] Items assigned: ${inventoryItems.length}');
      } else {
        inventoryItems.assignAll([]);
      }
    } catch (e) {
      getLogger('app').info('[MerchantStocks] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToAddItemPage() async {
    final result = await Get.toNamed(Routes.MERCHANT_INVENTORY_ADD);
    // Refresh the list if item was created
    if (result == true) {
      await fetchInventoryItems();
    }
  }

  Future<void> goToEditItemPage(InventoryItem item) async {
    final result = await Get.toNamed(
      Routes.MERCHANT_INVENTORY_EDIT,
      arguments: item,
    );
    if (result == true) {
      await fetchInventoryItems();
    }
  }

  Future<void> checkAndDeleteItemFromList(InventoryItem item) async {
    if (item.id == null || item.id!.isEmpty) return;
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final result = await _inventoryApiService.checkInventoryItemDeletable(
        item.id!,
      );
      if (result == null) {
        DialogUtils.showError('Failed to check deletion status.');
        return;
      }

      final bool deletable = result['deletable'] == true;
      final Map<String, dynamic> blockers = result['blockers'] ?? {};
      if (!deletable) {
        final entries = blockers.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
        DialogUtils.showError(
          'Cannot delete item. References found:\n$entries',
        );
        return;
      }

      final confirm = await DialogUtils.showConfirmDialog(
        title: 'Delete Item',
        message:
            'Are you sure you want to permanently delete "${item.name}"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDanger: true,
      );
      if (confirm != true) return;

      final success = await _inventoryApiService.deleteInventoryItem(item.id!);
      if (success) {
        try {
          await _dbService.deleteInventoryItem(item.id!);
        } catch (e) {
          getLogger(
            'app',
          ).info('Warning: failed to delete local DB record: $e');
        }
        inventoryItems.removeWhere((i) => i.id == item.id);
        DialogUtils.showSuccess('Item deleted');
      } else {
        DialogUtils.showError('Failed to delete item');
      }
    } catch (e) {
      DialogUtils.showError('Error: ${e.toString()}');
    } finally {
      isSyncing.value = false;
    }
  }

  void goToMoveStockPage() {
    Get.toNamed(Routes.MERCHANT_STOCK_MOVE);
  }
}
