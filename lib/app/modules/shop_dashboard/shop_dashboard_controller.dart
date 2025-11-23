import 'package:get/get.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/data/services/shop_dashboard_api_service.dart';
import 'package:smart_retail/app/utils/dialog_utils.dart';

class ShopDashboardController extends GetxController {
  final ShopDashboardApiService _apiService =
      Get.find<ShopDashboardApiService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLoading = true.obs;
  final Rxn<ShopDashboardSummary> summary = Rxn<ShopDashboardSummary>();

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    try {
      isLoading.value = true;

      final userRole = _authService.user.value?.role;
      final user = _authService.user.value;

      print('🔍 [SHOP DASHBOARD CONTROLLER] User role: $userRole');

      // Get shopId based on user role
      String? shopId;
      if (userRole == 'merchant') {
        // For merchants, shopId comes from route parameters
        shopId = Get.parameters['shopId'];
        print(
          '🔍 [SHOP DASHBOARD CONTROLLER] Merchant - Shop ID from params: $shopId',
        );

        if (shopId == null) {
          throw Exception('Shop ID is required for merchants');
        }
      } else if (userRole == 'staff') {
        // For staff, use their assigned shop ID from user model
        shopId = user?.assignedShopId;
        print(
          '🔍 [SHOP DASHBOARD CONTROLLER] Staff - Assigned Shop ID: $shopId',
        );

        if (shopId == null || shopId.isEmpty) {
          throw Exception('Staff member has no assigned shop');
        }
      } else {
        throw Exception('Invalid user role: $userRole');
      }

      print(
        '📦 [SHOP DASHBOARD CONTROLLER] Fetching dashboard for shop: $shopId',
      );
      final result = await _apiService.getDashboardSummary(shopId: shopId);
      summary.value = result;
      print('✅ [SHOP DASHBOARD CONTROLLER] Dashboard loaded successfully');
    } catch (e) {
      print('❌ [SHOP DASHBOARD CONTROLLER] Error: $e');
      DialogUtils.showError('Could not load dashboard summary: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
