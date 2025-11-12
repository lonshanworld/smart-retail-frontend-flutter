import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_customer_model.dart';
import 'package:smart_retail/app/data/services/shop_customers_api_service.dart';

class ShopCustomersController extends GetxController {
  final ShopCustomersApiService _apiService = Get.find<ShopCustomersApiService>();

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final RxList<ShopCustomer> allCustomers = <ShopCustomer>[].obs;
  final RxList<ShopCustomer> filteredCustomers = <ShopCustomer>[].obs;

  final TextEditingController searchController = TextEditingController();
  String? _shopId;

  @override
  void onInit() {
    super.onInit();
    // Get shopId from route parameters (consistent with other shop pages)
    _shopId = Get.parameters['shopId'];
    developer.log('🏪 [ShopCustomersController] Initializing with shopId: $_shopId', name: 'Controller');

    if (_shopId == null || _shopId!.isEmpty) {
      developer.log('❌ [ShopCustomersController] No shopId found in route parameters', name: 'Controller');
      errorMessage.value = 'Error: No shop is currently selected. Please go back and select a shop to view customers.';
      isLoading.value = false;
    } else {
      developer.log('✅ [ShopCustomersController] shopId found, fetching customers...', name: 'Controller');
      fetchCustomers();
    }

    searchController.addListener(_filterCustomers);
  }

  @override
  void onClose() {
    searchController.removeListener(_filterCustomers);
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchCustomers() async {
    if (_shopId == null) {
      developer.log('❌ [ShopCustomersController] Cannot fetch customers: shopId is null', name: 'Controller');
      errorMessage.value = 'Error: Cannot fetch customers without a shop ID.';
      return;
    }

    try {
      developer.log('🔄 [ShopCustomersController] Starting fetch for shopId: $_shopId', name: 'Controller');
      isLoading.value = true;
      errorMessage.value = null;
      
      final customers = await _apiService.getCustomers(_shopId!);
      
      developer.log('✅ [ShopCustomersController] Received ${customers.length} customers', name: 'Controller');
      allCustomers.assignAll(customers);
      filteredCustomers.assignAll(customers);
    } catch (e, stackTrace) {
      developer.log('💥 [ShopCustomersController] Error fetching customers', 
        name: 'Controller', 
        error: e, 
        stackTrace: stackTrace
      );
      errorMessage.value = 'Failed to load customers: ${e.toString()}';
    } finally {
      isLoading.value = false;
      developer.log('🏁 [ShopCustomersController] Fetch completed. Loading: ${isLoading.value}', name: 'Controller');
    }
  }

  void _filterCustomers() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      filteredCustomers.assignAll(allCustomers);
    } else {
      filteredCustomers.assignAll(allCustomers.where((customer) {
        final nameMatch = customer.name.toLowerCase().contains(query);
        final emailMatch = customer.email?.toLowerCase().contains(query) ?? false;
        final phoneMatch = customer.phone?.toLowerCase().contains(query) ?? false;
        return nameMatch || emailMatch || phoneMatch;
      }).toList());
    }
  }

  Future<void> createNewCustomer(Map<String, dynamic> customerData) async {
    if (_shopId == null) {
      developer.log('❌ [ShopCustomersController] Cannot create customer: shopId is null', name: 'Controller');
      Get.snackbar('Operation Failed', 'Cannot create customer: No shop is selected.');
      return;
    }
    try {
      developer.log('➕ [ShopCustomersController] Creating customer with data: $customerData', name: 'Controller');
      isLoading.value = true;
      await _apiService.createCustomer(_shopId!, customerData);
      developer.log('✅ [ShopCustomersController] Customer created successfully', name: 'Controller');
      Get.snackbar('Success', 'New customer has been created.', snackPosition: SnackPosition.BOTTOM);
      await fetchCustomers(); // Refresh the list
    } catch (e, stackTrace) {
      developer.log('💥 [ShopCustomersController] Error creating customer', 
        name: 'Controller', 
        error: e, 
        stackTrace: stackTrace
      );
      Get.snackbar('Error', 'Failed to create customer: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
