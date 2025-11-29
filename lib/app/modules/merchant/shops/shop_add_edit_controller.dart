import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart'; // To get user ID and role
import './shops_controller.dart'; // To refresh list after save

class ShopAddEditController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  var isEditing = false.obs;
  var isSaving = false.obs;
  var errorMessage = RxnString();

  Shop? _editingShop; // Store the shop being edited, if any
  final RxBool isCheckingDelete = false.obs;
  final RxBool isDeletable = false.obs;
  final RxMap<String, int> deleteBlockers = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final shopArg = Get.arguments as Shop?;
    if (shopArg != null) {
      isEditing.value = true;
      _editingShop = shopArg;
      nameController.text = _editingShop!.name;
      addressController.text = _editingShop!.address ?? '';
    } else {
      isEditing.value = false;
    }
  }

  Future<void> saveShop() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (isSaving.value) return;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      final String? currentUserId = await _authService.getUserId();
      final String? currentUserRole = await _authService.getUserRole();

      if (currentUserRole != 'merchant' || currentUserId == null) {
        throw Exception('Merchant not authenticated or user ID not found.');
      }

      Shop? savedShop;
      if (isEditing.value && _editingShop != null && _editingShop!.id != null) {
        // Update existing shop
        Map<String, dynamic> updates = {
          'name': nameController.text,
          'address': addressController.text.isNotEmpty
              ? addressController.text
              : null,
        };
        // Ensure the merchantId is not accidentally changed during update if it's part of the `updates` map implicitly.
        // The API should ideally protect against this, or the DTO for update shouldn't include merchantId.
        savedShop = await _shopApiService.updateShop(
          _editingShop!.id!,
          updates,
        );
      } else {
        // Create new shop
        Shop newShop = Shop(
          merchantId: currentUserId, // Use the fetched currentUserId
          name: nameController.text,
          address: addressController.text.isNotEmpty
              ? addressController.text
              : null,
          createdAt: DateTime.now(), // Client-side, backend will override
          updatedAt: DateTime.now(), // Client-side, backend will override
        );
        savedShop = await _shopApiService.createShop(newShop);
      }

      if (savedShop != null) {
        Get.back(); // Go back to the shops list view
        // Notify MerchantShopsController to refresh the list
        if (Get.isRegistered<MerchantShopsController>()) {
          final shopsCtrl = Get.find<MerchantShopsController>();
          await shopsCtrl.fetchShops();
        }
        DialogUtils.showSuccess('Successfully saved shop: ${savedShop.name}');
      } else {
        errorMessage.value = 'Failed to save shop. Please try again.';
        DialogUtils.showError(errorMessage.value!);
      }
    } catch (e) {
      print("Error saving shop: $e");
      errorMessage.value = 'An error occurred: ${e.toString()}';
      DialogUtils.showError(errorMessage.value!);
    } finally {
      isSaving.value = false;
    }
  }

  /// Performs a preflight check and attempts hard delete if safe.
  Future<void> checkAndDeleteShop() async {
    if (_editingShop == null || _editingShop!.id == null) return;
    if (isCheckingDelete.value) return;

    isCheckingDelete.value = true;
    deleteBlockers.clear();
    isDeletable.value = false;

    try {
      final result = await _shopApiService.checkShopDeletable(_editingShop!.id!);
      if (result == null) {
        DialogUtils.showError('Failed to check deletion status.');
        return;
      }
      final bool deletable = result['deletable'] == true;
      final Map<String, dynamic> blockers = result['blockers'] ?? {};
      blockers.forEach((k, v) {
        if (v is int) deleteBlockers[k] = v;
        else if (v is String) {
          final parsed = int.tryParse(v) ?? 0;
          deleteBlockers[k] = parsed;
        }
      });
      isDeletable.value = deletable;

      if (!deletable) {
        // Show blockers
        final entries = deleteBlockers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        DialogUtils.showError('Cannot delete shop. References found:\n$entries');
        return;
      }

      // Confirm and delete
      final confirm = await DialogUtils.showConfirmDialog(
        title: 'Delete Shop',
        message: 'Are you sure you want to permanently delete this shop? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        isDanger: true,
      );
      if (confirm != true) return;

      final success = await _shopApiService.deleteShop(_editingShop!.id!);
      if (success) {
        // Refresh list and pop
        if (Get.isRegistered<MerchantShopsController>()) {
          final shopsCtrl = Get.find<MerchantShopsController>();
          await shopsCtrl.fetchShops();
        }
        DialogUtils.showSuccess('Shop deleted successfully');
        Get.back(result: true);
      } else {
        DialogUtils.showError('Failed to delete shop.');
      }
    } catch (e) {
      DialogUtils.showError('Error: ${e.toString()}');
    } finally {
      isCheckingDelete.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
