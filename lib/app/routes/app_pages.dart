import 'package:get/get.dart';

// Import all the pages
import 'package:smart_retail/app/modules/intro/intro_view.dart';
import 'package:smart_retail/app/modules/admin_intro/admin_intro_view.dart';
import 'package:smart_retail/app/modules/customer_landing/customer_landing_view.dart';
import 'package:smart_retail/app/modules/login/login_view.dart';
import 'package:smart_retail/app/modules/login/login_binding.dart';
import 'package:smart_retail/app/modules/merchant/dashboard/merchant_dashboard_view.dart';
import 'package:smart_retail/app/modules/merchant/dashboard/merchant_dashboard_binding.dart';
import 'package:smart_retail/app/modules/merchant/stocks/merchant_stocks_view.dart';
import 'package:smart_retail/app/modules/merchant/stocks/merchant_stocks_binding.dart';
import 'package:smart_retail/app/modules/merchant/move_stock/move_stock_view.dart';
import 'package:smart_retail/app/modules/merchant/move_stock/move_stock_binding.dart';
import 'package:smart_retail/app/modules/merchant/inventory/add_item/add_inventory_item_view.dart';
import 'package:smart_retail/app/modules/merchant/inventory/add_item/add_inventory_item_binding.dart';
import 'package:smart_retail/app/modules/merchant/inventory/edit_item/edit_inventory_item_view.dart';
import 'package:smart_retail/app/modules/merchant/inventory/edit_item/edit_inventory_item_binding.dart';
import 'package:smart_retail/app/modules/merchant/supplier_management/supplier_management_view.dart';
import 'package:smart_retail/app/modules/merchant/supplier_management/supplier_management_binding.dart';
import 'package:smart_retail/app/modules/merchant/shops/shops_view.dart';
import 'package:smart_retail/app/modules/merchant/shops/shops_binding.dart';
import 'package:smart_retail/app/modules/merchant/shops/shop_add_edit_view.dart';
import 'package:smart_retail/app/modules/merchant/shops/shop_add_edit_binding.dart';
import 'package:smart_retail/app/modules/merchant/shops/shop_stock/adjust/shop_stock_adjust_view.dart';
import 'package:smart_retail/app/modules/merchant/shops/shop_stock/adjust/shop_stock_adjust_binding.dart';
import 'package:smart_retail/app/modules/shop_inventory/shop_inventory_view.dart';
import 'package:smart_retail/app/modules/shop_inventory/shop_inventory_binding.dart';
import 'package:smart_retail/app/modules/merchant/shop_inventory/merchant_shop_inventory_view.dart';
import 'package:smart_retail/app/modules/merchant/shop_inventory/merchant_shop_inventory_binding.dart';
import 'package:smart_retail/app/modules/merchant/stock_in/stock_in_view.dart';
import 'package:smart_retail/app/modules/merchant/stock_in/stock_in_binding.dart';
import 'package:smart_retail/app/modules/merchant/pos/pos_view.dart';
import 'package:smart_retail/app/modules/merchant/pos/pos_binding.dart';
import 'package:smart_retail/app/modules/merchant/sales_history/detail/sale_detail_view.dart';
import 'package:smart_retail/app/modules/merchant/sales_history/detail/sale_detail_binding.dart';
import 'package:smart_retail/app/modules/merchant/promotions/list/promotions_view.dart';
import 'package:smart_retail/app/modules/merchant/promotions/list/promotions_binding.dart';
import 'package:smart_retail/app/modules/merchant/promotions/add_edit/promotion_add_edit_view.dart';
import 'package:smart_retail/app/modules/merchant/promotions/add_edit/promotion_add_edit_binding.dart';
import 'package:smart_retail/app/modules/merchant/staff/list/merchant_staff_list_view.dart';
import 'package:smart_retail/app/modules/merchant/staff/list/merchant_staff_list_binding.dart';
import 'package:smart_retail/app/modules/merchant/staff/add_edit/staff_add_edit_view.dart';
import 'package:smart_retail/app/modules/merchant/staff/add_edit/staff_add_edit_binding.dart';
import 'package:smart_retail/app/modules/merchant/staff/detail/staff_detail_view.dart';
import 'package:smart_retail/app/modules/merchant/staff/detail/staff_detail_binding.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_view.dart';
import 'package:smart_retail/app/modules/merchant/reports/sales_analysis_binding.dart';
import 'package:smart_retail/app/modules/merchant/ai_sales_analysis/ai_sales_analysis_view.dart';
import 'package:smart_retail/app/modules/merchant/ai_sales_analysis/ai_sales_analysis_binding.dart';
import 'package:smart_retail/app/modules/merchant/notifications/notifications_view.dart';
import 'package:smart_retail/app/modules/merchant/notifications/notifications_binding.dart';
import 'package:smart_retail/app/modules/merchant/profile/merchant_profile_view.dart';
import 'package:smart_retail/app/modules/merchant/profile/merchant_profile_binding.dart';
import 'package:smart_retail/app/modules/merchant/settings/settings_view.dart';
import 'package:smart_retail/app/modules/merchant/settings/settings_binding.dart';
import 'package:smart_retail/app/modules/admin/dashboard/admin_dashboard_view.dart';
import 'package:smart_retail/app/modules/admin/dashboard/admin_dashboard_binding.dart';
import 'package:smart_retail/app/modules/admin/users/users_admin_view.dart';
import 'package:smart_retail/app/modules/admin/users/users_admin_binding.dart';
import 'package:smart_retail/app/modules/admin/users/detail/user_detail_admin_view.dart';
import 'package:smart_retail/app/modules/admin/users/detail/user_detail_admin_binding.dart';
import 'package:smart_retail/app/modules/admin/users/add_edit/add_edit_user_admin_view.dart';
import 'package:smart_retail/app/modules/admin/users/add_edit/add_edit_user_admin_binding.dart';
import 'package:smart_retail/app/modules/admin/shops/shops_admin_view.dart';
import 'package:smart_retail/app/modules/admin/shops/admin_shops_binding.dart';

import 'package:smart_retail/app/modules/admin/shops/detail/admin_shop_detail_view.dart';
import 'package:smart_retail/app/modules/admin/shops/detail/admin_shop_detail_binding.dart';
import 'package:smart_retail/app/modules/admin/merchants/admin_merchants_view.dart';
import 'package:smart_retail/app/modules/admin/merchants/admin_merchants_binding.dart';
import 'package:smart_retail/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_view.dart';
import 'package:smart_retail/app/modules/admin/merchants/add_edit_merchant/admin_add_edit_merchant_binding.dart';
import 'package:smart_retail/app/modules/admin/merchants/detail/admin_merchant_detail_view.dart';
import 'package:smart_retail/app/modules/admin/merchants/detail/admin_merchant_detail_binding.dart';
import 'package:smart_retail/app/modules/admin/admins/admins_admin_view.dart';
import 'package:smart_retail/app/modules/admin/admins/admins_admin_binding.dart';
import 'package:smart_retail/app/modules/admin/staff/admin_staff_view.dart';
import 'package:smart_retail/app/modules/admin/staff/admin_staff_binding.dart';
import 'package:smart_retail/app/modules/admin/profile/admin_profile_view.dart';
import 'package:smart_retail/app/modules/admin/profile/admin_profile_binding.dart';
import 'package:smart_retail/app/modules/admin/settings/settings_admin_view.dart';
import 'package:smart_retail/app/modules/staff_dashboard/staff_dashboard_view.dart';
import 'package:smart_retail/app/modules/staff_dashboard/staff_dashboard_binding.dart';
import 'package:smart_retail/app/modules/staff_profile/staff_profile_view.dart';
import 'package:smart_retail/app/modules/staff_profile/staff_profile_binding.dart';
import 'package:smart_retail/app/modules/staff_salary/staff_salary_view.dart';
import 'package:smart_retail/app/modules/staff_salary/staff_salary_binding.dart';
import 'package:smart_retail/app/modules/staff_settings/staff_settings_view.dart';
import 'package:smart_retail/app/modules/staff_settings/staff_settings_binding.dart';
import 'package:smart_retail/app/modules/settings_printer/printer_settings_view.dart';
import 'package:smart_retail/app/modules/settings_printer/printer_settings_binding.dart';

// Shop Dashboard Imports
import 'package:smart_retail/app/modules/shop_login/shop_login_view.dart';
import 'package:smart_retail/app/modules/shop_login/shop_login_binding.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_dashboard_view.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_dashboard_binding.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_sales/shop_sales_view.dart';
import 'package:smart_retail/app/modules/shop_dashboard/shop_sales/shop_sales_binding.dart';
import 'package:smart_retail/app/modules/shop_profile/shop_profile_view.dart';
import 'package:smart_retail/app/modules/shop_profile/shop_profile_binding.dart';
import 'package:smart_retail/app/modules/shop_items/shop_items_view.dart';
import 'package:smart_retail/app/modules/shop_items/shop_items_binding.dart';
import 'package:smart_retail/app/modules/shop_pos/shop_pos_view.dart';
import 'package:smart_retail/app/modules/shop_pos/shop_pos_binding.dart';
import 'package:smart_retail/app/modules/shop_customers/shop_customers_view.dart';
// CORRECTED: Import the new binding
import 'package:smart_retail/app/modules/shop_customers/shop_customers_binding.dart';
import 'package:smart_retail/app/modules/shop_settings/shop_settings_view.dart';
import 'package:smart_retail/app/modules/shop_settings/shop_settings_binding.dart';

import 'package:smart_retail/app/middlewares/auth_middleware.dart';
import 'package:smart_retail/app/data/enums/user_role.dart';

// ADDED: Staff page imports
import 'package:smart_retail/app/modules/staff_shop/staff_shop_view.dart';
import 'package:smart_retail/app/modules/staff_shop/staff_shop_binding.dart';
import 'package:smart_retail/app/modules/staff_inventory/staff_inventory_view.dart';
import 'package:smart_retail/app/modules/staff_inventory/staff_inventory_binding.dart';
import 'package:smart_retail/app/modules/staff_items/staff_items_view.dart';
import 'package:smart_retail/app/modules/staff_items/staff_items_binding.dart';
import 'package:smart_retail/app/modules/staff_pos/staff_pos_view.dart';
import 'package:smart_retail/app/modules/staff_pos/staff_pos_binding.dart';

import 'package:smart_retail/app/modules/admin/shops/add_edit_shop/admin_add_edit_shop_view.dart';
import 'package:smart_retail/app/modules/admin/shops/add_edit_shop/admin_add_edit_shop_binding.dart';
import 'package:smart_retail/app/modules/login/signup_view.dart';
import 'package:smart_retail/app/modules/merchant/invoices/merchant_invoices_view.dart';
import 'package:smart_retail/app/modules/merchant/invoices/merchant_invoices_controller.dart';
import 'package:smart_retail/app/modules/merchant/invoices/invoice_detail_view.dart';
import 'package:smart_retail/app/modules/merchant/invoices/invoice_detail_controller.dart';
import 'package:smart_retail/app/modules/shop/invoices/shop_invoice_detail_view.dart';
import 'package:smart_retail/app/modules/staff/invoices/staff_invoice_detail_view.dart';
import 'package:smart_retail/app/modules/shop/invoices/shop_invoices_view.dart';
import 'package:smart_retail/app/modules/shop/invoices/shop_invoices_controller.dart';
import 'package:smart_retail/app/modules/staff/invoices/staff_invoices_view.dart';
import 'package:smart_retail/app/modules/staff/invoices/staff_invoices_controller.dart';

part 'app_routes.dart';

class AppPages {
  // Always start with customer landing page
  static const String INITIAL = Routes.CUSTOMER_INTRO;

  static final routes = [
    GetPage(name: Routes.INTRO, page: () => const IntroView()),
    GetPage(name: Routes.ADMIN_INTRO, page: () => const AdminIntroView()),
    GetPage(
      name: Routes.CUSTOMER_INTRO,
      page: () => const CustomerLandingView(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.MERCHANT_LOGIN,
      page: () => LoginView(loginType: 'merchant'),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.ADMIN_LOGIN,
      page: () => LoginView(loginType: 'admin'),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.STAFF_LOGIN,
      page: () => LoginView(loginType: 'staff'),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.SHOP_LOGIN,
      page: () => const ShopLoginView(),
      binding: ShopLoginBinding(),
    ),
    GetPage(
      name: Routes.MERCHANT_SIGNUP,
      page: () => const SignupView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.MERCHANT_INVOICES,
      page: () => const MerchantInvoicesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MerchantInvoicesController>(() => MerchantInvoicesController());
      }),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_INVOICE_DETAIL,
      page: () => const InvoiceDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InvoiceDetailController>(() => InvoiceDetailController());
      }),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),

    // Merchant Routes
    GetPage(
      name: Routes.MERCHANT_DASHBOARD,
      page: () => const MerchantDashboardView(),
      binding: MerchantDashboardBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_INVENTORY,
      page: () => const MerchantStocksView(),
      binding: MerchantStocksBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STOCKS,
      page: () => const MerchantStocksView(),
      binding: MerchantStocksBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STOCK_MOVE,
      page: () => const MoveStockView(),
      binding: MoveStockBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_INVENTORY_ADD,
      page: () => AddInventoryItemView(),
      binding: AddInventoryItemBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_INVENTORY_EDIT,
      page: () => EditInventoryItemView(),
      binding: EditInventoryItemBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SUPPLIERS,
      page: () => const SupplierManagementView(),
      binding: SupplierManagementBinding(),
      transition: Transition.native,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SHOPS,
      page: () => const ShopsView(),
      binding: ShopsBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SHOPS_ADD_EDIT,
      page: () => ShopAddEditView(),
      binding: ShopAddEditBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    // GetPage(
    //   name: Routes.MERCHANT_SHOP_INVENTORY,
    //   page: () => MoveStockView (),
    //   binding: ShopInventoryBinding(),
    //   transition: Transition.cupertino,
    //   middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    // ),
    GetPage(
      name: Routes.MERCHANT_SHOP_INVENTORY,
      page: () => const MerchantShopInventoryView(),
      binding: MerchantShopInventoryBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SHOP_STOCK_IN,
      page: () => const StockInView(),
      binding: StockInBinding(),
      transition: Transition.downToUp,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SHOP_STOCK_ADJUST,
      page: () => const ShopStockAdjustView(),
      binding: ShopStockAdjustBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.STAFF_STOCK_IN_FORM,
      page: () => const StockInView(),
      binding: StockInBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.MERCHANT_SALE_DETAIL,
      page: () => const SaleDetailView(),
      binding: SaleDetailBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_PROMOTIONS,
      page: () => const PromotionsView(),
      binding: PromotionsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_PROMOTIONS_ADD,
      page: () => const PromotionAddEditView(),
      binding: PromotionAddEditBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_PROMOTIONS_EDIT,
      page: () => const PromotionAddEditView(),
      binding: PromotionAddEditBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STAFF,
      page: () => const MerchantStaffListView(),
      binding: MerchantStaffListBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STAFF_ADD,
      page: () => const StaffAddEditView(),
      binding: StaffAddEditBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STAFF_EDIT,
      page: () => const StaffAddEditView(),
      binding: StaffAddEditBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_STAFF_DETAIL,
      page: () => const StaffDetailView(),
      binding: StaffDetailBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_POS,
      page: () => const PosView(),
      binding: PosBinding(),
      transition: Transition.zoom,
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_REPORTS,
      page: () => const SalesAnalysisView(),
      binding: SalesAnalysisBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_AI_SALES_ANALYSIS,
      page: () => const AiSalesAnalysisView(),
      binding: AiSalesAnalysisBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_PROFILE,
      page: () => const MerchantProfileView(),
      binding: MerchantProfileBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),
    GetPage(
      name: Routes.MERCHANT_PRINTER_SETTINGS,
      page: () => const PrinterSettingsView(),
      binding: PrinterSettingsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.merchant)],
    ),

    // Staff Routes
    GetPage(
      name: Routes.STAFF_DASHBOARD,
      page: () => const StaffDashboardView(),
      binding: StaffDashboardBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_PROFILE,
      page: () => const StaffProfileView(),
      binding: StaffProfileBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_SALARY,
      page: () => const StaffSalaryView(),
      binding: StaffSalaryBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_SETTINGS,
      page: () => const StaffSettingsView(),
      binding: StaffSettingsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_PRINTER_SETTINGS,
      page: () => const PrinterSettingsView(),
      binding: PrinterSettingsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_SHOP,
      page: () => const StaffShopView(),
      binding: StaffShopBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_INVENTORY,
      page: () => const StaffInventoryView(),
      binding: StaffInventoryBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_ITEMS,
      page: () => const StaffItemsView(),
      binding: StaffItemsBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_POS,
      page: () => const StaffPosView(),
      binding: StaffPosBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_INVOICES,
      page: () => const StaffInvoicesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StaffInvoicesController>(() => StaffInvoicesController());
      }),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),
    GetPage(
      name: Routes.STAFF_INVOICE_DETAIL,
      page: () => const StaffInvoiceDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InvoiceDetailController>(() => InvoiceDetailController());
      }),
      middlewares: [AuthMiddleware(requiredRole: UserRole.staff)],
    ),

    // Shop Dashboard Routes
    GetPage(
      name: Routes.SHOP_DASHBOARD,
      page: () => const ShopDashboardView(),
      binding: ShopDashboardBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_SALES,
      page: () => const ShopSalesView(),
      binding: ShopSalesBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_INVENTORY,
      page: () => const ShopInventoryView(),
      binding: ShopInventoryBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_ITEMS,
      page: () => const ShopItemsView(),
      binding: ShopItemsBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_POS,
      page: () => const ShopPosView(),
      binding: ShopPosBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_CUSTOMERS,
      page: () => const ShopCustomersView(),
      // CORRECTED: Use the new binding
      binding: ShopCustomersBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_PROFILE,
      page: () => const ShopProfileView(),
      binding: ShopProfileBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_SETTINGS,
      page: () => const ShopSettingsView(),
      binding: ShopSettingsBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_PRINTER_SETTINGS,
      page: () => const PrinterSettingsView(),
      binding: PrinterSettingsBinding(),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_INVOICES,
      page: () => const ShopInvoicesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ShopInvoicesController>(() => ShopInvoicesController());
      }),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),
    GetPage(
      name: Routes.SHOP_INVOICE_DETAIL,
      page: () => const ShopInvoiceDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<InvoiceDetailController>(() => InvoiceDetailController());
      }),
      middlewares: [
        AuthMiddleware(requiredRoles: [UserRole.staff, UserRole.merchant]),
      ],
    ),

    // Admin Routes
    GetPage(
      name: Routes.ADMIN_DASHBOARD,
      page: () => const AdminDashboardView(),
      binding: AdminDashboardBinding(),
      transition: Transition.leftToRightWithFade,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_USERS,
      page: () => const UsersAdminView(),
      binding: UsersAdminBinding(),
      transition: Transition.native,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_ADD_EDIT_USER,
      page: () => const AddEditUserAdminView(),
      binding: AddEditUserAdminBinding(),
      transition: Transition.rightToLeftWithFade,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_USER_DETAIL,
      page: () => const UserDetailAdminView(),
      binding: UserDetailAdminBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    // GetPage(
    //   name: Routes.ADMIN_EDIT_USER,
    //   page: () => const UserEditAdminView(),
    //   binding: UserEditAdminBinding(),
    //   transition: Transition.rightToLeft,
    //   middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    // ),
    GetPage(
      name: Routes.ADMIN_SHOPS,
      page: () => const ShopsAdminView(),
      binding: AdminShopsBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_ADD_EDIT_SHOP,
      page: () => const AdminAddEditShopView(),
      binding: AdminAddEditShopBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_SHOP_DETAIL,
      page: () => const AdminShopDetailView(),
      binding: AdminShopDetailBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_MERCHANTS,
      page: () => const AdminMerchantsView(),
      binding: AdminMerchantsBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_ADD_EDIT_MERCHANT,
      page: () => const AdminAddEditMerchantView(),
      binding: AdminAddEditMerchantBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_MERCHANT_DETAIL,
      page: () => const AdminMerchantDetailView(),
      binding: AdminMerchantDetailBinding(),
      transition: Transition.cupertino,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_ADMINS,
      page: () => const AdminsAdminView(),
      binding: AdminsAdminBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_STAFF,
      page: () => const AdminStaffView(),
      binding: AdminStaffBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_PROFILE,
      page: () => const AdminProfileView(),
      binding: AdminProfileBinding(),
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
    GetPage(
      name: Routes.ADMIN_SETTINGS,
      page: () => const SettingsAdminView(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware(requiredRole: UserRole.admin)],
    ),
  ];
}
