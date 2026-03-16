import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/shop/invoices/shop_invoices_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/data/models/invoice_model.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/section_header.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ShopInvoicesView extends GetView<ShopInvoicesController> {
  const ShopInvoicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Invoices',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.shop.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.hasError.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load invoices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: controller.refreshInvoices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final invoices = controller.invoices;
          if (invoices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No invoices yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invoices will appear here once sales are completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshInvoices,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SectionHeader(
                    title: "Shop Invoices",
                    subtitle: "${controller.totalItems.value} total invoices",
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: invoices.length + (controller.hasMorePages.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == invoices.length) {
                        controller.loadMoreInvoices();
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final invoice = invoices[index];
                      return _buildInvoiceCard(context, invoice);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12.0),
      onTap: () => controller.navigateToInvoiceDetail(invoice.id),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sale #${invoice.saleId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.shade500,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    invoice.paymentStatus.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().format(invoice.invoiceDate.toLocal()),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '\$${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
