import 'package:get/get.dart';

class AppNavigation {
  static void push(String route, {dynamic arguments, Map<String, String>? parameters}) {
    Get.toNamed(route, arguments: arguments, parameters: parameters);
  }

  static void replace(String route, {dynamic arguments, Map<String, String>? parameters}) {
    Get.offNamed(route, arguments: arguments, parameters: parameters);
  }

  static void reset(String route, {dynamic arguments, Map<String, String>? parameters}) {
    Get.offAllNamed(route, arguments: arguments, parameters: parameters);
  }

  static void backOr(String fallbackRoute) {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(fallbackRoute);
    }
  }
}