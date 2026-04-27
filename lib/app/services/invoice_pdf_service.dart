import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smart_retail/app/constants/currency.dart';
import 'package:smart_retail/app/utils/web_file_utils.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:smart_retail/app/utils/app_logger.dart';

class InvoicePdfService {
  /// Builds the invoice PDF bytes without saving them.
  static Future<Uint8List> buildInvoicePdfBytes(Invoice invoice) async {
    final pdf = pw.Document();

    // Add page to PDF. Layout mirrors the on-screen InvoiceDetailView:
    // Header -> Amount Breakdown -> Additional Info -> Items -> Footer
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(invoice),
              pw.SizedBox(height: 16),

              // Amount breakdown (matches UI ordering)
              _buildAmountBreakdown(invoice),
              pw.SizedBox(height: 12),

              // Additional info
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 12),

              // Items list (styled like the UI card)
              if (invoice.items.isNotEmpty) _buildItemsList(invoice),
              pw.SizedBox(height: 16),

              // Footer
              pw.Spacer(),
              _buildFooter(invoice),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a PDF for the given invoice and returns the file path (or downloads on web)
  static Future<String> generateInvoicePdf(Invoice invoice) async {
    final bytes = await buildInvoicePdfBytes(invoice);

    // Save or download PDF
    if (kIsWeb) {
      // For web, trigger a direct download via an anchor element instead of the share sheet.
      final filename = '${invoice.invoiceNumber}.pdf';
      await downloadFile(bytes, filename);
      // Print/log the web download filename for debugging
      getLogger(
        'app',
      ).info('[InvoicePdfService] Web download triggered: $filename');
      return 'web-downloaded';
    } else {
      // For mobile/desktop, save to a user-visible local directory when possible.
      final output = await _getLocalPdfDirectory();
      final file = File(p.join(output.path, '${invoice.invoiceNumber}.pdf'));
      await file.writeAsBytes(bytes);
      // Print/log the saved file path so UI/debugging can see where it landed
      getLogger(
        'app',
      ).info('[InvoicePdfService] Saved invoice PDF to: ${file.path}');
      return file.path;
    }
  }

  static Future<Directory> _getLocalPdfDirectory() async {
    try {
      // Prefer a user-visible Documents/SmartRetail/Invoices folder on Android and iOS
      if (Platform.isAndroid) {
        try {
          final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.documents,
          );
          if (dirs != null && dirs.isNotEmpty) {
            final base = dirs.first;
            // If the returned path is app-scoped (contains '/Android'), prefer
            // the shared public Documents folder by trimming at '/Android'.
            String publicRoot = base.path;
            final androidIdx = base.path.indexOf('${p.separator}Android');
            if (androidIdx != -1) {
              publicRoot = base.path.substring(0, androidIdx);
            }
            final target = Directory(
              p.join(publicRoot, 'Documents', 'SmartRetail', 'Invoices'),
            );
            if (!await target.exists()) await target.create(recursive: true);
            // Log chosen path for debugging
            getLogger('app').info(
              '[InvoicePdfService] Using Android public path: ${target.path}',
            );
            return target;
          }
        } catch (e) {
          getLogger(
            'app',
          ).info('[InvoicePdfService] Android public path fallback failed: $e');
        }
      } else if (Platform.isIOS) {
        try {
          final docs = await getApplicationDocumentsDirectory();
          final target = Directory(
            p.join(docs.path, 'SmartRetail', 'Invoices'),
          );
          if (!await target.exists()) await target.create(recursive: true);
          return target;
        } catch (_) {}
      }

      // Fallback to downloads directory if available
      try {
        final downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory != null) {
          final target = Directory(
            p.join(downloadsDirectory.path, 'SmartRetail', 'Invoices'),
          );
          if (!await target.exists()) await target.create(recursive: true);
          return target;
        }
      } catch (_) {}

      // Last fallback: application documents
      try {
        final appDocs = await getApplicationDocumentsDirectory();
        final target = Directory(
          p.join(appDocs.path, 'SmartRetail', 'Invoices'),
        );
        if (!await target.exists()) await target.create(recursive: true);
        return target;
      } catch (_) {}
    } catch (_) {}

    return await getTemporaryDirectory();
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              invoice.invoiceNumber,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _getStatusColor(invoice.paymentStatus),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            invoice.paymentStatus.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceInfo(Invoice invoice) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Invoice Information',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        _buildInfoRow(
          'Checkout Time:',
          dateFormat.format(invoice.checkoutTime.toLocal()),
        ),
        if (invoice.dueDate != null)
          _buildInfoRow(
            'Due Date:',
            dateFormat.format(invoice.dueDate!.toLocal()),
          ),
        _buildInfoRow(
          'Shop Name:',
          invoice.shopName?.trim().isNotEmpty == true
              ? invoice.shopName!
              : 'Unknown shop',
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountBreakdown(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Amount Breakdown',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),

        // Subtotal
        _buildAmountRow('Subtotal:', invoice.subtotal),
        pw.SizedBox(height: 8),

        // Discount
        if (invoice.discountAmount > 0) ...[
          _buildAmountRow(
            'Discount:',
            -invoice.discountAmount,
            isNegative: true,
          ),
          pw.SizedBox(height: 8),
        ],

        // Tax
        if (invoice.taxAmount > 0) ...[
          _buildAmountRow('Tax:', invoice.taxAmount),
          pw.SizedBox(height: 8),
        ],

        // Divider
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 12),
          height: 2,
          color: PdfColors.grey300,
        ),

        // Total
        _buildAmountRow('TOTAL:', invoice.totalAmount, isTotal: true),

        // Notes
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Notes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 11)),
        ],
      ],
    );
  }

  static pw.Widget _buildAmountRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isNegative = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          formatCurrency(amount),
          style: pw.TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
            color: isNegative
                ? PdfColors.green700
                : (isTotal ? PdfColors.blue900 : PdfColors.black),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        pw.Center(child: _buildSaleQr(invoice)),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildSaleQr(Invoice invoice) {
    final saleId = invoice.saleId.trim().isNotEmpty
        ? invoice.saleId.trim()
        : invoice.id;
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          'Sale ID QR',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: saleId,
          width: 72,
          height: 72,
          drawText: false,
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          saleId,
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsList(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Items',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Column(
          children: invoice.items.map((it) {
            final displayName = it.itemName ?? it.inventoryItemId;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          displayName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        if (it.itemSku != null)
                          pw.Text(
                            'SKU: ${it.itemSku}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'x${it.quantitySold}',
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      formatCurrency(it.sellingPriceAtSale),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      formatCurrency(it.subtotal),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColors.green700;
      case 'pending':
        return PdfColors.orange700;
      case 'overdue':
        return PdfColors.red700;
      case 'cancelled':
        return PdfColors.grey700;
      default:
        return PdfColors.blue700;
    }
  }
}
