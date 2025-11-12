import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/modules/admin/dashboard/admin_dashboard_controller.dart';
import 'package:smart_retail/app/modules/admin/widgets/admin_main_scaffold.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/stat_card.dart';
import 'package:smart_retail/app/widgets/section_header.dart';
import 'package:smart_retail/app/widgets/responsive_layout.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminMainScaffold(
      title: 'Admin Dashboard',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.admin.shade50.withOpacity(0.3),
              Colors.white,
            ],
          ),
        ),
        child: Obx(() {
          if (controller.isLoadingSummary.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.summary.value == null) {
            return Center(
              child: ModernCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dashboard_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Dashboard Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Summary data is not available at the moment.',
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

          final summary = controller.summary.value!;
          final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

          return RefreshIndicator(
            onRefresh: () => controller.refreshDashboard(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Overview Section
                  const SectionHeader(
                    title: 'System Overview',
                    subtitle: 'Monitor platform statistics and health',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 16),
                  ResponsiveGrid(
                    children: [
                      StatCard(
                        icon: Icons.storefront_outlined,
                        title: 'Total Merchants',
                        value: summary.totalMerchants.toString(),
                        subtitle: '${summary.activeMerchants} active',
                        color: AppColors.merchant,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed(Routes.ADMIN_MERCHANTS),
                      ),
                      StatCard(
                        icon: Icons.badge_outlined,
                        title: 'Total Staff',
                        value: summary.totalStaff.toString(),
                        subtitle: '${summary.activeStaff} active',
                        color: AppColors.staff,
                      ),
                      StatCard(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Total Shops',
                        value: summary.totalShops.toString(),
                        subtitle: 'Across all merchants',
                        color: AppColors.shop,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Get.toNamed(Routes.ADMIN_SHOPS),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sales Performance Section
                  const SectionHeader(
                    title: 'Sales Performance',
                    subtitle: 'Revenue and transaction metrics',
                    icon: Icons.trending_up,
                  ),
                  const SizedBox(height: 16),
                  ResponsiveGrid(
                    children: [
                      GradientStatCard(
                        gradient: AppColors.successGradientColors,
                        icon: Icons.monetization_on_outlined,
                        title: 'Total Sales Value',
                        value: currencyFormatter.format(summary.totalSalesValue),
                        subtitle: 'All-time revenue',
                      ),
                      StatCard(
                        icon: Icons.today_outlined,
                        title: 'Sales Today',
                        value: currencyFormatter.format(summary.salesToday),
                        subtitle: 'Today\'s revenue',
                        color: AppColors.primary,
                      ),
                      StatCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transactions Today',
                        value: summary.transactionsToday.toString(),
                        subtitle: 'Completed transactions',
                        color: AppColors.staff,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions Section
                  const SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Manage platform resources',
                    icon: Icons.flash_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  ResponsiveGrid(
                    children: [
                      ModernCard(
                        gradient: AppColors.merchantGradient,
                        onTap: () => Get.toNamed(Routes.ADMIN_MERCHANTS),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Merchants',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage merchants',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ModernCard(
                        gradient: AppColors.shopGradient,
                        onTap: () => Get.toNamed(Routes.ADMIN_SHOPS),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.store_mall_directory_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shops',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage shops',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ModernCard(
                        gradient: AppColors.staffGradient,
                        onTap: () => Get.toNamed(Routes.ADMIN_STAFF),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Staff',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage staff members',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ModernCard(
                        gradient: AppColors.adminGradient,
                        onTap: () => Get.toNamed(Routes.ADMIN_ADMINS),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admins',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage administrators',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
