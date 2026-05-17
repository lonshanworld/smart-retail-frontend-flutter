import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
  static Future<Uint8List> buildInvoicePdfBytes(
    Invoice invoice, {
    double fontScale = 1.0,
  }) async {
    try {
      final normalizedScale = _normalizeRenderScale(fontScale);
      final invoiceImage = await _renderInvoiceDetailAsImage(
        invoice,
        fontScale: normalizedScale,
      );
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(invoiceImage);

      // Render as an embedded image so text is rasterized and consistent across devices.
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      getLogger('app').info(
        '[InvoicePdfService] Image render failed, falling back to vector PDF: $e',
      );
      return _buildVectorInvoicePdfBytes(invoice);
    }
  }

  static double _normalizeRenderScale(double value) {
    if (value < 0.8) return 0.8;
    if (value > 3.0) return 3.0;
    return value;
  }

  static Future<Uint8List> _buildVectorInvoicePdfBytes(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              pw.SizedBox(height: 16),
              _buildAmountBreakdown(invoice),
              pw.SizedBox(height: 12),
              _buildInvoiceInfo(invoice),
              pw.SizedBox(height: 12),
              if (invoice.items.isNotEmpty) _buildItemsList(invoice),
              pw.SizedBox(height: 16),
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
  static Future<String> generateInvoicePdf(
    Invoice invoice, {
    double fontScale = 1.0,
  }) async {
    final bytes = await buildInvoicePdfBytes(invoice, fontScale: fontScale);

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

  static Future<Uint8List> _renderInvoiceDetailAsImage(
    Invoice invoice, {
    double fontScale = 1.0,
  }) async {
    final scale = _normalizeRenderScale(fontScale);
    double fs(double value) => value * scale;

    const width = 1240;
    const horizontalPadding = 64.0;
    const topPadding = 56.0;
    const baseHeight = 1280;
    final footerReserveHeight = (220 * scale).round();
    final scaleBufferHeight = (((scale - 1.0).clamp(0.0, 2.0)) * 720).round();
    final extraItemsHeight = (invoice.items.length * (58 * scale)).round();
    final notesHeight =
        (invoice.notes != null && invoice.notes!.trim().isNotEmpty)
        ? (120 * scale).round()
        : 0;
    final imageHeight =
        baseHeight +
        extraItemsHeight +
        notesHeight +
        footerReserveHeight +
        scaleBufferHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), imageHeight.toDouble()),
      whitePaint,
    );

    double y = topPadding;
    final contentWidth = width - (horizontalPadding * 2);

    TextPainter makePainter(
      String text,
      TextStyle style, {
      TextAlign align = TextAlign.left,
    }) {
      return TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: align,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: contentWidth);
    }

    void drawTextLine(
      String text, {
      required TextStyle style,
      TextAlign align = TextAlign.left,
      double spacingAfter = 8,
    }) {
      final painter = makePainter(text, style, align: align);
      final dx = switch (align) {
        TextAlign.center => (width - painter.width) / 2,
        TextAlign.right => width - horizontalPadding - painter.width,
        _ => horizontalPadding,
      };
      painter.paint(canvas, Offset(dx, y));
      y += painter.height + spacingAfter;
    }

    void drawDivider() {
      final paint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(width - horizontalPadding, y),
        paint,
      );
      y += 14;
    }

    void drawAmountRow(String label, String amount, {bool bold = false}) {
      final leftPainter = makePainter(
        label,
        TextStyle(
          fontSize: fs(bold ? 30 : 24),
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111111),
        ),
      );
      final rightPainter = makePainter(
        amount,
        TextStyle(
          fontSize: fs(bold ? 30 : 24),
          fontWeight: FontWeight.w400,
          color: bold ? const Color(0xFF0D47A1) : const Color(0xFF111111),
        ),
      );

      leftPainter.paint(canvas, Offset(horizontalPadding, y));
      rightPainter.paint(
        canvas,
        Offset(width - horizontalPadding - rightPainter.width, y),
      );
      y +=
          (leftPainter.height > rightPainter.height
              ? leftPainter.height
              : rightPainter.height) +
          10;
    }

    String status = invoice.paymentStatus.toUpperCase();
    final statusPainter = makePainter(
      status,
      TextStyle(
        fontSize: fs(20),
        fontWeight: FontWeight.w400,
        color: const Color(0xFFFFFFFF),
      ),
    );

    drawTextLine(
      'INVOICE',
      style: TextStyle(
        fontSize: fs(56),
        fontWeight: FontWeight.w400,
        color: const Color(0xFF0D47A1),
      ),
      spacingAfter: 6,
    );
    drawTextLine(
      invoice.invoiceNumber,
      style: TextStyle(
        fontSize: fs(32),
        fontWeight: FontWeight.w400,
        color: const Color(0xFF111111),
      ),
      spacingAfter: 14,
    );

    final pillPaddingH = 18.0;
    final pillPaddingV = 10.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontalPadding,
        y,
        statusPainter.width + (pillPaddingH * 2),
        statusPainter.height + (pillPaddingV * 2),
      ),
      const Radius.circular(12),
    );
    final statusBg = Paint()..color = const Color(0xFF1E88E5);
    canvas.drawRRect(pillRect, statusBg);
    statusPainter.paint(
      canvas,
      Offset(horizontalPadding + pillPaddingH, y + pillPaddingV),
    );
    y += statusPainter.height + (pillPaddingV * 2) + 18;

    drawDivider();

    drawTextLine(
      'Amount Breakdown',
      style: TextStyle(
        fontSize: fs(30),
        fontWeight: FontWeight.w400,
        color: const Color(0xFF111111),
      ),
      spacingAfter: 10,
    );
    drawAmountRow('Subtotal', formatCurrency(invoice.subtotal));
    if (invoice.discountAmount > 0) {
      drawAmountRow('Discount', formatCurrency(-invoice.discountAmount));
    }
    if (invoice.taxAmount > 0) {
      drawAmountRow('Tax', formatCurrency(invoice.taxAmount));
    }
    if (invoice.deliveryCharge > 0) {
      drawAmountRow('Delivery Charge', formatCurrency(invoice.deliveryCharge));
    }
    drawDivider();
    drawAmountRow('TOTAL', formatCurrency(invoice.totalAmount), bold: true);
    y += 8;

    drawDivider();

    drawTextLine(
      'Additional Information',
      style: TextStyle(
        fontSize: fs(30),
        fontWeight: FontWeight.w400,
        color: const Color(0xFF111111),
      ),
      spacingAfter: 10,
    );

    final checkoutDate = DateFormat(
      'MMM dd, yyyy HH:mm',
    ).format(invoice.checkoutTime.toLocal());
    drawTextLine(
      'Shop Name: ${invoice.shopName?.trim().isNotEmpty == true ? invoice.shopName! : 'Unknown shop'}',
      style: TextStyle(fontSize: fs(22), color: const Color(0xFF222222)),
      spacingAfter: 6,
    );
    drawTextLine(
      'Checkout Time: $checkoutDate',
      style: TextStyle(fontSize: fs(22), color: const Color(0xFF222222)),
      spacingAfter: 6,
    );
    if (invoice.dueDate != null) {
      drawTextLine(
        'Due Date: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate!.toLocal())}',
        style: TextStyle(fontSize: fs(22), color: const Color(0xFF222222)),
        spacingAfter: 6,
      );
    }
    if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) {
      drawTextLine(
        'Notes: ${invoice.notes!.trim()}',
        style: TextStyle(fontSize: fs(21), color: const Color(0xFF333333)),
        spacingAfter: 10,
      );
    }

    drawDivider();
    drawTextLine(
      'Items',
      style: TextStyle(
        fontSize: fs(30),
        fontWeight: FontWeight.w400,
        color: const Color(0xFF111111),
      ),
      spacingAfter: 8,
    );

    if (invoice.items.isEmpty) {
      drawTextLine(
        'No item list found for this invoice yet.',
        style: TextStyle(fontSize: fs(22), color: const Color(0xFF666666)),
        spacingAfter: 6,
      );
    } else {
      for (final it in invoice.items) {
        final itemName = (it.itemName != null && it.itemName!.trim().isNotEmpty)
            ? it.itemName!
            : it.inventoryItemId;
        drawTextLine(
          '$itemName x${it.quantitySold}  ${formatCurrency(it.sellingPriceAtSale)}  ${formatCurrency(it.subtotal)}',
          style: TextStyle(
            fontSize: fs(21),
            color: const Color(0xFF111111),
            fontWeight: FontWeight.w400,
          ),
          spacingAfter: 6,
        );
        if (it.itemSku != null && it.itemSku!.trim().isNotEmpty) {
          drawTextLine(
            'SKU: ${it.itemSku}',
            style: TextStyle(fontSize: fs(18), color: const Color(0xFF666666)),
            spacingAfter: 8,
          );
        }
      }
    }

    y += 10;
    drawDivider();
    drawTextLine(
      'Thank you for your purchase',
      style: TextStyle(
        fontSize: fs(21),
        color: const Color(0xFF555555),
        fontStyle: FontStyle.italic,
      ),
      align: TextAlign.center,
      spacingAfter: 4,
    );
    drawTextLine(
      'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
      style: TextStyle(fontSize: fs(18), color: const Color(0xFF666666)),
      spacingAfter: 6,
    );
    drawTextLine(
      'Need custom software for your business? Visit nanonux.com.',
      style: TextStyle(fontSize: fs(18), color: const Color(0xFF666666)),
      align: TextAlign.center,
      spacingAfter: 0,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, imageHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to convert invoice image to PNG bytes');
    }
    return byteData.buffer.asUint8List();
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
              style: pw.TextStyle(fontSize: 32, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 8),
            pw.Text(invoice.invoiceNumber, style: pw.TextStyle(fontSize: 18)),
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
            style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
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
        pw.Text('Invoice Information', style: pw.TextStyle(fontSize: 16)),
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
              style: pw.TextStyle(color: PdfColors.grey700),
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
        pw.Text('Amount Breakdown', style: pw.TextStyle(fontSize: 16)),
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
          pw.Text('Notes:', style: pw.TextStyle(fontSize: 12)),
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
        pw.Text(label, style: pw.TextStyle(fontSize: isTotal ? 18 : 14)),
        pw.Text(
          formatCurrency(amount),
          style: pw.TextStyle(
            fontSize: isTotal ? 20 : 14,
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
          'Thank you for your purchase',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Need custom software for your business? Visit nanonux.com.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
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
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
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
        pw.Text('Items', style: pw.TextStyle(fontSize: 16)),
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
                        pw.Text(displayName, style: pw.TextStyle()),
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
                      style: pw.TextStyle(),
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
