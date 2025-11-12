// lib/app/modules/admin/dashboard/views/admin_dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/modules/admin/dashboard/controllers/admin_dashboard_controller.dart';
import 'package:smart_retail/app/widgets/responsive_layout_builder.dart';
import 'package:smart_retail/app/modules/admin/dashboard/models/admin_dashboard_summary_model.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshDashboard(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${controller.errorMessage.value}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () => controller.fetchDashboardSummary(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer),
                  )
                ],
              ),
            ),
          );
        }

        if (controller.summaryData.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text('No dashboard data available.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Fetch Data'),
                    onPressed: () => controller.fetchDashboardSummary(),
                  )
                ],
              ),
            ),
          );
        }

        final summary = controller.summaryData.value!;

        return ResponsiveLayoutBuilder(
          mobile: (_) => _buildKpiGrid(context, summary, crossAxisCount: 2, isMobile: true),
          tablet: (_) => _buildKpiGrid(context, summary, crossAxisCount: 3),
          desktop: (_) => _buildKpiGrid(context, summary, crossAxisCount: 4, mainAxisSpacing: 24, crossAxisSpacing: 24, padding: const EdgeInsets.all(24)),
        );
      }),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    AdminDashboardSummaryModel summary, {
    required int crossAxisCount,
    double mainAxisSpacing = 16.0,
    double crossAxisSpacing = 16.0,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    bool isMobile = false,
  }) {
    final kpiData = [
      _KpiItemData('Active Merchants', summary.totalActiveMerchants, Icons.storefront_outlined, Colors.blue),
      _KpiItemData('Active Staff', summary.totalActiveStaff, Icons.people_alt_outlined, Colors.green),
      _KpiItemData('Active Shops', summary.totalActiveShops, Icons.store_mall_directory_outlined, Colors.orange),
      _KpiItemData('Products Listed', summary.totalProductsListed, Icons.inventory_2_outlined, Colors.purple),
    ];

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: isMobile ? 1.8 : 2.2,
      ),
      itemCount: kpiData.length,
      itemBuilder: (context, index) {
        return _KpiCard(data: kpiData[index]);
      },
    );
  }
}

class _KpiItemData {
  final String title;
  final int value;
  final IconData icon;
  final MaterialColor color; // <<< CHANGED TO MaterialColor

  _KpiItemData(this.title, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiItemData data;

  const _KpiCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    data.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? data.color.shade200 : data.color.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(data.icon, size: 28.0, color: data.color),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${data.value}',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
