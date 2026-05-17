import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/modules/public/widgets/public_premium_shell.dart';
import 'package:smart_retail/app/modules/public/widgets/public_website_header.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class IntroView extends StatelessWidget {
  const IntroView({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PublicPremiumShell(
        baseColor: const Color(0xFFF7FAFC),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 42 : 18,
                  28,
                  isWide ? 42 : 18,
                  30,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D1B2A),
                      Color(0xFF102A43),
                      Color(0xFF0B7285),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PublicWebsiteHeader(
                      currentRoute: Routes.CUSTOMER_INTRO,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome to NanoNux Business Central',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: isWide ? 52 : 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Streamline operations, manage inventory, and grow sales with one connected retail platform.',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 42 : 18,
                  vertical: 26,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => Get.toNamed(Routes.LOGIN),
                          icon: const Icon(Icons.business_center_rounded),
                          label: const Text('Merchant Login / Register'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0B7285),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(Routes.SHOP_LOGIN),
                          icon: const Icon(Icons.storefront_rounded),
                          label: const Text('Shop Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0B7285),
                            side: const BorderSide(color: Color(0xFF0B7285)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(Routes.STAFF_LOGIN),
                          icon: const Icon(Icons.groups_2_outlined),
                          label: const Text('Staff Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF364FC7),
                            side: const BorderSide(color: Color(0xFF364FC7)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(Routes.ADMIN_LOGIN),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Admin Login'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF102A43),
                            side: const BorderSide(color: Color(0xFF102A43)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
