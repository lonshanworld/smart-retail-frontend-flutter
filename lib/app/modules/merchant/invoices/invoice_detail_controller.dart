import 'dart:io';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/data/services/invoice_api_service.dart';
import 'package:smart_retail/app/services/invoice_pdf_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';

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

      print('[InvoiceDetail] Fetching invoice: $invoiceId');

      final result = await _invoiceApiService.getInvoiceById(invoiceId!);

      if (result != null) {
        invoice.value = result;
        print('[InvoiceDetail] Invoice loaded: ${result.invoiceNumber}');
      } else {
        errorMessage.value = 'Invoice not found';
      }
    } catch (e) {
      print('[InvoiceDetail] Error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void refresh() {
    if (invoiceId != null) {
      fetchInvoiceDetails();
    }
  }

  Future<void> downloadPdf() async {
    if (invoice.value == null) {
      Get.snackbar('Error', 'No invoice data available');
      return;
    }

    try {
      isGeneratingPdf.value = true;
      
      final filePath = await InvoicePdfService.generateInvoicePdf(invoice.value!);
      
      if (kIsWeb) {
        Get.snackbar(
          'Success',
          'PDF download initiated',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // For mobile/desktop, share the PDF file
        final file = File(filePath);
        if (await file.exists()) {
          await Printing.sharePdf(
            bytes: await file.readAsBytes(),
            filename: '${invoice.value!.invoiceNumber}.pdf',
          );
          Get.snackbar(
            'Success',
            'PDF generated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
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
