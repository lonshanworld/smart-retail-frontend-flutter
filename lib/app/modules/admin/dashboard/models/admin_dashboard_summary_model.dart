
// lib/app/modules/admin/dashboard/models/admin_dashboard_summary_model.dart
class AdminDashboardSummaryModel {
  final int totalActiveMerchants;
  final int totalActiveStaff;
  final int totalActiveShops;
  final int totalProductsListed;

  AdminDashboardSummaryModel({
    this.totalActiveMerchants = 0,
    this.totalActiveStaff = 0,
    this.totalActiveShops = 0,
    this.totalProductsListed = 0,
  });

  factory AdminDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummaryModel(
      totalActiveMerchants: json['total_active_merchants'] ?? 0,
      totalActiveStaff: json['total_active_staff'] ?? 0,
      totalActiveShops: json['total_active_shops'] ?? 0,
      totalProductsListed: json['total_products_listed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_active_merchants': totalActiveMerchants,
      'total_active_staff': totalActiveStaff,
      'total_active_shops': totalActiveShops,
      'total_products_listed': totalProductsListed,
    };
  }
}
