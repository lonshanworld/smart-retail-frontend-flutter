// lib/app/modules/admin/merchants/detail/admin_merchant_detail_controller.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/merchant_model.dart';
import 'package:smart_retail/app/data/services/admin_merchant_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class AdminMerchantDetailController extends GetxController {
  final AdminMerchantService adminMerchantService;

  AdminMerchantDetailController({required this.adminMerchantService});

  final Rxn<Merchant> merchant = Rxn<Merchant>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadMerchantDetailsFromArgs();
  }

  void _loadMerchantDetailsFromArgs() {
    isLoading.value = true;
    errorMessage.value = null;
    final dynamic argument = Get.arguments;

    if (argument is Merchant) {
      // Set initial data from list (for quick display)
      merchant.value = argument;
      // But fetch full details including shops array
      printInfo(info: "AdminMerchantDetailController received Merchant object. Fetching full details with shops...");
      fetchMerchantDetailsById(argument.id);
    } else if (argument is String) {
      // If only an ID is passed (e.g. from a notification or deep link)
      printInfo(info: "AdminMerchantDetailController received Merchant ID: $argument. Fetching details...");
      fetchMerchantDetailsById(argument);
    } else {
      printError(info: "AdminMerchantDetailController received invalid arguments.");
      errorMessage.value = "Could not load merchant details. Invalid data.";
      isLoading.value = false;
    }
  }

  Future<void> fetchMerchantDetailsById(String merchantId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final fetchedMerchant = await adminMerchantService.getMerchantById(merchantId);
      if (fetchedMerchant != null) {
        merchant.value = fetchedMerchant;
      } else {
        errorMessage.value = "Failed to fetch merchant details.";
      }
    } catch (e) {
      printError(info: "Error fetching merchant details by ID $merchantId: $e");
      errorMessage.value = "An error occurred while fetching details.";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshMerchantDetails() async {
    if (merchant.value != null && merchant.value!.id.isNotEmpty) {
      await fetchMerchantDetailsById(merchant.value!.id);
    } else {
      _loadMerchantDetailsFromArgs(); // Fallback if ID is somehow missing
      if(merchant.value == null) {
        Get.snackbar("Error", "Cannot refresh. Merchant data is unavailable.", snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void navigateToEditMerchant() {
    if (merchant.value != null) {
      Get.toNamed(Routes.ADMIN_ADD_EDIT_MERCHANT, arguments: merchant.value)?.then((result) {
        if (result == true) { // If edit page indicates a change
          refreshMerchantDetails(); // Refresh to show updated data
        }
      });
    } else {
      Get.snackbar("Error", "Merchant data not available for editing.", snackPosition: SnackPosition.BOTTOM);
    }
  }
}
