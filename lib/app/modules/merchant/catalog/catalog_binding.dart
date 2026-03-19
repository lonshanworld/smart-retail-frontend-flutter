import 'package:get/get.dart';
import 'package:smart_retail/app/modules/merchant/catalog/catalog_controller.dart';

class CatalogBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CatalogController>(() => CatalogController());
  }
}
