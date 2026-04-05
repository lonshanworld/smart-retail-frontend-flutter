import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_selection_item.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/data/services/user_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class AdminAddEditShopController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final UserApiService _userApiService = Get.find<UserApiService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxnString selectedMerchantId = RxnString();
  late TextEditingController nameController;
  late TextEditingController addressController;
  final RxBool isActive = true.obs;

  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  Shop? _shopToEdit;

  final RxString pageTitle = "Add New Shop".obs;
  final RxList<UserSelectionItem> merchants = <UserSelectionItem>[].obs;
  final RxBool isFetchingMerchants = true.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    addressController = TextEditingController();

    _fetchMerchants();

    if (Get.arguments is Shop) {
      isEditMode.value = true;
      _shopToEdit = Get.arguments as Shop;
      pageTitle.value = "Edit Shop";
      _initializeFormFields(_shopToEdit!);
    }
  }

  void _initializeFormFields(Shop shop) {
    selectedMerchantId.value = shop.merchantId;
    nameController.text = shop.name;
    addressController.text = shop.address ?? "";
    isActive.value = shop.isActive ?? true;
  }

  Future<void> _fetchMerchants() async {
    try {
      isFetchingMerchants.value = true;
      final result = await _userApiService.getMerchantsForSelection();
      merchants.assignAll(result);
    } catch (e) {
      DialogUtils.showError("Could not fetch merchants: ${e.toString()}");
    } finally {
      isFetchingMerchants.value = false;
    }
  }

  String? validateMerchantId(String? value) {
    if (value == null || value.isEmpty) {
      return "A merchant must be selected.";
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Shop name is required.";
    }
    if (value.length < 2) {
      return "Shop name must be at least 2 characters.";
    }
    if (value.length > 100) {
      return "Shop name cannot exceed 100 characters.";
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value != null && value.isNotEmpty && value.length > 255) {
      return "Address cannot exceed 255 characters.";
    }
    return null;
  }

  Future<void> saveShop() async {
    if (!formKey.currentState!.validate()) {
      DialogUtils.showWarning("Please correct the errors in the form.");
      return;
    }

    isLoading.value = true;

    try {
      Shop? resultShop;
      if (isEditMode.value && _shopToEdit != null && _shopToEdit!.id != null) {
        Map<String, dynamic> updates = {};
        bool changed = false;

        if (selectedMerchantId.value != _shopToEdit!.merchantId) {
          updates['merchantId'] = selectedMerchantId.value;
          changed = true;
        }
        if (nameController.text != _shopToEdit!.name) {
          updates['name'] = nameController.text;
          changed = true;
        }

        final currentAddress = _shopToEdit!.address ?? "";
        if (addressController.text != currentAddress) {
          updates['address'] = addressController.text.isEmpty
              ? null
              : addressController.text;
          changed = true;
        }

        if (isActive.value != (_shopToEdit!.isActive ?? true)) {
          updates['isActive'] = isActive.value;
          changed = true;
        }

        if (!changed) {
          DialogUtils.showInfo("No changes were made to the shop details.");
          isLoading.value = false;
          return;
        }

        resultShop = await _shopApiService.adminUpdateShop(
          _shopToEdit!.id!,
          updates,
        );
      } else {
        final newShop = Shop(
          merchantId: selectedMerchantId.value!,
          name: nameController.text,
          address: addressController.text.isEmpty
              ? null
              : addressController.text,
          isActive: isActive.value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        resultShop = await _shopApiService.adminCreateShop(newShop);
      }

      // CORRECTED: Unified success and failure handling for both create and edit.
      // On success, ONLY navigate back. The previous screen will show the snackbar.
      if (resultShop != null) {
        Get.back(result: true);
      } else {
        DialogUtils.showError(
          isEditMode.value
              ? "Could not update shop. Please try again."
              : "Could not create shop. Please try again.",
        );
      }
    } catch (e) {
      getLogger('app').info("[AdminAddEditShopController] Error saving shop: $e");
      DialogUtils.showError("An unexpected error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    super.onClose();
  }
}

