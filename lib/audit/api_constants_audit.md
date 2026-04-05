# ApiConstants.baseUrl Audit

Generated: 2026-03-20

Summary: this report lists files that reference `ApiConstants.baseUrl` (found in a previous repo scan) and a quick status indicating whether a local-only check (`_appConfig.localStorageOnly` / `AppConfig.localStorageOnly`) or usage of `LocalDatabaseService` was detected nearby. "Has local-only check" means the file contains code paths that already guard or short-circuit when local-only is enabled. "Needs local fallback" means no clear local branch was found during the scan and the file should be reviewed/modified to either use `LocalDatabaseService` or queue operations when `localStorageOnly` is true.

- lib/app/data/services/admin_admins_api_service.dart — Needs local fallback
- lib/app/data/services/admin_merchant_service.dart — Needs local fallback
- lib/app/data/services/admin_dashboard_service.dart — Needs local fallback (contains direct GETs to admin dashboard endpoints)
- lib/app/data/services/admin_profile_api_service.dart — Needs local fallback
- lib/app/data/services/admin_staff_api_service.dart — Needs local fallback
- lib/app/data/services/admin_user_service.dart — Has local-only checks (file contains `_appConfig.localStorageOnly` branches)
- lib/app/data/services/auth_service.dart — Has local-only checks (login/signup flows have local branches)
- lib/app/services/admin_api_service.dart — Needs local fallback
- lib/app/services/offline_sales_service.dart — Has local-only checks (queues or short-circuits when local-only)
- lib/app/services/safe_get_connect.dart — N/A (guarded client registered)
- lib/app/services/sync_service.dart — Has local-only checks (sync methods respect OfflineModeManager.localStorageOnly)
- lib/app/data/services/inventory_api_service.dart — Needs local fallback
- lib/app/data/services/customer_api_service.dart — Has local-only checks (early returns when localStorageOnly)
- lib/app/data/services/invoice_api_service.dart — Has local-only checks (list/get/getBySaleId short-circuits present)
- lib/app/data/services/merchant_profile_api_service.dart — Needs local fallback
- lib/app/data/services/merchant_shops_api_service.dart — Needs local fallback
- lib/app/data/services/merchant_staff_api_service.dart — Needs local fallback
- lib/app/modules/login/signup_view.dart — Has been patched with a local-only signup fallback
- lib/app/data/services/merchant_stocks_api_service.dart — Needs local fallback
- lib/app/data/services/notification_api_service.dart — Needs local fallback
- lib/app/data/services/payment_api_service.dart — Has local-only checks (some branches present; verify for all mutation endpoints)
- lib/app/data/services/pos_api_service.dart — Needs local fallback
- lib/app/data/services/promotion_api_service.dart — Needs local fallback
- lib/app/data/services/public_ai_chat_service.dart — Needs local fallback / decision (AI chat may rely on public API)
- lib/app/data/services/report_api_service.dart — Needs local fallback
- lib/app/data/services/sales_analysis_api_service.dart — Needs local fallback
- lib/app/data/services/shop_api_service.dart — Needs local fallback
- lib/app/data/services/shop_customers_api_service.dart — Needs local fallback
- lib/app/data/services/shop_dashboard_api_service.dart — Needs local fallback
- lib/app/data/services/shop_inventory_api_service.dart — Needs local fallback
- lib/app/data/services/shop_items_api_service.dart — Needs local fallback (file contains LocalDatabaseService usage in some places; verify all endpoints)
- lib/app/data/services/shop_pos_api_service.dart — Has local-only checks (checkout & promotions short-circuited to LocalDatabaseService)
- lib/app/data/services/shop_sales_api_service.dart — Needs local fallback
- lib/app/data/services/shop_support_api_service.dart — Needs local fallback
- lib/app/data/services/staff_api_service.dart — Needs local fallback
- lib/app/data/services/staff_inventory_api_service.dart — Needs local fallback
- lib/app/data/services/staff_items_api_service.dart — Needs local fallback
- lib/app/data/services/staff_pos_api_service.dart — Needs local fallback
- lib/app/data/services/staff_profile_api_service.dart — Needs local fallback (contains direct GET to staff/profile)
- lib/app/data/services/stock_in_api_service.dart — Needs local fallback (stock-in POST exists in stock_in_service.dart; ensure local queue)
- lib/app/data/services/stock_in_service.dart — Has local-only handling implemented (now uses LocalDatabaseService upsert and addStockToShopLocal)
- lib/app/data/services/supplier_api_service.dart — Needs local fallback
- lib/app/data/services/user_api_service.dart — Partially has local DB usage (multiple Get.find<LocalDatabaseService>() calls); verify all methods


Next steps recommended:
- Prioritize implementing local-only short-circuits for: `shop_pos_api_service.dart` (checkout), `invoice_api_service.dart`, `stock_in_service.dart`, `payment_api_service.dart`, `sync_service.dart`, `offline_sales_service.dart`.
- For each file marked "Needs local fallback", implement one of:
  - Use `if (Get.find<AppConfig>().localStorageOnly) { /* call LocalDatabaseService / queue operation */ } else { /* existing network flow */ }`
  - Or ensure code uses `Get.find<GetConnect>()` so `SafeGetConnect` blocks network and surface clearer errors; preferred to add explicit local fallback rather than relying only on SafeGetConnect.
- Add unit tests / integration tests for the guarded flows where feasible.

Report generated automatically from repo scan. Manual review recommended for `public_ai_chat_service.dart` and any AI/third-party endpoints.
