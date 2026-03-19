import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';

class ShopInvoicesController extends GetxController {
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
    // Try route parameters first (e.g., /shop/invoices?shopId=...)
    final params = Get.parameters;
    if (params.containsKey('shopId') &&
        params['shopId'] != null &&
        params['shopId']!.isNotEmpty) {
      _shopId = params['shopId'];
      return;
    }

    // Fall back to user's assigned shop (staff) or provided argument
    final user = _auth_service_or_getUser();

    _shopId = user?.assignedShopId;

    // If still null, try arguments
    if ((_shopId == null || _shopId!.isEmpty) && Get.arguments != null) {
      try {
        final arg = Get.arguments;
        if (arg is Map && arg.containsKey('shopId')) {
          _shopId = arg['shopId']?.toString();
        }
      } catch (_) {}
    }

    if (_shopId == null || _shopId!.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'No shop selected';
      isLoading.value = false;
    }
  }

  dynamic _auth_service_or_getUser() {
    try {
      return _authService.user.value;
    } catch (_) {
      return null;
    }
  }

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
    Get.toNamed('/shop/invoices/detail', arguments: invoiceId);
  }
}
