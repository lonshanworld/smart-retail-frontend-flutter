import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/inventory_item_model.dart';
import 'package:smart_retail/app/data/services/inventory_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class CatalogController extends GetxController {
  final InventoryApiService _inventoryApi = Get.find<InventoryApiService>();

  final RxBool isLoading = false.obs;
  final RxList<CategoryWithSubcategories> categories =
      <CategoryWithSubcategories>[].obs;
  final RxList<BrandRef> brands = <BrandRef>[].obs;

  List<SubcategoryRef> get allSubcategories {
    return categories.expand((c) => c.subcategories).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    try {
      isLoading.value = true;
      final catalog = await _inventoryApi.getCatalogOptions();
      if (catalog != null) {
        categories.assignAll(catalog.categories);
        brands.assignAll(catalog.brands);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCategory(String name, String description) async {
    final ok = await _inventoryApi.createCategory(
      name: name,
      description: description,
    );
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Category created');
      return true;
    } else {
      DialogUtils.showError('Failed to create category');
      return false;
    }
  }

  Future<bool> updateCategory(
    String categoryId,
    String name,
    String description,
  ) async {
    final ok = await _inventoryApi.updateCategory(
      categoryId: categoryId,
      name: name,
      description: description,
    );
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Category updated');
      return true;
    } else {
      DialogUtils.showError('Failed to update category');
      return false;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    final ok = await _inventoryApi.deleteCategory(categoryId);
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Category deleted');
    } else {
      DialogUtils.showError('Failed to delete category');
    }
  }

  Future<bool> createSubcategory(
    String categoryId,
    String name,
    String description,
  ) async {
    final ok = await _inventoryApi.createSubcategory(
      categoryId: categoryId,
      name: name,
      description: description,
    );
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Subcategory created');
      return true;
    } else {
      DialogUtils.showError('Failed to create subcategory');
      return false;
    }
  }

  Future<bool> updateSubcategory(
    String subcategoryId,
    String categoryId,
    String name,
    String description,
  ) async {
    final ok = await _inventoryApi.updateSubcategory(
      subcategoryId: subcategoryId,
      categoryId: categoryId,
      name: name,
      description: description,
    );
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Subcategory updated');
      return true;
    } else {
      DialogUtils.showError('Failed to update subcategory');
      return false;
    }
  }

  Future<void> deleteSubcategory(String subcategoryId) async {
    final ok = await _inventoryApi.deleteSubcategory(subcategoryId);
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Subcategory deleted');
    } else {
      DialogUtils.showError('Failed to delete subcategory');
    }
  }

  Future<bool> createBrand(
    String name,
    String description, {
    String? imageUrl,
  }) async {
    final res = await _inventoryApi.createBrand(
      name: name,
      description: description,
      imageUrl: imageUrl,
    );
    final ok = res['ok'] == true;
    final message =
        res['message']?.toString() ??
        (ok ? 'Brand created' : 'Failed to create brand');
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess(message);
      return true;
    } else {
      DialogUtils.showError(message);
      return false;
    }
  }

  // Returns raw response from API: {ok: bool, message: string}
  Future<Map<String, dynamic>> createBrandRaw(
    String name,
    String description, {
    String? imageUrl,
  }) async {
    final res = await _inventoryApi.createBrand(
      name: name,
      description: description,
      imageUrl: imageUrl,
    );
    if (res['ok'] == true) {
      await loadCatalog();
    }
    return Map<String, dynamic>.from(res);
  }

  Future<bool> updateBrand(
    String brandId,
    String name,
    String description,
    String? imageUrl,
  ) async {
    // Debug trace for brand edit payloads.
    // This helps confirm whether the image URL is preserved end-to-end.
    final ok = await _inventoryApi.updateBrand(
      brandId: brandId,
      name: name,
      description: description,
      imageUrl: imageUrl,
    );
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Brand updated');
      return true;
    } else {
      DialogUtils.showError('Failed to update brand');
      return false;
    }
  }

  Future<void> deleteBrand(String brandId) async {
    final ok = await _inventoryApi.deleteBrand(brandId);
    if (ok) {
      await loadCatalog();
      DialogUtils.showSuccess('Brand deleted');
    } else {
      DialogUtils.showError('Failed to delete brand');
    }
  }
}
