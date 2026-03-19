import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
// Removed duplicate imports
// Removed stray code fence
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class StaffInvoicesController extends GetxController {
  final InvoiceApiService _invoiceService = Get.find();
  final AuthService _authService = Get.find();

  final invoices = <Invoice>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final currentPage = 1.obs;
  final hasMorePages = true.obs;
  final totalItems = 0.obs;

  String? _shopId;

  @override
  void onInit() {
    super.onInit();
    _initializeShopId();
    if (_shopId != null) {
      fetchInvoices(refresh: true);
    }
  }

  void _initializeShopId() {
    final user = _auth_service_user();

    // For staff, always use their assigned shop ID
    _shopId = user?.assignedShopId;

    if (_shopId == null || _shopId!.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'No assigned shop found';
      isLoading.value = false;
    }
  }

  // Helper to safely get the current user from AuthService
  dynamic _auth_service_user() => _authService.user.value;

  Future<void> fetchInvoices({bool refresh = false}) async {
    if (_shopId == null) return;

    try {
      if (refresh) {
        isLoading.value = true;
        currentPage.value = 1;
        hasError.value = false;
        errorMessage.value = '';
      } else {
        isLoadingMore.value = true;
      }

      final response = await _invoiceService.listInvoices(
        page: currentPage.value,
        pageSize: 20,
        shopId: _shopId,
      );

      if (response != null) {
        if (refresh) {
          invoices.value = response.items;
        } else {
          invoices.addAll(response.items);
        }

        totalItems.value = response.totalItems;
        hasMorePages.value = currentPage.value < response.totalPages;
      } else {
        if (refresh) {
          hasError.value = true;
          errorMessage.value = 'Failed to load invoices';
        }
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreInvoices() async {
    if (!hasMorePages.value || isLoadingMore.value) return;

    currentPage.value++;
    await fetchInvoices(refresh: false);
  }

  Future<void> refreshInvoices() async {
    currentPage.value = 1;
    await fetchInvoices(refresh: true);
  }

  void navigateToInvoiceDetail(String invoiceId) {
    Get.toNamed(Routes.STAFF_INVOICE_DETAIL, arguments: invoiceId);
  }
}
