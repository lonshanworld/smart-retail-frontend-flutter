// lib/app/modules/admin/merchants/admin_merchants_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/merchant_model.dart';
import 'package:smart_retail/app/data/services/admin_merchant_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart'; // For navigation

class AdminMerchantsController extends GetxController {
  final AdminMerchantService adminMerchantService;

  AdminMerchantsController({required this.adminMerchantService});

  final RxList<Merchant> merchants = <Merchant>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isProcessingAction = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxInt pageSize = 10.obs; // Default page size

  // Filter State
  // These Rx variables will now be updated MANUALLY by the applyFilters method
  final RxnString nameFilter = RxnString();
  final RxnString emailFilter = RxnString();
  final RxnBool isActiveFilter = RxnBool();

  // TextEditingControllers for filter fields
  late TextEditingController nameFilterController;
  late TextEditingController emailFilterController;

  @override
  void onInit() {
    super.onInit();
    // REMOVED: All listeners and debounce logic.
    nameFilterController = TextEditingController();
    emailFilterController = TextEditingController();
    fetchMerchants(); // Initial fetch
  }

  Future<void> fetchMerchants({bool resetPage = false}) async {
    if (resetPage) {
      currentPage.value = 1;
    }
    isLoading.value = true;
    errorMessage.value = null;

    final response = await adminMerchantService.listMerchants(
      page: currentPage.value,
      pageSize: pageSize.value,
      // Pass the reactive filter values directly.
      nameFilter: nameFilter.value,
      emailFilter: emailFilter.value,
      isActiveFilter: isActiveFilter.value,
    );

    if (response != null) {
      merchants.assignAll(response.merchants);
      totalItems.value = response.pagination.totalItems;
      totalPages.value = response.pagination.totalPages;
    } else {
      errorMessage.value = "Failed to fetch merchants.";
      if (currentPage.value == 1 || resetPage) merchants.clear();
    }
    isLoading.value = false;
  }

  // --- Filter Actions ---

  /// This is now the primary method to trigger a search.
  void applyFilters() {
    // Update the reactive variables from the text controllers
    nameFilter.value = nameFilterController.text.trim().isEmpty
        ? null
        : nameFilterController.text.trim();
    emailFilter.value = emailFilterController.text.trim().isEmpty
        ? null
        : emailFilterController.text.trim();

    // Fetch will use the updated reactive variables.
    fetchMerchants(resetPage: true);
  }

  /// Handles the status dropdown change.
  void applyIsActiveFilter(bool? isActive) {
    isActiveFilter.value = isActive;
    // We still trigger a fetch here for immediate feedback, as it's a dropdown.
    fetchMerchants(resetPage: true);
  }

  /// Clears all filters and re-fetches the full list.
  void clearFilters() {
    nameFilterController.clear();
    emailFilterController.clear();

    nameFilter.value = null;
    emailFilter.value = null;
    isActiveFilter.value = null;

    fetchMerchants(resetPage: true);
  }

  // --- Pagination ---
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchMerchants();
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchMerchants();
    }
  }

  // --- Navigation ---
  Future<void> goToAddMerchantPage() async {
    final result = await Get.toNamed(Routes.ADMIN_ADD_EDIT_MERCHANT);
    if (result == true) {
      applyFilters(); // Re-fetch with current filters
    }
  }

  Future<void> goToEditMerchantPage(Merchant merchant) async {
    final result = await Get.toNamed(
      Routes.ADMIN_ADD_EDIT_MERCHANT,
      arguments: merchant,
    );
    if (result == true) {
      fetchMerchants(); // Re-fetch current page
    }
  }

  void goToMerchantDetailsPage(Merchant merchant) {
    Get.toNamed(Routes.ADMIN_MERCHANT_DETAIL, arguments: merchant)?.then((
      result,
    ) {
      if (result == true) {
        fetchMerchants();
      }
    });
  }

  // --- Actions ---
  Future<void> toggleMerchantStatus(Merchant merchant) async {
    // ... (rest of the method is unchanged)
    if (merchant.id.isEmpty) return;
    bool currentStatus = merchant.isActive;
    bool newStatus = !currentStatus;

    bool? confirmToggle = await DialogUtils.showCustomDialog<bool>(
      dialog: AlertDialog(
        title: Text(newStatus ? 'Confirm Activation' : 'Confirm Deactivation'),
        content: Text(
          'Are you sure you want to ${newStatus ? "activate" : "deactivate"} merchant user "${merchant.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              newStatus ? 'Activate' : 'Deactivate',
              style: TextStyle(color: newStatus ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmToggle != true) return;

    isProcessingAction.value = true;
    try {
      final success = await adminMerchantService.setMerchantUserActiveStatus(
        merchant.id,
        newStatus,
      );
      if (success) {
        int index = merchants.indexWhere((m) => m.id == merchant.id);
        if (index != -1) {
          merchants[index] = merchant.copyWith(
            isActive: newStatus,
            updatedAt: DateTime.now(),
          );
          merchants.refresh();
        } else {
          fetchMerchants();
        }
      }
    } catch (e) {
      DialogUtils.showError(
        "Failed to update merchant status: ${e.toString()}",
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  Future<void> deleteMerchant(String merchantId, String merchantName) async {
    // ... (rest of the method is unchanged)
    bool? confirmDelete = await DialogUtils.showCustomDialog<bool>(
      dialog: AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to PERMANENTLY delete merchant user "$merchantName"? This action cannot be undone.',
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

    if (confirmDelete != true) return;

    isProcessingAction.value = true;
    try {
      final success = await adminMerchantService.deleteUserMerchant(merchantId);
      if (success) {
        if (merchants.length == 1 && currentPage.value > 1) {
          currentPage.value--;
        }
        applyFilters(); // Re-fetch with current filters
      }
    } catch (e) {
      DialogUtils.showError("Failed to delete merchant: ${e.toString()}");
    } finally {
      isProcessingAction.value = false;
    }
  }

  @override
  void onClose() {
    nameFilterController.dispose();
    emailFilterController.dispose();
    super.onClose();
  }
}
