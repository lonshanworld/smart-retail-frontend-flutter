// lib/app/modules/admin/shops/admin_shops_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class AdminShopsController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  final RxList<Shop> shops = <Shop>[].obs;
  final RxBool isLoading =
      true.obs; // True initially to show loading on first fetch
  final RxnString errorMessage = RxnString();
  final RxBool isProcessingAction =
      false.obs; // For row-specific actions like delete/toggle

  // Pagination State
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxInt pageSize = 10.obs;

  // Filter State
  final RxnString nameFilter = RxnString();
  final RxnBool isActiveFilter = RxnBool();
  final RxnString merchantIdFilter = RxnString();

  // TextEditingControllers for filter fields
  late TextEditingController nameFilterController;
  late TextEditingController merchantIdFilterController;

  @override
  void onInit() {
    super.onInit();

    nameFilterController = TextEditingController(text: nameFilter.value);
    merchantIdFilterController = TextEditingController(
      text: merchantIdFilter.value,
    );

    nameFilterController.addListener(() {
      if (nameFilter.value !=
          (nameFilterController.text.trim().isEmpty
              ? null
              : nameFilterController.text.trim())) {
        nameFilter.value = nameFilterController.text.trim().isEmpty
            ? null
            : nameFilterController.text.trim();
      }
    });
    merchantIdFilterController.addListener(() {
      if (merchantIdFilter.value !=
          (merchantIdFilterController.text.trim().isEmpty
              ? null
              : merchantIdFilterController.text.trim())) {
        merchantIdFilter.value = merchantIdFilterController.text.trim().isEmpty
            ? null
            : merchantIdFilterController.text.trim();
      }
    });

    debounce(
      nameFilter,
      (_) => fetchShops(resetPage: true),
      time: const Duration(milliseconds: 600),
    );
    debounce(
      merchantIdFilter,
      (_) => fetchShops(resetPage: true),
      time: const Duration(milliseconds: 600),
    );

    fetchShops(); // Initial fetch
  }

  Future<void> fetchShops({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
    }
    isLoading.value = true;
    errorMessage.value = null;
    if (resetPage || currentPage.value == 1) {
      // shops.clear();
    }

    getLogger('app').info(
      "[AdminShopsController] Fetching shops for page ${currentPage.value} with filters: Name=${nameFilter.value}, Active=${isActiveFilter.value}, Merchant=${merchantIdFilter.value}",
    );

    final response = await _shopApiService.adminListShops(
      page: currentPage.value,
      pageSize: pageSize.value,
      nameFilter: nameFilter.value,
      isActiveFilter: isActiveFilter.value,
      merchantIdFilter: merchantIdFilter.value,
    );

    if (response != null) {
      if (currentPage.value == 1 || resetPage) {
        shops.assignAll(response.shops);
      } else {
        shops.assignAll(response.shops);
      }
      totalItems.value = response.pagination.totalItems;
      totalPages.value = response.pagination.totalPages;
      getLogger('app').info(
        "[AdminShopsController] Fetched ${response.shops.length} shops. Total items: ${totalItems.value}",
      );
    } else {
      errorMessage.value = "Failed to fetch shops. Please try again.";
      if (currentPage.value == 1 || resetPage) shops.clear();
    }
    isLoading.value = false;
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchShops();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchShops();
    }
  }

  void goToPage(int page) {
    if (page > 0 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      fetchShops();
    }
  }

  void onNameSubmittedOrCleared(String? name) {
    nameFilterController.text = name ?? '';
  }

  void onMerchantIdSubmittedOrCleared(String? merchantId) {
    merchantIdFilterController.text = merchantId ?? '';
  }

  void applyIsActiveFilter(bool? isActive) {
    isActiveFilter.value = isActive;
    fetchShops(resetPage: true);
  }

  void clearFilters() {
    nameFilterController.text = '';
    merchantIdFilterController.text = '';
    nameFilter.value = null;
    merchantIdFilter.value = null;
    isActiveFilter.value = null;
    fetchShops(resetPage: true);
  }

  Future<void> goToAddShopPage() async {
    final result = await Get.toNamed(Routes.ADMIN_ADD_EDIT_SHOP);
    if (result == true) {
      fetchShops(resetPage: true);
    }
  }

  Future<void> goToEditShopPage(Shop shop) async {
    final result = await Get.toNamed(
      Routes.ADMIN_ADD_EDIT_SHOP,
      arguments: shop,
    );
    if (result == true) {
      fetchShops();
    }
  }

  void goToShopDetailsPage(Shop shop) {
    Get.toNamed(Routes.ADMIN_SHOP_DETAIL, arguments: shop)?.then((result) {
      if (result == true) {
        fetchShops();
      }
    });
  }

  Future<void> deleteShop(String shopId, String shopName) async {
    bool? confirmDelete = await DialogUtils.showCustomDialog<bool>(
      dialog: AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete shop "$shopName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      isProcessingAction.value = true;
      try {
        final success = await _shopApiService.adminDeleteShop(shopId);
        if (success) {
          DialogUtils.showSuccess("Shop \"$shopName\" deleted successfully.");
          if (shops.length == 1 && currentPage.value > 1) {
            currentPage.value--;
          }
          fetchShops();
        }
      } catch (e) {
        DialogUtils.showError("An unexpected error occurred: ${e.toString()}");
      } finally {
        isProcessingAction.value = false;
      }
    }
  }

  Future<void> toggleShopStatus(Shop shop) async {
    if (shop.id == null) return;
    bool currentStatus = shop.isActive ?? true;
    bool newStatus = !currentStatus;
    isProcessingAction.value = true;
    try {
      final success = await _shopApiService.adminSetShopActiveStatus(
        shop.id!,
        newStatus,
      );
      if (success) {
        DialogUtils.showSuccess(
          "Shop \"${shop.name}\" status updated to ${newStatus ? 'Active' : 'Inactive'}.",
        );
        int index = shops.indexWhere((s) => s.id == shop.id);
        if (index != -1) {
          shops[index] = shops[index].copyWith(
            isActive: newStatus,
            updatedAt: DateTime.now(),
          );
        } else {
          fetchShops();
        }
      }
    } catch (e) {
      DialogUtils.showError("Failed to update shop status: ${e.toString()}");
    } finally {
      isProcessingAction.value = false;
    }
  }

  @override
  void onClose() {
    nameFilterController.dispose();
    merchantIdFilterController.dispose();
    super.onClose();
  }
}

