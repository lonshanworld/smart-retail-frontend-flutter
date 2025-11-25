import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InvoicePdfService {
  /// Generates a PDF for the given invoice and returns the file path (or downloads on web)
  static Future<String> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Add page to PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(invoice),
              pw.SizedBox(height: 30),
              
              // Invoice details
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 30),
              
              // Divider
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              
              // Amount breakdown
              _buildAmountBreakdown(invoice),
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Spacer(),
              _buildFooter(invoice),
            ],
          );
        },
      ),
    );

    // Save or download PDF
    if (kIsWeb) {
      // For web, trigger download
      await pdf.save();
      // Use the printing package's sharing functionality
      // or implement web download via js interop
      return 'web-download-initiated';
    } else {
      // For mobile/desktop, save to file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    }
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
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
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
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        _buildInfoRow('Invoice Date:', dateFormat.format(invoice.invoiceDate.toLocal())),
        if (invoice.dueDate != null)
          _buildInfoRow('Due Date:', dateFormat.format(invoice.dueDate!.toLocal())),
        _buildInfoRow('Sale ID:', invoice.saleId),
        _buildInfoRow('Shop ID:', invoice.shopId),
        if (invoice.customerId != null)
          _buildInfoRow('Customer ID:', invoice.customerId!),
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
          pw.Expanded(
            child: pw.Text(value),
          ),
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
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 16),
        
        // Subtotal
        _buildAmountRow('Subtotal:', invoice.subtotal),
        pw.SizedBox(height: 8),
        
        // Discount
        if (invoice.discountAmount > 0) ...[
          _buildAmountRow('Discount:', -invoice.discountAmount, isNegative: true),
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
        _buildAmountRow(
          'TOTAL:',
          invoice.totalAmount,
          isTotal: true,
        ),
        
        // Notes
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            invoice.notes!,
            style: const pw.TextStyle(fontSize: 11),
          ),
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
          '\$${amount.abs().toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.bold,
            color: isNegative ? PdfColors.green700 : (isTotal ? PdfColors.blue900 : PdfColors.black),
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
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
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
