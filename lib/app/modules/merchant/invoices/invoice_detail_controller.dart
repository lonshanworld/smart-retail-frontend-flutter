import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/services/invoice_pdf_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smart_retail/app/utils/app_logger.dart';

class InvoiceDetailController extends GetxController {
  final InvoiceApiService _invoiceApiService = Get.find<InvoiceApiService>();

  final Rxn<Invoice> invoice = Rxn<Invoice>();
  final RxBool isLoading = true.obs;
  final RxBool isGeneratingPdf = false.obs;
  final RxnString errorMessage = RxnString();

  String? invoiceId;

  @override
  void onInit() {
    super.onInit();
    invoiceId = Get.arguments as String?;
    if (invoiceId != null) {
      fetchInvoiceDetails();
    } else {
      errorMessage.value = 'No invoice ID provided';
      isLoading.value = false;
    }
  }

  Future<void> fetchInvoiceDetails() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      getLogger('app').info('[InvoiceDetail] Fetching invoice: $invoiceId');

      final result = await _invoiceApiService.getInvoiceById(invoiceId!);

      if (result != null) {
        invoice.value = result;
        getLogger('app').info('[InvoiceDetail] Invoice loaded: ${result.invoiceNumber}');
        getLogger('app').info('[InvoiceDetail] Invoice items count: ${result.items.length}');

        // Fallback: if items are empty, try fetching invoice by sale ID which may include items
        if (result.items.isEmpty && result.saleId.isNotEmpty) {
          try {
            getLogger('app').info(
              '[InvoiceDetail] Items empty; attempting fallback fetch by saleId: ${result.saleId}',
            );
            final bySale = await _invoiceApiService.getInvoiceBySaleId(result.saleId);
            if (bySale != null && bySale.items.isNotEmpty) {
              invoice.value = bySale;
              getLogger('app').info(
                '[InvoiceDetail] Fallback fetch succeeded, items count: ${bySale.items.length}',
              );
            } else {
              getLogger('app').info('[InvoiceDetail] Fallback fetch returned no items');
            }
          } catch (e) {
            getLogger('app').info('[InvoiceDetail] Fallback fetch error: $e');
          }
        }
      } else {
        getLogger('app').info('[InvoiceDetail] Invoice not found for ID: $invoiceId');

        // Fallback: attempt by saleId if invoiceId is actually a sale id
        final fallbackBySale = await _invoiceApiService.getInvoiceBySaleId(invoiceId!);
        if (fallbackBySale != null) {
          invoice.value = fallbackBySale;
        } else {
          errorMessage.value = 'Invoice not found';
        }
      }
    } catch (e) {
      getLogger('app').info('[InvoiceDetail] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void refresh() {
    if (invoiceId != null) {
      fetchInvoiceDetails();
    }
  }

  Future<void> downloadPdf() async {
    // Log the underlying Invoice value (not the Rx wrapper) for debugging
    final inv = invoice.value;
    print('[InvoiceDetail] invoice detail log: ${inv == null ? 'null' : inv.toJson()}');
    getLogger('app').info('[InvoiceDetail] invoice detail: ${inv?.invoiceNumber ?? 'null'} (items: ${inv?.items.length ?? 0})');

    if (invoice.value == null) {
      Get.snackbar('Error', 'No invoice data available');
      return;
    }

    try {
      isGeneratingPdf.value = true;
      final filePath = await InvoicePdfService.generateInvoicePdf(
        invoice.value!,
      );
      getLogger('app').info('[InvoiceDetail] PDF generated at: $filePath');

      Get.snackbar(
        'Success',
        kIsWeb
            ? 'PDF download initiated'
            : 'PDF saved to device: $filePath',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isGeneratingPdf.value = false;
    }
  }
}

