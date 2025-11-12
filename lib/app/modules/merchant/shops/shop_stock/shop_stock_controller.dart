import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_stock_model.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart'; // For navigation

class ShopStockController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  late final String shopId;
  late final String shopName; // For display in AppBar

  var shopStockItems = <ShopStockItem>[].obs; // Master list from API
  var filteredShopStockItems = <ShopStockItem>[].obs; // List displayed in UI

  var isLoading = true.obs;
  var errorMessage = RxnString();

  // Search and Filter
  final TextEditingController searchController = TextEditingController();
  var searchText = ''.obs;
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  ShopStockController() {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>; 
    shopId = args['shopId'] as String;
    shopName = args['shopName'] as String? ?? 'Shop Inventory';
  }

  @override
  void onInit() {
    super.onInit();
    fetchShopStock();
    searchController.addListener(() {
      _debouncer.call(() {
        searchText.value = searchController.text;
      });
    });
    ever(searchText, (_) => _filterItems());
    ever(shopStockItems, (_) => _filterItems()); 
  }

  Future<void> fetchShopStock({bool showLoading = true}) async {
    try {
      if (showLoading) {
        isLoading(true);
      }
      errorMessage.value = null;
      final PaginatedShopStockResponse? response = await _shopApiService.listInventoryForShop(shopId);
      
      if (response != null) {
        shopStockItems.assignAll(response.items);
      } else {
        shopStockItems.clear();
        errorMessage.value = "Failed to fetch shop inventory.";
      }
    } catch (e) {
      print("Error fetching shop stock for shop $shopId: $e");
      errorMessage.value = "An error occurred. Please try again.";
    } finally {
      if (showLoading) {
        isLoading(false);
      }
    }
  }

  void _filterItems() {
    final query = searchText.value.toLowerCase();
    if (query.isEmpty) {
      filteredShopStockItems.assignAll(shopStockItems);
    } else {
      filteredShopStockItems.assignAll(shopStockItems.where((item) {
        final itemNameLower = item.itemName.toLowerCase();
        final itemSkuLower = item.itemSku?.toLowerCase() ?? '';
        return itemNameLower.contains(query) || itemSkuLower.contains(query);
      }).toList());
    }
  }

  void clearSearch() {
    searchController.clear();
  }

  void goToAddStock(ShopStockItem item) {
    Get.toNamed(Routes.MERCHANT_SHOP_STOCK_IN, arguments: {
      'shopId': shopId,
      'shopName': shopName, 
      'inventoryItemId': item.inventoryItemId,
      'itemName': item.itemName,
      'currentQuantity': item.quantity,
    });
  }

  void goToAdjustStock(ShopStockItem item) {
    Get.toNamed(Routes.MERCHANT_SHOP_STOCK_ADJUST, arguments: {
      'shopId': shopId,
      'shopName': shopName, 
      'inventoryItemId': item.inventoryItemId,
      'itemName': item.itemName,
      'currentQuantity': item.quantity,
      'itemSku': item.itemSku,
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _debouncer.cancel();
    super.onClose();
  }
}

// Debouncer class
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}
