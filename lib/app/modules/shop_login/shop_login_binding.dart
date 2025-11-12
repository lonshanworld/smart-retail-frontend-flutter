import 'package:get/get.dart';
import './shop_login_controller.dart';

class ShopLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopLoginController>(() => ShopLoginController());
  }
}
