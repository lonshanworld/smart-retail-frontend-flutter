import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/core/config/public_contact_config.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class PublicContactView extends StatelessWidget {
  const PublicContactView({super.key});

  static const Color _ink = Color(0xFF102A43);
  static const Color _ocean = Color(0xFF0B7285);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 28, isWide ? 42 : 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF102A43), Color(0xFF0B7285)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.CUSTOMER_INTRO),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(Routes.PUBLIC_SUPPORT),
                        icon: const Icon(Icons.support_agent_outlined),
                        label: const Text('Support Center'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Contact Smart Retail',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: isWide ? 48 : 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reach sales, implementation, or support through direct email and Telegram channels.',
                    style: GoogleFonts.manrope(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reach Us Now',
                    style: GoogleFonts.playfairDisplay(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: PublicContactLauncher.openContactEmail,
                        icon: const Icon(Icons.email_outlined),
                        label: Text(PublicContactConfig.contactEmail),
                        style: FilledButton.styleFrom(backgroundColor: _ocean, foregroundColor: Colors.white),
                      ),
                      FilledButton.icon(
                        onPressed: PublicContactLauncher.openSupportEmail,
                        icon: const Icon(Icons.support_agent_outlined),
                        label: Text(PublicContactConfig.supportEmail),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B7285), foregroundColor: Colors.white),
                      ),
                      FilledButton.icon(
                        onPressed: PublicContactLauncher.openTelegramSupport,
                        icon: const Icon(Icons.telegram),
                        label: Text('@${PublicContactConfig.telegramUsername}'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF229ED9), foregroundColor: Colors.white),
                      ),
                      FilledButton.icon(
                        onPressed: PublicContactLauncher.openTelegramBot,
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: Text('@${PublicContactConfig.telegramBotUsername} bot'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF364FC7), foregroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: PublicContactLauncher.openPhone,
                        icon: const Icon(Icons.phone_outlined),
                        label: Text(PublicContactConfig.contactPhone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _ContactLine(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'Best for issue reporting with screenshots and detailed context.',
                  ),
                  const _ContactLine(
                    icon: Icons.telegram,
                    title: 'Telegram Support',
                    subtitle: 'Best for fast response during support hours.',
                  ),
                  const _ContactLine(
                    icon: Icons.smart_toy_outlined,
                    title: 'Telegram Bot',
                    subtitle: 'Best for quick triage, ticket links, and status checks before human follow-up.',
                  ),
                  const _ContactLine(
                    icon: Icons.schedule_outlined,
                    title: 'Coverage',
                    subtitle: 'Monday-Friday with UTC-aligned support windows.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PublicContactView._ocean),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: PublicContactView._ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF486581),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
