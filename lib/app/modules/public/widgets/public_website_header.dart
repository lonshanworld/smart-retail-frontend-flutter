import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class PublicWebsiteHeader extends StatelessWidget {
  const PublicWebsiteHeader({super.key, required this.currentRoute});

  final String currentRoute;

  bool _isActive(String route) => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    return Column(
      children: [
        if (isWide)
          Row(
            children: [
              const _Brand(),
              const Spacer(),
              Wrap(
                spacing: 22,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _NavLink(
                    label: 'Home',
                    active: _isActive(Routes.CUSTOMER_INTRO),
                    onTap: () => Get.offAllNamed(Routes.CUSTOMER_INTRO),
                  ),
                  _NavLink(
                    label: 'Features',
                    active: _isActive(Routes.PUBLIC_FEATURES),
                    onTap: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                  ),
                  _NavLink(
                    label: 'About',
                    active: _isActive(Routes.PUBLIC_ABOUT),
                    onTap: () => Get.toNamed(Routes.PUBLIC_ABOUT),
                  ),
                  _NavLink(
                    label: 'Support',
                    active: _isActive(Routes.PUBLIC_SUPPORT),
                    onTap: () => Get.toNamed(Routes.PUBLIC_SUPPORT),
                  ),
                  _NavLink(
                    label: 'Contact',
                    active: _isActive(Routes.PUBLIC_CONTACT),
                    onTap: () => Get.toNamed(Routes.PUBLIC_CONTACT),
                  ),
                ],
              ),
              const Spacer(),
              const _Ctas(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _Brand(),
                  const Spacer(),
                  const _Ctas(compact: true),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _NavLink(
                      label: 'Home',
                      active: _isActive(Routes.CUSTOMER_INTRO),
                      onTap: () => Get.offAllNamed(Routes.CUSTOMER_INTRO),
                    ),
                    const SizedBox(width: 18),
                    _NavLink(
                      label: 'Features',
                      active: _isActive(Routes.PUBLIC_FEATURES),
                      onTap: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                    ),
                    const SizedBox(width: 18),
                    _NavLink(
                      label: 'About',
                      active: _isActive(Routes.PUBLIC_ABOUT),
                      onTap: () => Get.toNamed(Routes.PUBLIC_ABOUT),
                    ),
                    const SizedBox(width: 18),
                    _NavLink(
                      label: 'Support',
                      active: _isActive(Routes.PUBLIC_SUPPORT),
                      onTap: () => Get.toNamed(Routes.PUBLIC_SUPPORT),
                    ),
                    const SizedBox(width: 18),
                    _NavLink(
                      label: 'Contact',
                      active: _isActive(Routes.PUBLIC_CONTACT),
                      onTap: () => Get.toNamed(Routes.PUBLIC_CONTACT),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withValues(alpha: 0.28), height: 1),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF2EC4B6), Color(0xFF5C7CFA)],
            ),
          ),
          child: const Icon(Icons.hub_outlined, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          'NanoNux',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Ctas extends StatelessWidget {
  const _Ctas({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return FilledButton(
        onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2EC4B6),
          foregroundColor: const Color(0xFF072A2E),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: const Text('Login'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => Get.toNamed(Routes.SHOP_LOGIN),
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: const Text('Shop'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        FilledButton.icon(
          onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
          icon: const Icon(Icons.business_center_rounded, size: 18),
          label: const Text('Merchant Login'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2EC4B6),
            foregroundColor: const Color(0xFF072A2E),
          ),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.onTap,
    required this.active,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active
                  ? const Color(0xFF2EC4B6)
                  : Colors.white.withValues(alpha: 0),
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.84),
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
