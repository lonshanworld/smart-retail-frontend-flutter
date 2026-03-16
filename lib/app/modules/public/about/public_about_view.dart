import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class PublicAboutView extends StatelessWidget {
  const PublicAboutView({super.key});

  static const Color _ink = Color(0xFF102A43);
  static const Color _ocean = Color(0xFF0B7285);
  static const Color _paper = Color(0xFFF7FAFC);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: _paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _hero(isWide)),
          SliverToBoxAdapter(child: _story(isWide)),
          SliverToBoxAdapter(child: _values(isWide)),
          SliverToBoxAdapter(child: _actions(isWide)),
        ],
      ),
    );
  }

  Widget _hero(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 28, isWide ? 42 : 18, 26),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: Text('Back', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.offAllNamed(Routes.CUSTOMER_INTRO),
                icon: const Icon(Icons.home_outlined),
                label: Text('Home', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                icon: const Icon(Icons.auto_awesome_motion_outlined),
                label: Text('Features', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'About Smart Retail',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: isWide ? 50 : 38,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We build premium retail software that respects the speed of the store floor and the precision required by management.',
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

  Widget _story(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9E2EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Our Story',
                style: GoogleFonts.playfairDisplay(
                  color: _ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Smart Retail started from a simple observation: most retail teams juggle too many disconnected systems. We built one platform where merchant leadership, staff execution, and shop operations work in harmony.',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF334E68),
                  height: 1.7,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _values(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _ValueCard(
            icon: Icons.rocket_launch_outlined,
            title: 'Operational Speed',
            text: 'Interactions are crafted to reduce friction at peak store hours.',
          ),
          _ValueCard(
            icon: Icons.balance_outlined,
            title: 'Design + Utility',
            text: 'Premium visual language with practical, measurable outcomes.',
          ),
          _ValueCard(
            icon: Icons.account_tree_outlined,
            title: 'Unified Platform',
            text: 'Shared data across merchant, staff, and shop experiences.',
          ),
        ],
      ),
    );
  }

  Widget _actions(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 20, isWide ? 42 : 18, 30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE6F6F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            children: [
              Text(
                'Explore feature-level details or speak with our team.',
                style: GoogleFonts.manrope(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                    icon: const Icon(Icons.auto_awesome_motion_outlined),
                    label: const Text('See Features'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ocean,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(Routes.PUBLIC_CONTACT),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Contact Team'),
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

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: PublicAboutView._ocean),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: PublicAboutView._ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF486581),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
