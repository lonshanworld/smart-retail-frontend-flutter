import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';

class SaleDetailController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();

  // Get saleId from arguments
  final String saleId = Get.arguments as String;

  // State
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var sale = Rxn<Sale>();

  @override
  void onInit() {
    super.onInit();
    fetchSaleDetails();
  }

  Future<void> fetchSaleDetails() async {
    try {
      isLoading(true);
      errorMessage('');
      final result = await _shopApiService.getSaleById(saleId);
      if (result != null) {
        sale.value = result;
      } else {
        errorMessage.value = 'Could not find details for this sale.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoading(false);
    }
  }
}
