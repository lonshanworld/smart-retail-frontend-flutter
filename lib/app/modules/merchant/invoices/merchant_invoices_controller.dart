import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/utils/app_logger.dart';

class MerchantInvoicesController extends GetxController {
  final InvoiceApiService _invoiceApiService = Get.find<InvoiceApiService>();

  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final int pageSize = 10;

  // Filter
  final RxnString selectedShopId = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices({bool resetPage = false}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
      }

      isLoading.value = true;
      errorMessage.value = null;

      getLogger('app').info(
        '[MerchantInvoices] Fetching invoices... page: ${currentPage.value}',
      );

      final response = await _invoiceApiService.listInvoices(
        page: currentPage.value,
        pageSize: pageSize,
        shopId: selectedShopId.value,
      );

      getLogger('app').info(
        '[MerchantInvoices] Response received: ${response != null ? '${response.items.length} invoices' : 'null'}',
      );

      if (response != null) {
        invoices.assignAll(response.items);
        totalPages.value = response.totalPages;
        totalItems.value = response.totalItems;
        getLogger('app').info(
          '[MerchantInvoices] Invoices assigned: ${invoices.length}, total: ${totalItems.value}',
        );
      } else {
        invoices.clear();
        errorMessage.value = 'Failed to load invoices';
      }
    } catch (e) {
      getLogger('app').info('[MerchantInvoices] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void goToNextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      fetchInvoices();
    }
  }

  void goToPreviousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      fetchInvoices();
    }
  }

  void goToInvoiceDetail(String invoiceId) {
    Get.toNamed('/merchant/invoices/$invoiceId', arguments: invoiceId);
  }

  void filterByShop(String? shopId) {
    selectedShopId.value = shopId;
    fetchInvoices(resetPage: true);
  }

  @override
  void refresh() {
    fetchInvoices(resetPage: true);
  }
}

