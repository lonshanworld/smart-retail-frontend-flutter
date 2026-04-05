import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/services/merchant_staff_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class StaffAddEditController extends GetxController {
  final MerchantStaffApiService _apiService =
      Get.find<MerchantStaffApiService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isEditMode = false.obs;
  final Rxn<User> _editingStaff = Rxn<User>();

  final RxBool isSaving = false.obs;
  final RxBool isActive = true.obs;
  final RxnString formError = RxnString();

  // New state for shop assignment
  final RxList<Shop> shopList = <Shop>[].obs;
  final RxBool isLoadingShops = true.obs;
  final RxnString selectedShopId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _fetchShops(); // Fetch shops for the dropdown

    if (Get.arguments is User) {
      isEditMode.value = true;
      _editingStaff.value = Get.arguments as User;
      nameController.text = _editingStaff.value!.name;
      emailController.text = _editingStaff.value!.email;
      isActive.value = _editingStaff.value!.isActive;
      selectedShopId.value = _editingStaff.value!.assignedShopId;
    }
  }

  Future<void> _fetchShops() async {
    try {
      isLoadingShops.value = true;
      final shops = await _apiService.getShopsForSelection();
      final uniqueShops = <Shop>[];
      final seenIds = <String>{};
      for (final shop in shops) {
        final id = shop.id?.trim();
        if (id == null || id.isEmpty) {
          uniqueShops.add(shop);
          continue;
        }
        if (seenIds.add(id)) {
          uniqueShops.add(shop);
        }
      }
      shopList.assignAll(uniqueShops);
    } catch (e) {
      DialogUtils.showError('Could not load shops for assignment: $e');
    } finally {
      isLoadingShops.value = false;
    }
  }

  Future<void> saveStaff() async {
    getLogger('app').info('reach here to save staff ??');
    if (!formKey.currentState!.validate()) {
      formError.value = 'Please correct the errors above.';
      return;
    }

    isSaving.value = true;
    formError.value = null;

    try {
      final data = <String, dynamic>{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'isActive': isActive.value,
        'assignedShopId': selectedShopId.value,
      };
      getLogger('app').info('reach here for save staff 2');
      if (!isEditMode.value) {
        if (passwordController.text.isEmpty) {
          formError.value = 'Password is required for new staff.';
          isSaving.value = false;
          return;
        }
        data['password'] = passwordController.text;
      }
      getLogger('app').info('reach here 3 staff');
      if (isEditMode.value) {
        await _apiService.updateStaff(_editingStaff.value!.id, data);
      } else {
        getLogger('app').info('reach here 4 staff');
        await _apiService.createStaff(data);
      }
      getLogger('app').info('reach here 5 staff');
      Get.back(result: true); // Return true to signal a refresh is needed
      DialogUtils.showSuccess('Staff member saved successfully.');
    } catch (e) {
      formError.value = e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

