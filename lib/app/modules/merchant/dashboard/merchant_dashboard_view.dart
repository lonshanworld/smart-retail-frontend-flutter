import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/merchant_dashboard_summary_model.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/modules/merchant/dashboard/merchant_dashboard_controller.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/modules/merchant/widgets/merchant_main_scaffold.dart';
import 'package:smart_retail/app/widgets/stat_card.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/section_header.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_layout.dart';
import 'package:smart_retail/app/widgets/cards/data_sync_card.dart';

class MerchantDashboardView extends GetView<MerchantDashboardController> {
  const MerchantDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return MerchantMainScaffold(
      title: 'Dashboard',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.shade50.withOpacity(0.3), Colors.white],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => controller.fetchDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildShopSelector(context, controller),
                const SizedBox(height: 24),
                const DataSyncCard(),
                const SizedBox(height: 24),
                _buildKpiSection(context, controller),
                const SizedBox(height: 32),
                _buildManagementActionsSection(context, controller),
                const SizedBox(height: 32),
                _buildTopProductsSection(context, controller),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSelector(
    BuildContext context,
    MerchantDashboardController controller,
  ) {
    return Obx(() {
      if (controller.isLoadingShops.value) {
        return const ModernCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      if (controller.shopError.value != null) {
        return ModernCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading shops: ${controller.shopError.value}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
      }

      List<DropdownMenuItem<Shop?>> shopItems = [
        const DropdownMenuItem<Shop?>(value: null, child: Text("All Shops")),
        ...controller.shopList.map((shop) {
          return DropdownMenuItem<Shop?>(value: shop, child: Text(shop.name));
        }).toList(),
      ];

      return ModernCard(
        child: DropdownButtonFormField<Shop?>(
          decoration: InputDecoration(
            labelText: 'Select Shop',
            labelStyle: TextStyle(color: AppColors.primary.shade700),
            prefixIcon: Icon(
              Icons.store_rounded,
              color: AppColors.primary.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.primary.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
          value: controller.selectedShop.value,
          items: shopItems,
          onChanged: (Shop? newValue) {
            controller.onShopSelected(newValue);
          },
          isExpanded: true,
        ),
      );
    });
  }

  Widget _buildKpiSection(
    BuildContext context,
    MerchantDashboardController controller,
  ) {
    return Obx(() {
      if (controller.isLoadingDashboard.value) {
        return const ModernCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      if (controller.dashboardError.value != null) {
        return ModernCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.dashboardError.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (controller.dashboardSummary.value == null) {
        return ModernCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No dashboard data available",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a shop to view metrics",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final summary = controller.dashboardSummary.value!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Performance Metrics",
            subtitle: "Key indicators for your business",
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: 16,
            children: [
              GradientStatCard(
                title: 'Total Revenue',
                value:
                    '\$${summary.totalSalesRevenue.value.toStringAsFixed(2)}',
                icon: Icons.attach_money_rounded,
                gradient: AppColors.successGradientColors,
              ),
              StatCard(
                title: 'Transactions',
                value: summary.numberOfTransactions.value.toInt().toString(),
                icon: Icons.receipt_long_rounded,
                color: AppColors.info,
              ),
              StatCard(
                title: 'Avg. Order Value',
                value:
                    '\$${summary.averageOrderValue.value.toStringAsFixed(2)}',
                icon: Icons.shopping_cart_checkout_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildManagementActionsSection(
    BuildContext context,
    MerchantDashboardController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: "Quick Actions",
          subtitle: "Manage your business operations",
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 2,
          spacing: 16,
          children: [
            _buildActionCard(
              icon: Icons.inventory_2_rounded,
              title: 'Master Inventory',
              subtitle: 'Manage products & stock',
              gradient: [
                AppColors.warning.shade400,
                AppColors.warning.shade600,
              ],
              onTap: () => Get.toNamed(Routes.MERCHANT_INVENTORY),
            ),
            _buildActionCard(
              icon: Icons.store_mall_directory_rounded,
              title: 'Shops & Stock',
              subtitle: 'Manage shop inventory',
              gradient: [AppColors.info.shade400, AppColors.info.shade600],
              onTap: () => Get.toNamed(Routes.MERCHANT_SHOPS),
            ),
            _buildActionCard(
              icon: Icons.receipt_long_rounded,
              title: 'Invoices',
              subtitle: 'View and download invoices',
              gradient: [
                AppColors.primary.shade400,
                AppColors.primary.shade600,
              ],
              onTap: () => Get.toNamed(Routes.MERCHANT_INVOICES),
            ),
            _buildActionCard(
              icon: Icons.people_alt_rounded,
              title: 'Suppliers',
              subtitle: 'Manage supplier relationships',
              gradient: [
                AppColors.secondary.shade400,
                AppColors.secondary.shade600,
              ],
              onTap: () => Get.toNamed(Routes.MERCHANT_SUPPLIERS),
            ),
            _buildActionCard(
              icon: Icons.badge_rounded,
              title: 'Staff',
              subtitle: 'Manage team members',
              gradient: [
                AppColors.success.shade400,
                AppColors.success.shade600,
              ],
              onTap: () => Get.toNamed(Routes.MERCHANT_STAFF),
            ),
                _buildActionCard(
                  icon: Icons.print_rounded,
                  title: 'Printer Settings',
                  subtitle: 'Configure receipt printer',
                  gradient: [
                    AppColors.secondary.shade400,
                    AppColors.secondary.shade600,
                  ],
                  onTap: () => Get.toNamed(Routes.MERCHANT_PRINTER_SETTINGS),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      gradient: LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(
    BuildContext context,
    MerchantDashboardController controller,
  ) {
    return Obx(() {
      if (controller.isLoadingDashboard.value &&
          controller.dashboardSummary.value == null) {
        return const SizedBox.shrink();
      }
      if (controller.dashboardSummary.value == null ||
          controller.dashboardSummary.value!.topSellingProducts.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: "Top Selling Products",
              subtitle: "Best performers",
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 16),
            ModernCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No top selling products yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Products will appear here once you have sales data",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }

      final products = controller.dashboardSummary.value!.topSellingProducts;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Top Selling Products",
            subtitle: "${products.length} best performers",
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 16),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductListItem(products[index], index + 1);
              },
              separatorBuilder: (context, index) =>
                  Divider(height: 24, color: Colors.grey.shade200),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProductListItem(ProductSummaryModel product, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: rank == 1
                    ? [Colors.amber.shade400, Colors.amber.shade600]
                    : rank == 2
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : rank == 3
                    ? [Colors.brown.shade300, Colors.brown.shade400]
                    : [AppColors.primary.shade200, AppColors.primary.shade300],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${product.productId}",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_rounded,
                      size: 14,
                      color: AppColors.success.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${product.quantitySold ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (product.revenue != null) ...[
                const SizedBox(height: 4),
                Text(
                  "\$${product.revenue!.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.shade700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
