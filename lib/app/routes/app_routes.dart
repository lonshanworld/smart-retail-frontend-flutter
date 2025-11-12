part of 'app_pages.dart';

abstract class Routes {
  static const INTRO = '/intro'; // This will be dynamic based on portal type
  static const ADMIN_INTRO = '/admin-intro';
  static const CUSTOMER_INTRO = '/customer-intro';
  static const LOGIN = '/login';
  static const MERCHANT_LOGIN = '/merchant/login';
  static const ADMIN_LOGIN = '/admin/login';
  static const STAFF_LOGIN = '/staff/login';
  static const SHOP_LOGIN = '/shop/login';

  // Merchant Routes
  static const MERCHANT_DASHBOARD = '/merchant/dashboard';
  static const MERCHANT_INVENTORY = '/merchant/inventory';
  static const MERCHANT_STOCKS = '/merchant/stocks';
  static const MERCHANT_STOCK_MOVE = '/merchant/stock-move';
  static const MERCHANT_INVENTORY_ADD = '/merchant/inventory/add';
  static const MERCHANT_INVENTORY_EDIT = '/merchant/inventory/edit';
  static const MERCHANT_SUPPLIERS = '/merchant/suppliers';
  static const MERCHANT_SHOPS = '/merchant/shops';
  static const MERCHANT_SHOPS_ADD_EDIT = '/merchant/shops/add-edit';
  static const MERCHANT_SHOP_INVENTORY = '/merchant/shop-inventory';
  static const MERCHANT_SHOP_STOCK_IN = '/merchant/shop-stock-in';
  static const MERCHANT_SHOP_STOCK_ADJUST = '/merchant/shop-stock/adjust';
  static const MERCHANT_SALE_DETAIL = '/merchant/sale-detail';
  static const MERCHANT_PROMOTIONS = '/merchant/promotions';
  static const MERCHANT_PROMOTIONS_ADD = '/merchant/promotions/add';
  static const MERCHANT_PROMOTIONS_EDIT = '/merchant/promotions/edit';
  static const MERCHANT_STAFF = '/merchant/staff';
  static const MERCHANT_STAFF_ADD = '/merchant/staff/add';
  static const MERCHANT_STAFF_EDIT = '/merchant/staff/edit';
  static const MERCHANT_STAFF_DETAIL = '/merchant/staff/detail';
  static const MERCHANT_POS = '/merchant/pos';
  static const MERCHANT_REPORTS = '/merchant/reports';
  static const MERCHANT_AI_SALES_ANALYSIS = '/merchant/ai-sales-analysis';
  static const MERCHANT_NOTIFICATIONS = '/merchant/notifications';
  static const MERCHANT_PROFILE = '/merchant/profile';
  static const MERCHANT_SETTINGS = '/merchant/settings';
  static const MERCHANT_PRINTER_SETTINGS = '/merchant/settings/printer';
  static const CHECKOUT_SUCCESS = '/checkout-success';

  // Staff Routes
  static const STAFF_DASHBOARD = '/staff/dashboard';
  static const STAFF_PROFILE = '/staff/profile';
  static const STAFF_SALARY = '/staff/salary';
  static const STAFF_STOCK_IN_FORM = '/staff/stock-in-form';
  static const STAFF_SETTINGS = '/staff/settings';
  static const STAFF_PRINTER_SETTINGS = '/staff/settings/printer';
  static const STAFF_SHOP = '/staff/shop'; // ADDED
  static const STAFF_INVENTORY = '/staff/inventory'; // ADDED
  static const STAFF_ITEMS = '/staff/items'; // ADDED
  static const STAFF_POS = '/staff/pos'; // ADDED

  // Shop Dashboard Routes
  static const SHOP_DASHBOARD = '/shop/dashboard';
  static const SHOP_SALES = '/shop/sales';
  static const SHOP_INVENTORY = '/shop/inventory';
  static const SHOP_ITEMS = '/shop/items';
  static const SHOP_POS = '/shop/pos';
  static const SHOP_CUSTOMERS = '/shop/customers';
  static const SHOP_PROFILE = '/shop/profile';
  static const SHOP_SETTINGS = '/shop/settings';
  static const SHOP_PRINTER_SETTINGS = '/shop/settings/printer';

  // Admin Routes
  static const ADMIN_DASHBOARD = '/admin/dashboard';
  static const ADMIN_USERS = '/admin/users';
  static const ADMIN_ADD_EDIT_USER = '/admin/users/add-edit';
  static const ADMIN_USER_DETAIL = '/admin/users/detail';
  static const ADMIN_EDIT_USER = '/admin/users/edit';
  static const ADMIN_SHOPS = '/admin/shops';
  static const ADMIN_ADD_EDIT_SHOP = '/admin/shops/add-edit';
  static const ADMIN_SHOP_DETAIL = '/admin/shops/detail';
  static const ADMIN_MERCHANTS = '/admin/merchants';
  static const ADMIN_ADD_EDIT_MERCHANT = '/admin/merchants/add-edit';
  static const ADMIN_MERCHANT_DETAIL = '/admin/merchants/detail';
  static const ADMIN_ADMINS = '/admin/admins';
  static const ADMIN_STAFF = '/admin/staff';
  static const ADMIN_PROFILE = '/admin/profile';
  static const ADMIN_SETTINGS = '/admin/settings';
}
