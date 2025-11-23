// lib/app/modules/admin/shops/add_edit_shop/admin_add_edit_shop_binding.dart
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/shops/add_edit_shop/admin_add_edit_shop_controller.dart';

class AdminAddEditShopBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminAddEditShopController>(() => AdminAddEditShopController());
  }
}
