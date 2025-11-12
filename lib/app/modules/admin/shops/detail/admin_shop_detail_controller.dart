// lib/app/modules/admin/shops/detail/admin_shop_detail_controller.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/routes/app_pages.dart'; // For navigation to edit page
import 'package:smart_retail/app/data/services/shop_api_service.dart'; // <-- IMPORT ADDED

class AdminShopDetailController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>(); // <-- SERVICE INSTANCE ADDED

  final Rxn<Shop> shop = Rxn<Shop>();
  final RxBool isLoading = true.obs; // isLoading is true initially
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadShopDetailsFromArgs();
  }

  void _loadShopDetailsFromArgs() {
    isLoading.value = true;
    errorMessage.value = null;
    final dynamic argument = Get.arguments;

    if (argument is Shop) {
      shop.value = argument;
      isLoading.value = false; // Loaded from arguments
    } else if (argument is String) {
      // If only an ID is passed (e.g. from a notification or deep link in the future)
      print("INFO: AdminShopDetailController received Shop ID: $argument. Fetching details..."); // MODIFIED
      fetchShopDetailsById(argument); // Fetch details using the ID
    } else {
      print("ERROR: AdminShopDetailController received invalid arguments for shop details."); // MODIFIED
      errorMessage.value = "Could not load shop details. Invalid data received.";
      isLoading.value = false;
    }
  }

  Future<void> fetchShopDetailsById(String shopId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final fetchedShop = await _shopApiService.adminGetShopById(shopId);
      if (fetchedShop != null) {
        shop.value = fetchedShop;
      } else {
        errorMessage.value = "Failed to fetch shop details. Shop not found or error occurred.";
      }
    } catch (e) {
      print("ERROR: Error fetching shop details by ID $shopId: $e"); // MODIFIED
      errorMessage.value = "An error occurred while fetching shop details.";
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToEditShop() {
    if (shop.value != null) {
      Get.toNamed(Routes.ADMIN_ADD_EDIT_SHOP, arguments: shop.value)?.then((result) {
        if (result == true) { // If edit page returns true (meaning a change was made)
          print("INFO: Returned from edit shop. Refreshing shop details."); // MODIFIED
          refreshShopDetails(); // <-- CALL ENHANCED REFRESH
        }
      });
    } else {
      Get.snackbar("Error", "Shop data not available for editing.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> refreshShopDetails() async { // <-- MADE ASYNC
    if (shop.value != null && shop.value!.id != null) {
      print("INFO: Refresh shop details called. Fetching from API for ID: ${shop.value!.id!}"); // MODIFIED
      await fetchShopDetailsById(shop.value!.id!); // <-- USE API FETCH METHOD
    } else {
      // If shop.value or its ID is null, try to reload from initial arguments
      // This might happen if the initial load failed or arguments were weird
      print("WARN: Cannot refresh via API as shop ID is missing. Attempting to reload from arguments."); // MODIFIED
       _loadShopDetailsFromArgs();
      if (shop.value == null) { // If still null after trying to reload from args
         Get.snackbar("Error", "Cannot refresh. Shop data is unavailable.", snackPosition: SnackPosition.BOTTOM);
      }
    }
  }
}
