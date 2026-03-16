import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_retail/app/data/models/staff_dashboard_model.dart';
import 'package:smart_retail/app/modules/staff_dashboard/staff_dashboard_controller.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/modules/staff_dashboard/widgets/staff_main_scaffold.dart';
import 'package:smart_retail/app/widgets/stat_card.dart';
import 'package:smart_retail/app/widgets/modern_card.dart';
import 'package:smart_retail/app/widgets/section_header.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';
import 'package:smart_retail/app/widgets/responsive_layout.dart';
import 'package:smart_retail/app/widgets/cards/data_sync_card.dart';

class StaffDashboardView extends GetView<StaffDashboardController> {
  const StaffDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return StaffMainScaffold(
      title: 'Dashboard',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.staff.shade50.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(100.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.hasError.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: ModernCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error.shade400,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : 'Failed to load dashboard data.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => controller.fetchDashboardSummary(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: AppColors.staff,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (controller.dashboardSummary.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: ModernCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning.shade400,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Data Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No dashboard data available at the moment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        onPressed: () => controller.fetchDashboardSummary(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: AppColors.staff,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final summary = controller.dashboardSummary.value!;

          return RefreshIndicator(
            onRefresh: () => controller.refreshDashboard(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildShopHeader(summary.assignedShopName),
                  const SizedBox(height: 24),
                  const DataSyncCard(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildPerformanceMetrics(summary),
                  const SizedBox(height: 32),
                  _buildRecentActivity(summary.recentActivities),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShopHeader(String shopName) {
    return ModernCard(
      gradient: LinearGradient(
        colors: AppColors.staffGradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.store_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Shop',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: "Quick Actions",
          subtitle: "Common tasks",
          icon: Icons.flash_on_rounded,
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
              gradient: [
                AppColors.primary.shade400,
                AppColors.primary.shade600,
              ],
              onTap: () => Get.toNamed(Routes.STAFF_POS),
            ),
            // _buildActionCard(
            //   icon: Icons.inventory_2_rounded,
            //   title: 'Inventory',
            //   subtitle: 'View stock levels',
            //   gradient: [
            //     AppColors.success.shade400,
            //     AppColors.success.shade600,
            //   ],
            //   onTap: () => Get.toNamed(Routes.STAFF_INVENTORY),
            // ),
            _buildActionCard(
              icon: Icons.receipt_long_rounded,
              title: 'Invoices',
              subtitle: 'View shop invoices',
              gradient: [
                AppColors.primary.shade400,
                AppColors.primary.shade600,
              ],
              onTap: () => Get.toNamed(Routes.STAFF_INVOICES),
            ),
            _buildActionCard(
              icon: Icons.print_rounded,
              title: 'Printer Settings',
              subtitle: 'Configure receipt printer',
              gradient: [
                AppColors.secondary.shade400,
                AppColors.secondary.shade600,
              ],
              onTap: () => Get.toNamed(Routes.STAFF_PRINTER_SETTINGS),
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
              color: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(StaffDashboardSummaryResponse summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: "Today's Performance",
          subtitle: "Your metrics",
          icon: Icons.analytics_rounded,
        ),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 2,
          spacing: 16,
          children: [
            GradientStatCard(
              title: 'Sales Today',
              value: NumberFormat.currency(
                locale: 'en_US',
                symbol: '\$',
              ).format(summary.salesToday),
              icon: Icons.attach_money_rounded,
              gradient: AppColors.successGradientColors,
            ),
            StatCard(
              title: 'Transactions Today',
              value: summary.transactionsToday.toString(),
              icon: Icons.receipt_long_rounded,
              color: AppColors.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List<ActivityItemDTO> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent Activity',
          subtitle: activities.isEmpty
              ? 'No activities yet'
              : '${activities.length} recent items',
          icon: Icons.history_rounded,
        ),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          ModernCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your activities will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ModernCard(
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: activity.type == 'sale'
                          ? AppColors.success.shade50
                          : AppColors.warning.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.type == 'sale'
                          ? Icons.receipt_rounded
                          : Icons.inventory_rounded,
                      color: activity.type == 'sale'
                          ? AppColors.success.shade600
                          : AppColors.warning.shade600,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    activity.details,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.yMMMd().add_jm().format(
                        activity.timestamp.toLocal(),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () {
                    if (activity.type == 'sale') {
                      Get.toNamed(
                        Routes.MERCHANT_SALE_DETAIL,
                        arguments: activity.relatedId,
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

