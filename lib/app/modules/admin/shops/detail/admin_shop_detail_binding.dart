// lib/app/modules/admin/shops/detail/admin_shop_detail_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/shops/detail/admin_shop_detail_controller.dart';

class AdminShopDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminShopDetailController>(
      () => AdminShopDetailController(),
    );
  }
}
