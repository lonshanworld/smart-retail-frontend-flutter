import 'package:get/get.dart';
import 'shop_sales_controller.dart';

class ShopSalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ShopSalesController>(ShopSalesController());
  }
}
