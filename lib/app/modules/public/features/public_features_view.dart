import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/modules/public/widgets/public_premium_shell.dart';
import 'package:smart_retail/app/modules/public/widgets/public_website_header.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class PublicFeaturesView extends StatelessWidget {
  const PublicFeaturesView({super.key});

  static const Color _ink = Color(0xFF102A43);
  static const Color _ocean = Color(0xFF0B7285);
  static const Color _paper = Color(0xFFF7FAFC);
  static const Color _midnight = Color(0xFF0D1B2A);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PublicPremiumShell(
        baseColor: _paper,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(isWide)),
            SliverToBoxAdapter(
              child: _RevealOnLoad(delay: 40, child: _overview(isWide)),
            ),
            SliverToBoxAdapter(
              child: _RevealOnLoad(
                delay: 90,
                child: _roleSection(
                  isWide: isWide,
                  title: 'Merchant Features',
                  subtitle: 'Command center for growth and operations.',
                  icon: Icons.storefront_rounded,
                  points: const [
                    'Live dashboard across sales, stock, and cashflow',
                    'Inventory and supplier management in one workflow',
                    'Promotion engine with campaign-level controls',
                    'Cross-shop stock transfers and low-stock alerts',
                    'Invoices, reporting, and AI-assisted analysis',
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RevealOnLoad(
                delay: 140,
                child: _roleSection(
                  isWide: isWide,
                  title: 'Staff Features',
                  subtitle: 'Execution-first experience for front-line teams.',
                  icon: Icons.groups_2_outlined,
                  points: const [
                    'Fast POS with clear basket and payment interactions',
                    'Stock-in, stock adjustments, and product lookup tools',
                    'Daily task flow optimized for minimal training time',
                    'Invoice access and shift-friendly productivity tools',
                    'Consistent UX built for speed and fewer mistakes',
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RevealOnLoad(
                delay: 190,
                child: _roleSection(
                  isWide: isWide,
                  title: 'Shop Features',
                  subtitle:
                      'Focused control for branch-level retail operations.',
                  icon: Icons.point_of_sale_rounded,
                  points: const [
                    'Branch dashboard with sales, customer, and item signals',
                    'Shop inventory, item catalog, and checkout operations',
                    'Customer and invoice views designed for shop context',
                    'Clear role-based access aligned with headquarters policy',
                    'Connected data sync with merchant-level reporting',
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _RevealOnLoad(delay: 240, child: _cta(isWide)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 26, isWide ? 42 : 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF102A43), Color(0xFF0B7285)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PublicWebsiteHeader(currentRoute: Routes.PUBLIC_FEATURES),
          const SizedBox(height: 18),
          Text(
            'Feature Deep Dive',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: isWide ? 48 : 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A premium look at what each operational team can do inside NanoNux Business Central.',
            style: GoogleFonts.manrope(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E2EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'NanoNux Business Central is intentionally role-specific. Merchant, Staff, and Shop modules are designed around different decisions, while sharing one connected operational dataset.',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: const Color(0xFF334E68),
              height: 1.65,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleSection({
    required bool isWide,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> points,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF4FBFC)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: _ocean),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF486581),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: points
                    .map((point) => _FeatureBullet(text: point))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cta(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 20, isWide ? 42 : 18, 30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _midnight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            children: [
              const SizedBox(
                width: 540,
                child: Text(
                  'Ready to experience NanoNux Business Central workflows live? Choose your portal and start with the role that matches your team.',
                  style: TextStyle(
                    color: Color(0xFFDBE7F0),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Merchant'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Get.toNamed(Routes.STAFF_LOGIN),
                    icon: const Icon(Icons.groups_2_outlined),
                    label: const Text('Staff'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Get.toNamed(Routes.SHOP_LOGIN),
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Shop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC9E3E8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF0B7285),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                color: const Color(0xFF243B53),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealOnLoad extends StatelessWidget {
  const _RevealOnLoad({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 620 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
