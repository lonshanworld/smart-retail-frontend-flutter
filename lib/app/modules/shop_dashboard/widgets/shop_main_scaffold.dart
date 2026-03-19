import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/data/models/shop_model.dart';
import 'package:smart_retail/app/data/models/user_model.dart';
import 'package:smart_retail/app/data/services/auth_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import 'package:smart_retail/app/widgets/app_colors.dart';

class ShopMainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const ShopMainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<ShopMainScaffold> createState() => _ShopMainScaffoldState();
}

class _ShopMainScaffoldState extends State<ShopMainScaffold> {
  final AuthService _authService = Get.find<AuthService>();

  final List<Map<String, dynamic>> _allShopNavItems = [
    {
      'route': Routes.SHOP_DASHBOARD,
      'label': 'Dashboard',
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard,
    },
    {
      'route': Routes.SHOP_SALES,
      'label': 'Sales',
      'icon': Icons.receipt_long_outlined,
      'selectedIcon': Icons.receipt_long,
    },
    {
      'route': Routes.SHOP_INVOICES,
      'label': 'Invoices',
      'icon': Icons.receipt_long_outlined,
      'selectedIcon': Icons.receipt_long,
    },
    // {
    //   'route': Routes.SHOP_INVENTORY,
    //   'label': 'Inventory',
    //   'icon': Icons.inventory_2_outlined,
    //   'selectedIcon': Icons.inventory_2,
    // },
    {
      'route': Routes.SHOP_ITEMS,
      'label': 'Items',
      'icon': Icons.list_alt_outlined,
      'selectedIcon': Icons.list_alt,
    },
    {
      'route': Routes.SHOP_POS,
      'label': 'POS',
      'icon': Icons.point_of_sale_outlined,
      'selectedIcon': Icons.point_of_sale,
    },
    {
      'route': Routes.SHOP_CUSTOMERS,
      'label': 'Customers',
      'icon': Icons.people_outline,
      'selectedIcon': Icons.people,
    },
    {
      'route': Routes.SHOP_SUPPORT,
      'label': 'Support',
      'icon': Icons.support_agent_outlined,
      'selectedIcon': Icons.support_agent,
    },
    {
      'route': Routes.SHOP_PROFILE,
      'label': 'Profile',
      'icon': Icons.person_outline,
      'selectedIcon': Icons.person,
    },
    {
      'route': Routes.SHOP_SETTINGS,
      'label': 'Settings',
      'icon': Icons.settings_outlined,
      'selectedIcon': Icons.settings,
    },
  ];

  /// Get filtered nav items based on user role
  List<Map<String, dynamic>> get _shopNavItems {
    final userRole = _authService.user.value?.role;

    // Hide Inventory for staff users
    if (userRole == 'staff') {
      return _allShopNavItems
          .where((item) => item['route'] != Routes.SHOP_INVENTORY)
          .toList();
    }

    return _allShopNavItems;
  }

  int _calculateSelectedIndex() {
    final String currentRoute = Get.currentRoute;
    int index = _shopNavItems.indexWhere(
      (item) => currentRoute.startsWith(item['route']!),
    );
    return index > -1 ? index : 0;
  }

  void _onDestinationSelected(int index, {bool fromDrawer = false}) {
    if (index >= 0 && index < _shopNavItems.length) {
      final String destinationRoute = _shopNavItems[index]['route']!;
      if (Get.currentRoute != destinationRoute) {
        // Preserve shopId parameter when navigating between shop pages
        final String? shopId = Get.parameters['shopId'];
        if (shopId != null && shopId.isNotEmpty) {
          Get.offAllNamed(destinationRoute, parameters: {'shopId': shopId});
        } else {
          Get.offAllNamed(destinationRoute);
        }
      }
      if (fromDrawer && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    Get.offAllNamed(Routes.SHOP_LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    const double webBreakpoint = 720.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < webBreakpoint;
        return Scaffold(
          appBar: isMobile
              ? AppBar(
                  title: Text(widget.title),
                  backgroundColor: AppColors.shop,
                  foregroundColor: Colors.white,
                  elevation: 0,
                )
              : null,
          drawer: isMobile ? _buildModernDrawer() : null,
          floatingActionButton: widget.floatingActionButton,
          floatingActionButtonLocation: widget.floatingActionButtonLocation,
          body: isMobile
              ? widget.body
              : Row(
                  children: <Widget>[
                    _buildModernSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          // Modern app bar for desktop
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.shop.shade900,
                                  ),
                                ),
                                const Spacer(),
                                // User profile badge
                                Obx(() {
                                  final User? user = _authService.user.value;
                                  final Shop? shop =
                                      _authService.currentShop.value;
                                  if (user == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.shop.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.shop,
                                          child: Text(
                                            shop != null && shop.name.isNotEmpty
                                                ? shop.name[0].toUpperCase()
                                                : user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (shop != null)
                                              Text(
                                                shop.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.shop.shade900,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            Text(
                                              user.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.shop.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: Colors.grey.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: widget.body,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildModernSidebar() {
    final int selectedIndex = _calculateSelectedIndex();
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.shop.shade700, AppColors.shop.shade900],
        ),
      ),
      child: Column(
        children: [
          // Logo and brand
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 32,
                    color: AppColors.shop,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final Shop? shop = _authService.currentShop.value;
                  return Column(
                    children: [
                      Text(
                        shop?.name ?? 'Shop Portal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart Retail System',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _shopNavItems.length,
              itemBuilder: (context, index) {
                final item = _shopNavItems[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item['selectedIcon'] : item['icon'],
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['label'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // User profile and logout
          const Divider(color: Colors.white24, height: 1),
          _buildSidebarUserProfile(),
        ],
      ),
    );
  }

  Widget _buildSidebarUserProfile() {
    return Obx(() {
      final User? user = _authService.user.value;
      if (user == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                    style: TextStyle(
                      color: AppColors.shop,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildModernDrawer() {
    final int selectedIndex = _calculateSelectedIndex();
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.shop.shade700, AppColors.shop.shade900],
          ),
        ),
        child: Column(
          children: [
            // Logo and brand
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 32,
                      color: AppColors.shop,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final Shop? shop = _authService.currentShop.value;
                    return Text(
                      shop?.name ?? 'Shop Portal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            // Navigation items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _shopNavItems.length,
                itemBuilder: (context, index) {
                  final item = _shopNavItems[index];
                  final isSelected = selectedIndex == index;
                  return ListTile(
                    leading: Icon(
                      isSelected ? item['selectedIcon'] : item['icon'],
                      color: Colors.white,
                    ),
                    title: Text(
                      item['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () =>
                        _onDestinationSelected(index, fromDrawer: true),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            _buildSidebarUserProfile(),
          ],
        ),
      ),
    );
  }
}

