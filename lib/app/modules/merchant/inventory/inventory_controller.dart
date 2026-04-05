import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/database_service.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;
import 'package:smart_retail/app/utils/app_logger.dart';

class InventoryController extends GetxController {
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final InventoryApiService _apiService = Get.find<InventoryApiService>();
  final AuthService _authService = Get.find<AuthService>();

  var inventoryItems = <InventoryItem>[].obs;
  var isLoading = false.obs;
  var isFetchingPage = false.obs;
  var isSyncing = false.obs;
  var errorMessage = RxnString();
  var currentPage = 1.obs;
  var totalPagesFromApi = 1.obs;
  final int _pageSize = 15;
  var uuid = uuid_pkg.Uuid();

  // --- Form TextEditingControllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController originalPriceController = TextEditingController();
  final TextEditingController lowStockThresholdController =
      TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController supplierNameController = TextEditingController();

  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;
  final RxnString selectedCategoryFilterId = RxnString();
  final RxnString selectedSubcategoryFilterId = RxnString();
  final RxnString selectedBrandFilterId = RxnString();

  List<SubcategoryRef> get filteredSubcategoriesForFilter {
    final categoryId = selectedCategoryFilterId.value;
    if (categoryId == null) return const [];
    return categories
            .firstWhereOrNull((c) => c.id == categoryId)
            ?.subcategories ??
        const [];
  }

  List<InventoryItem> get visibleInventoryItems {
    return inventoryItems.where((item) {
      final categoryMatch =
          selectedCategoryFilterId.value == null ||
          item.categoryId == selectedCategoryFilterId.value;
      final subcategoryMatch =
          selectedSubcategoryFilterId.value == null ||
          item.subcategoryId == selectedSubcategoryFilterId.value;
      final brandMatch =
          selectedBrandFilterId.value == null ||
          item.brandId == selectedBrandFilterId.value;
      return categoryMatch && subcategoryMatch && brandMatch;
    }).toList();
  }

  // Stores the ID of the item being edited, if any
  String? _editingItemId;

  @override
  void onInit() {
    super.onInit();
    _authService.userRole.listen((role) {
      if (role == 'merchant' && _authService.isAuthenticated) {
        getLogger('app').info(
          "Merchant role detected and authenticated, initializing inventory.",
        );
        initializeInventory();
      } else if (role != 'merchant') {
        inventoryItems.clear();
        currentPage.value = 1;
        totalPagesFromApi.value = 1;
        clearFormFields(); // Clear form if user changes
        getLogger('app').info("Not a merchant, or not authenticated. Inventory cleared.");
      }
    });
    if (_authService.isAuthenticated &&
        _authService.userRole.value == 'merchant') {
      getLogger('app').info("Already authenticated as merchant, initializing inventory.");
      initializeInventory();
    }

    _loadCatalogOptions();
  }

  Future<void> _loadCatalogOptions() async {
    final catalog = await _apiService.getCatalogOptions();
    if (catalog == null) return;
    categories.assignAll(catalog.categories);
    brands.assignAll(catalog.brands);
  }

  void setCategoryFilter(String? categoryId) {
    selectedCategoryFilterId.value = categoryId;
    selectedSubcategoryFilterId.value = null;
  }

  void setSubcategoryFilter(String? subcategoryId) {
    selectedSubcategoryFilterId.value = subcategoryId;
  }

  void setBrandFilter(String? brandId) {
    selectedBrandFilterId.value = brandId;
  }

  // --- Method to populate form fields for editing ---
  void loadItemForEditing(InventoryItem item) {
    _editingItemId = item.id;
    nameController.text = item.name;
    descriptionController.text = item.description ?? '';
    skuController.text = item.sku ?? '';
    sellingPriceController.text = item.sellingPrice.toString();
    originalPriceController.text = item.originalPrice?.toString() ?? '';
    lowStockThresholdController.text = item.lowStockThreshold?.toString() ?? '';
    categoryController.text = item.category ?? '';
    supplierNameController.text = item.supplier ?? '';
  }

  // --- Method to clear all form fields ---
  void clearFormFields() {
    _editingItemId = null;
    nameController.clear();
    descriptionController.clear();
    skuController.clear();
    sellingPriceController.clear();
    originalPriceController.clear();
    lowStockThresholdController.clear();
    categoryController.clear();
    supplierNameController.clear();
  }

  Future<void> initializeInventory() async {
    isLoading.value = true;
    errorMessage.value = null;
    currentPage.value = 1;
    String? currentUserId = await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      errorMessage.value = "Merchant not identified. Cannot load inventory.";
      isLoading.value = false;
      return;
    }
    getLogger('app').info(
      "Initializing inventory: Fetching page 1 from API for User ID (Merchant): $currentUserId",
    );
    await _fetchFromApiAndCache(
      currentUserId,
      loadNextPage: false,
      clearLocalPageData: false,
    );
    _backgroundSyncAndFetchLatest(currentUserId);
    isLoading.value = false;
  }

  Future<void> _backgroundSyncAndFetchLatest(String currentUserId) async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      await syncPendingChanges();
    } catch (e) {
      getLogger('app').info("Error during background sync/fetch: $e");
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> performFullSyncWithBackend({
    String? merchantIdParam,
    bool isInitialLoad = false,
  }) async {
    if (!isInitialLoad) isLoading.value = true;
    isSyncing.value = true;
    errorMessage.value = null;
    String? currentUserId = merchantIdParam ?? await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      errorMessage.value = "Merchant not identified. Cannot perform full sync.";
      if (!isInitialLoad) isLoading.value = false;
      isSyncing.value = false;
      return;
    }

    try {
      getLogger('app').info("Performing full sync for User ID (Merchant): $currentUserId");
      await _dbService.clearAllInventoryForMerchant(currentUserId);
      inventoryItems.clear();
      currentPage.value = 1;
      totalPagesFromApi.value = 1;

      await _fetchFromApiAndCache(
        currentUserId,
        loadNextPage: false,
        clearLocalPageData: true,
      );

      DialogUtils.showSuccess(
        "Inventory has been synchronized with the server. Displaying first page.",
      );
      getLogger('app').info("Full sync complete. First page items loaded and synced.");
    } catch (e) {
      getLogger('app').info("Error during full sync: $e");
      errorMessage.value = "Full sync failed: $e";
      DialogUtils.showError("Could not fully synchronize inventory.");
    } finally {
      if (!isInitialLoad) isLoading.value = false;
      isSyncing.value = false;
    }
  }

  Future<void> goToNextPage() async {
    if (currentPage.value < totalPagesFromApi.value) {
      currentPage.value++;
      await _fetchPageData();
    }
  }

  Future<void> goToPreviousPage() async {
    if (currentPage.value > 1) {
      currentPage.value--;
      await _fetchPageData();
    }
  }

  Future<void> jumpToPage(int pageNumber) async {
    if (pageNumber >= 1 &&
        pageNumber <= totalPagesFromApi.value &&
        pageNumber != currentPage.value) {
      currentPage.value = pageNumber;
      await _fetchPageData();
    }
  }

  Future<void> _fetchPageData() async {
    isFetchingPage.value = true;
    errorMessage.value = null;
    String? currentUserId = await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      errorMessage.value = "Merchant ID not found for fetching page data.";
      isFetchingPage.value = false;
      return;
    }
    await _fetchFromApiAndCache(currentUserId, loadNextPage: false);
    isFetchingPage.value = false;
  }

  Future<void> _fetchFromApiAndCache(
    String currentUserId, {
    required bool loadNextPage,
    bool clearLocalPageData = false,
  }) async {
    if (!loadNextPage) {
      isFetchingPage.value = true;
    }

    if (clearLocalPageData) {
      await _dbService.clearAllInventoryForMerchant(currentUserId);
      inventoryItems.clear();
    }

    PaginatedInventoryResponse? apiResponse = await _apiService
        .listInventoryItems(page: currentPage.value, pageSize: _pageSize);

    if (apiResponse != null) {
      List<InventoryItem> fetchedItems = [];
      for (var item in apiResponse.items) {
        final syncedItem = item.copyWith(
          merchantId: currentUserId,
          isSynced: true,
          needsCreate: false,
          needsUpdate: false,
        );
        await _dbService.insertInventoryItem(syncedItem);
        fetchedItems.add(syncedItem);
      }

      inventoryItems.assignAll(fetchedItems);

      totalPagesFromApi.value = apiResponse.totalPages;
      currentPage.value = apiResponse.currentPage;
      getLogger('app').info(
        "Fetched and cached page ${currentPage.value} from API. Total API pages: ${totalPagesFromApi.value}",
      );
    } else {
      errorMessage.value =
          "Failed to load inventory page ${currentPage.value} from server.";
    }
    if (!loadNextPage) {
      isFetchingPage.value = false;
    }
  }

  Future<void> addInventoryItem() async {
    String? currentUserId = await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      DialogUtils.showError("Merchant ID not found.");
      return;
    }

    if (nameController.text.isEmpty) {
      DialogUtils.showError("Item name cannot be empty.");
      return;
    }
    if (sellingPriceController.text.isEmpty ||
        double.tryParse(sellingPriceController.text) == null) {
      DialogUtils.showError("Valid selling price is required.");
      return;
    }

    final localId = uuid.v4();
    final newItem = InventoryItem(
      id: localId,
      merchantId: currentUserId,
      name: nameController.text,
      description: descriptionController.text.isNotEmpty
          ? descriptionController.text
          : null,
      sku: skuController.text.isNotEmpty ? skuController.text : null,
      sellingPrice: double.parse(sellingPriceController.text),
      originalPrice: double.parse(originalPriceController.text),
      lowStockThreshold: lowStockThresholdController.text.isNotEmpty
          ? int.tryParse(lowStockThresholdController.text)
          : null,
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : null,
      supplier: supplierNameController.text.isNotEmpty
          ? supplierNameController.text
          : null,
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      needsCreate: true,
      needsUpdate: false,
    );

    await _dbService.insertInventoryItem(newItem);
    inventoryItems.insert(0, newItem);
    DialogUtils.showSuccess("'${newItem.name}' added. Sync to upload.");
    getLogger('app').info("Item added to local DB: ${newItem.name}");

    clearFormFields();

    try {
      isSyncing.value = true;
      InventoryItem? createdItem = await _apiService.createInventoryItem(
        newItem,
      );
      if (createdItem != null) {
        await _dbService.markItemAsSynced(
          localId,
          createdItem.id!,
          createdItem.updatedAt,
        );
        int index = inventoryItems.indexWhere((i) => i.id == localId);
        if (index != -1) {
          inventoryItems[index] = createdItem.copyWith(
            isSynced: true,
            needsCreate: false,
            needsUpdate: false,
          );
        }
        DialogUtils.showSuccess(
          "Item '${createdItem.name}' created and synced.",
        );
        await _fetchPageData();
      } else {
        DialogUtils.showWarning(
          "Item '${newItem.name}' saved locally. Will sync later.",
        );
      }
    } catch (e) {
      getLogger('app').info("Error syncing new item: $e");
      DialogUtils.showError(
        "Item '${newItem.name}' saved locally. Sync failed. Will retry.",
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> updateInventoryItem() async {
    String? role = await _authService.getUserRole();
    if (role != 'merchant') {
      DialogUtils.showError("Operation not allowed for current user role.");
      return;
    }

    if (_editingItemId == null) {
      DialogUtils.showError("No item selected for update.");
      return;
    }

    if (nameController.text.isEmpty) {
      DialogUtils.showError("Item name cannot be empty.");
      return;
    }
    if (sellingPriceController.text.isEmpty ||
        double.tryParse(sellingPriceController.text) == null) {
      DialogUtils.showError("Valid selling price is required.");
      return;
    }

    int itemIndex = inventoryItems.indexWhere(
      (item) => item.id == _editingItemId,
    );
    InventoryItem? originalItem = await _dbService.getInventoryItemById(
      _editingItemId!,
    );
    if (originalItem == null) {
      DialogUtils.showError("Item not found in local DB for update.");
      return;
    }

    InventoryItem itemWithChanges = originalItem.copyWith(
      name: nameController.text,
      description: descriptionController.text.isNotEmpty
          ? descriptionController.text
          : null,
      sku: skuController.text.isNotEmpty ? skuController.text : null,
      sellingPrice: double.parse(sellingPriceController.text),
      originalPrice: originalPriceController.text.isNotEmpty
          ? double.tryParse(originalPriceController.text)
          : null,
      lowStockThreshold: lowStockThresholdController.text.isNotEmpty
          ? int.tryParse(lowStockThresholdController.text)
          : null,
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : null,
      supplier: supplierNameController.text.isNotEmpty
          ? supplierNameController.text
          : null,
      updatedAt: DateTime.now(),
      needsUpdate: true,
      isSynced: false,
      needsCreate: originalItem.needsCreate,
    );

    Map<String, dynamic> changesForApi = {};
    if (itemWithChanges.name != originalItem.name) {
      changesForApi['name'] = itemWithChanges.name;
    }
    if (itemWithChanges.description != originalItem.description) {
      changesForApi['description'] = itemWithChanges.description;
    }
    if (itemWithChanges.sku != originalItem.sku) {
      changesForApi['sku'] = itemWithChanges.sku;
    }
    if (itemWithChanges.sellingPrice != originalItem.sellingPrice) {
      changesForApi['sellingPrice'] = itemWithChanges.sellingPrice;
    }
    if (itemWithChanges.originalPrice != originalItem.originalPrice) {
      changesForApi['originalPrice'] = itemWithChanges.originalPrice;
    }
    if (itemWithChanges.lowStockThreshold != originalItem.lowStockThreshold) {
      changesForApi['lowStockThreshold'] = itemWithChanges.lowStockThreshold;
    }
    if (itemWithChanges.category != originalItem.category) {
      changesForApi['category'] = itemWithChanges.category;
    }
    if (itemWithChanges.supplier != originalItem.supplier) {
      changesForApi['supplier'] = itemWithChanges.supplier;
    }

    if (changesForApi.isEmpty) {
      DialogUtils.showInfo("No changes detected to update.");
      return;
    }

    await _dbService.updateInventoryItem(itemWithChanges);
    if (itemIndex != -1) {
      inventoryItems[itemIndex] = itemWithChanges;
    } else {
      getLogger('app').info(
        "Item updated in DB but not in current view: ${itemWithChanges.name}",
      );
    }
    DialogUtils.showSuccess(
      "'${itemWithChanges.name}' updated. Sync to save changes to cloud.",
    );

    clearFormFields();

    try {
      isSyncing.value = true;
      if (!itemWithChanges.needsCreate &&
          itemWithChanges.id != null &&
          itemWithChanges.id!.isNotEmpty) {
        InventoryItem? syncedItem = await _apiService.updateInventoryItem(
          itemWithChanges.id!,
          changesForApi,
        );
        if (syncedItem != null) {
          final finalItem = syncedItem.copyWith(
            isSynced: true,
            needsUpdate: false,
            needsCreate: false,
          );
          await _dbService.updateInventoryItem(finalItem);
          if (itemIndex != -1) inventoryItems[itemIndex] = finalItem;
          DialogUtils.showSuccess(
            "Item '${finalItem.name}' updated and synced.",
          );
          await _fetchPageData();
        } else {
          DialogUtils.showWarning(
            "Item '${itemWithChanges.name}' updated locally. Will sync later.",
          );
        }
      } else if (itemWithChanges.needsCreate) {
        DialogUtils.showWarning(
          "Item '${itemWithChanges.name}' updated locally (pending creation). Will sync later.",
        );
      } else {
        DialogUtils.showError(
          "Cannot sync update for item '${itemWithChanges.name}' due to missing ID or trying to update an item that needs creation first.",
        );
      }
    } catch (e) {
      getLogger('app').info("Error syncing updated item: $e");
      DialogUtils.showError(
        "Item '${itemWithChanges.name}' updated locally. Sync failed. Will retry.",
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _toggleArchiveStatus(String itemId, bool archive) async {
    String? role = await _authService.getUserRole();
    if (role != 'merchant') {
      DialogUtils.showError("Operation not allowed for current user role.");
      return;
    }

    int itemIndex = inventoryItems.indexWhere((item) => item.id == itemId);
    InventoryItem? item = await _dbService.getInventoryItemById(itemId);
    if (item == null) {
      DialogUtils.showError("Item not found.");
      return;
    }

    InventoryItem changedItem = item.copyWith(
      isArchived: archive,
      updatedAt: DateTime.now(),
      needsUpdate: true,
      isSynced: false,
      needsCreate: item.needsCreate,
    );

    await _dbService.updateInventoryItem(changedItem);
    if (itemIndex != -1) inventoryItems[itemIndex] = changedItem;
    DialogUtils.showSuccess(
      "'${changedItem.name}' ${archive ? 'archived' : 'unarchived'}. Sync to update cloud.",
    );

    try {
      isSyncing.value = true;
      if (!changedItem.needsCreate &&
          changedItem.id != null &&
          changedItem.id!.isNotEmpty) {
        bool success =
            (archive
                    ? await _apiService.archiveInventoryItem(changedItem.id!)
                    : await _apiService.unarchiveInventoryItem(changedItem.id!))
                as bool;

        if (success) {
          final finalItem = changedItem.copyWith(
            isSynced: true,
            needsUpdate: false,
            isArchived: archive,
          );
          await _dbService.updateInventoryItem(finalItem);
          if (itemIndex != -1) inventoryItems[itemIndex] = finalItem;
          DialogUtils.showSuccess(
            "Item ${archive ? 'archived' : 'unarchived'} and synced.",
          );
          await _fetchPageData();
        } else {
          DialogUtils.showWarning(
            "Item status changed locally. Will sync later.",
          );
        }
      } else if (changedItem.needsCreate) {
        DialogUtils.showWarning(
          "Item status changed locally (pending creation). Will sync later.",
        );
      } else {
        DialogUtils.showError(
          "Cannot sync archive status for item '${changedItem.name}' due to missing ID or trying to update an item that needs creation first.",
        );
      }
    } catch (e) {
      getLogger('app').info("Error syncing archive status: $e");
      DialogUtils.showError(
        "Item status changed locally. Sync failed. Will retry.",
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> archiveInventoryItem(String itemId) =>
      _toggleArchiveStatus(itemId, true);
  Future<void> unarchiveInventoryItem(String itemId) =>
      _toggleArchiveStatus(itemId, false);

  /// Check whether the given item can be deleted and delete it if confirmed.
  Future<void> checkAndDeleteItemFromList(InventoryItem item) async {
    if (item.id == null || item.id!.isEmpty) return;
    if (isSyncing.value) return;
    isSyncing.value = true;
    try {
      final result = await _apiService.checkInventoryItemDeletable(item.id!);
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

      final success = await _apiService.deleteInventoryItem(item.id!);
      if (success) {
        // remove from local DB and UI
        try {
          await _dbService.deleteInventoryItem(item.id!);
        } catch (e) {
          getLogger('app').info('Warning: failed to delete local DB record: $e');
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

  Future<void> syncPendingChanges() async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    getLogger('app').info("Starting sync of pending changes...");
    int createdCount = 0;
    int updatedCount = 0;
    String? currentUserId = await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      isSyncing.value = false;
      DialogUtils.showError("Cannot sync without valid Merchant ID.");
      return;
    }

    final itemsToCreate = await _dbService.getItemsToCreate(
      merchantId: currentUserId,
    );
    for (var item in itemsToCreate) {
      if (item.id == null || item.id!.isEmpty) continue;
      getLogger('app').info("Syncing (create): ${item.name}");
      InventoryItem? createdItem = await _apiService.createInventoryItem(item);
      if (createdItem != null) {
        await _dbService.markItemAsSynced(
          item.id!,
          createdItem.id!,
          createdItem.updatedAt,
        );
        createdCount++;
      }
    }

    final itemsToUpdate = await _dbService.getItemsToUpdate(
      merchantId: currentUserId,
    );
    for (var item in itemsToUpdate) {
      if (item.id == null || item.id!.isEmpty || item.needsCreate) continue;
      getLogger('app').info("Syncing (update): ${item.name}");
      InventoryItem? updatedApiItem = await _apiService.updateInventoryItem(
        item.id!,
        item.toJsonForUpdate(),
      );
      if (updatedApiItem != null) {
        final finalItem = updatedApiItem.copyWith(
          isSynced: true,
          needsUpdate: false,
          needsCreate: false,
        );
        await _dbService.updateInventoryItem(finalItem);
        updatedCount++;
      }
    }

    if (createdCount > 0 || updatedCount > 0) {
      DialogUtils.showSuccess(
        "Synced $createdCount new and $updatedCount updated items.",
      );
      await _fetchPageData();
    } else {
      DialogUtils.showInfo("Your local data is up to date.");
      getLogger('app').info("No pending changes to sync.");
    }
    getLogger('app').info("Sync process completed.");
    isSyncing.value = false;
  }

  Future<void> refreshInventoryListFromLocal() async {
    isLoading.value = true;
    String? currentUserId = await _authService.getUserId();
    String? role = await _authService.getUserRole();

    if (role != 'merchant' || currentUserId == null) {
      inventoryItems.clear();
      errorMessage.value = "Merchant not identified. Cannot refresh inventory.";
    } else {
      await _fetchPageData();
    }
    isLoading.value = false;
  }

  @override
  void onClose() {
    // --- Dispose Text Editing Controllers ---
    nameController.dispose();
    descriptionController.dispose();
    skuController.dispose();
    sellingPriceController.dispose();
    originalPriceController.dispose();
    lowStockThresholdController.dispose();
    categoryController.dispose();
    supplierNameController.dispose();
    super.onClose();
  }
}

