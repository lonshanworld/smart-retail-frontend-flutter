import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_dashboard_controller.dart';
import 'package:smart_retail/app/modules/shop_dashboard/widgets/shop_main_scaffold.dart';
import 'package:smart_retail/app/widgets/stat_card.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/section_header.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_layout.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/cards/data_sync_card.dart';

class ShopDashboardView extends GetView<ShopDashboardController> {
  const ShopDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShopMainScaffold(
      title: 'Dashboard',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.shop.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            controller.fetchDashboardSummary();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(100.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (controller.summary.value == null) {
                return ModernCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 64, color: AppColors.error.shade400),
                          const SizedBox(height: 24),
                          Text(
                            'Could not load dashboard data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Pull down to refresh',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final summary = controller.summary.value!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DataSyncCard(),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(summary),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: "Today's Performance",
          subtitle: "Real-time shop metrics",
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
              title: 'Sales Today',
              value: NumberFormat.currency(symbol: '\$').format(summary.salesToday),
              icon: Icons.attach_money_rounded,
              gradient: AppColors.successGradientColors,
            ),
            StatCard(
              title: 'Transactions Today',
              value: summary.transactionsToday.toString(),
              icon: Icons.receipt_long_rounded,
              color: AppColors.info,
            ),
            StatCard(
              title: 'Low Stock Items',
              value: summary.lowStockItems.toString(),
              icon: Icons.warning_amber_rounded,
              color: summary.lowStockItems > 0 ? AppColors.warning : AppColors.success,
              subtitle: summary.lowStockItems > 0 ? 'Needs attention' : 'All good',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: "Quick Actions",
          subtitle: "Common shop operations",
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
              icon: Icons.point_of_sale_rounded,
              title: 'Point of Sale',
              subtitle: 'Process transactions',
              gradient: [AppColors.primary.shade400, AppColors.primary.shade600],
              onTap: () => Get.toNamed(Routes.SHOP_POS),
            ),
            _buildActionCard(
              icon: Icons.inventory_2_rounded,
              title: 'Inventory',
              subtitle: 'Manage stock levels',
              gradient: [AppColors.warning.shade400, AppColors.warning.shade600],
              onTap: () => Get.toNamed(Routes.SHOP_INVENTORY),
            ),
            _buildActionCard(
              icon: Icons.people_rounded,
              title: 'Customers',
              subtitle: 'View customer list',
              gradient: [AppColors.secondary.shade400, AppColors.secondary.shade600],
              onTap: () => Get.toNamed(Routes.SHOP_CUSTOMERS),
            ),
            _buildActionCard(
              icon: Icons.shopping_bag_rounded,
              title: 'Products',
              subtitle: 'Browse products',
              gradient: [AppColors.success.shade400, AppColors.success.shade600],
              onTap: () => Get.toNamed(Routes.SHOP_ITEMS),
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
}