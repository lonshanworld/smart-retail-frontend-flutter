import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/sale_model.dart';
import 'package:smart_retail/app/data/services/promotion_api_service.dart';
import 'package:smart_retail/app/data/services/shop_api_service.dart';

class SaleDetailController extends GetxController {
  final ShopApiService _shopApiService = Get.find<ShopApiService>();
  final PromotionApiService _promotionApiService =
      Get.find<PromotionApiService>();

  // Get saleId from arguments
  final String saleId = Get.arguments as String;

  // State
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var sale = Rxn<Sale>();
  final RxnString promotionName = RxnString();

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
        await _loadPromotionName(result);
      } else {
        errorMessage.value = 'Could not find details for this sale.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoading(false);
    }
  }

  Future<void> _loadPromotionName(Sale result) async {
    final promotionId = result.appliedPromotionId?.trim();
    if (promotionId == null || promotionId.isEmpty) {
      promotionName.value = null;
      return;
    }

    try {
      final promotion = await _promotionApiService.getPromotionById(
        promotionId,
      );
      promotionName.value = promotion?.name ?? promotionId;
    } catch (_) {
      promotionName.value = promotionId;
    }
  }
}
