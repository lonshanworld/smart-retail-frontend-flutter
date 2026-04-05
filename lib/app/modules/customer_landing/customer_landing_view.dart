import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_retail/app/core/config/public_contact_config.dart';
import 'package:smart_retail/app/data/services/public_ai_chat_service.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class CustomerLandingView extends StatelessWidget {
  const CustomerLandingView({super.key});

  static const Color _ink = Color(0xFF102A43);
  static const Color _slate = Color(0xFF334E68);
  static const Color _paper = Color(0xFFF6F8FB);
  static const Color _midnight = Color(0xFF0D1B2A);
  static const Color _ocean = Color(0xFF0B7285);
  static const Color _line = Color(0xFFDCE5EE);
  static const Color _glass = Color(0xF2FFFFFF);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: _paper,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x332EC4B6), Color(0x002EC4B6)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 380,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x225C7CFA), Color(0x005C7CFA)],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _topBar(isWide)),
              SliverToBoxAdapter(child: _hero(isWide)),
              SliverToBoxAdapter(child: _trustRibbon(isWide)),
              SliverToBoxAdapter(child: _platformStorySection(isWide)),
              SliverToBoxAdapter(child: _valuePropositionSection(isWide)),
              SliverToBoxAdapter(child: _coreFeaturesSection(isWide)),
              SliverToBoxAdapter(child: _advancedCapabilitiesSection(isWide)),
              SliverToBoxAdapter(child: _multiRoleDetailSection(isWide)),
              SliverToBoxAdapter(child: _analyticsReportsSection(isWide)),
              SliverToBoxAdapter(child: _loginOptionsSection(isWide)),
              SliverToBoxAdapter(child: _statsSection(isWide)),
              SliverToBoxAdapter(child: _capabilityMatrixSection(isWide)),
              SliverToBoxAdapter(child: _dataVisualSection(isWide)),
              SliverToBoxAdapter(child: _roleWorkspaceSection(isWide)),
              SliverToBoxAdapter(child: _orchestrationSection(isWide)),
              SliverToBoxAdapter(child: _implementationSection(isWide)),
              SliverToBoxAdapter(child: _faqSection(isWide)),
              SliverToBoxAdapter(child: _testimonials(isWide)),
              SliverToBoxAdapter(child: _bottomCta(isWide)),
              SliverToBoxAdapter(child: _contactSection(isWide)),
              SliverToBoxAdapter(child: _footer(isWide)),
            ],
          ),
          const Positioned(
            right: 18,
            bottom: 18,
            child: _PublicAiChatFab(),
          ),
        ],
      ),
    );
  }

  Widget _topBar(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 14, 16, isWide ? 32 : 14, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF102A43), Color(0xFF0B7285)],
                      ),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Smart Retail Central',
                    style: GoogleFonts.playfairDisplay(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PillAction(
                    icon: Icons.auto_awesome_motion_outlined,
                    label: 'Features',
                    onTap: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                  ),
                  _PillAction(
                    icon: Icons.apartment_outlined,
                    label: 'About',
                    onTap: () => Get.toNamed(Routes.PUBLIC_ABOUT),
                  ),
                  _PillAction(
                    icon: Icons.support_agent_outlined,
                    label: 'Support',
                    onTap: () => Get.toNamed(Routes.PUBLIC_SUPPORT),
                  ),
                  _PillAction(
                    icon: Icons.alternate_email,
                    label: 'Contact',
                    onTap: () => Get.toNamed(Routes.PUBLIC_CONTACT),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 44, isWide ? 42 : 18, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF102A43), Color(0xFF0B7285)],
        ),
      ),
      child: _Reveal(
        delay: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    'Central commerce command system',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not Just POS.\nA Unified Operating Layer\nFor Modern Retail.',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: stacked ? 40 : 58,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Smart Retail connects leadership, staff execution, and branch operations in one synchronized system. Every workflow shares the same data heartbeat.',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: stacked ? 15 : 18,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _RoleButton(
                      label: 'Explore Full Features',
                      icon: Icons.auto_awesome_motion_outlined,
                      onTap: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                    ),
                    _RoleButton(
                      label: 'About Us',
                      icon: Icons.apartment_outlined,
                      onTap: () => Get.toNamed(Routes.PUBLIC_ABOUT),
                    ),
                    // _RoleButton(
                    //   label: 'Merchant Login',
                    //   icon: Icons.storefront_rounded,
                    //   onTap: () => Get.toNamed(Routes.MERCHANT_LOGIN),
                    // ),
                    FilledButton.icon(
                      onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
                      icon: const Icon(Icons.business_center_rounded),
                      label: const Text('Merchant Login'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
                    ),
                    FilledButton.icon(
                      onPressed: () => Get.toNamed(Routes.STAFF_LOGIN),
                      icon: const Icon(Icons.badge_rounded),
                      label: const Text('Staff Login'),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            );

            final right = Container(
              height: stacked ? 220 : 320,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: CustomPaint(
                painter: _SystemMapPainter(),
                child: const SizedBox.expand(),
              ),
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [left, const SizedBox(height: 16), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: right),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _trustRibbon(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 22),
      color: const Color(0xFFEAF5F8),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        children: const [
          _MetricText(label: '99.9%', value: 'Target platform uptime'),
          _MetricText(label: '< 2 min', value: 'Team onboarding flow'),
          _MetricText(label: 'Multi-role', value: 'Merchant, Staff, Shop, Admin'),
          _MetricText(label: 'Real-time', value: 'Unified operational data'),
        ],
      ),
    );
  }

  Widget _platformStorySection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Why This Platform Exists', 'Retail teams need one system that is elegant for leadership and practical for execution.'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 920;
              final narrative = Text(
                'Most businesses operate across disconnected tools: one for checkout, one for stock, one for reports, and another for payroll signals. Smart Retail removes that fragmentation by creating one operating layer where each role sees exactly what it needs while sharing the same data truth.\n\nThis means branch staff can move quickly, merchant leadership can make strategic decisions with confidence, and admins can govern the whole environment without data lag or duplicated effort.',
                style: GoogleFonts.manrope(
                  color: _slate,
                  fontSize: 15,
                  height: 1.8,
                ),
              );

              final lane = Column(
                children: const [
                  _RailStep(title: 'Transaction Capture', subtitle: 'Sales, stock movement, and customer records are logged instantly.'),
                  _RailStep(title: 'Cross-Role Sync', subtitle: 'The same event updates each workspace with role-relevant context.'),
                  _RailStep(title: 'Decision Layer', subtitle: 'Leaders receive clean trend signals for planning and optimization.'),
                  _RailStep(title: 'Continuous Improvement', subtitle: 'Promotions, pricing, staffing, and inventory can be tuned quickly.'),
                ],
              );

              if (stacked) {
                return Column(children: [narrative, const SizedBox(height: 12), lane]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: narrative),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: lane),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _capabilityMatrixSection(bool isWide) {
    final rows = [
      const _MatrixRow(
        feature: 'POS and Checkout',
        detail: 'Fast transaction flow with payment-state clarity and item-level detail.',
        merchant: true,
        staff: true,
        shop: true,
      ),
      const _MatrixRow(
        feature: 'Inventory Governance',
        detail: 'Master stock, low-stock signals, movement history, and supplier-aware control.',
        merchant: true,
        staff: true,
        shop: true,
      ),
      const _MatrixRow(
        feature: 'Promotion Intelligence',
        detail: 'Campaign controls that align discounts with margin and branch performance.',
        merchant: true,
        staff: false,
        shop: true,
      ),
      const _MatrixRow(
        feature: 'Cross-Branch Oversight',
        detail: 'Central visibility across locations with unified reporting structure.',
        merchant: true,
        staff: false,
        shop: false,
      ),
      const _MatrixRow(
        feature: 'Internal Governance',
        detail: 'Administrative ownership, role controls, and system-level supervision.',
        merchant: false,
        staff: false,
        shop: false,
        admin: true,
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 44, isWide ? 42 : 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Capability Matrix', 'A clear summary of which workspace drives each capability.'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(border: Border.all(color: _line)),
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFEDF2F7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _headerText('Capability')),
                      Expanded(flex: 5, child: _headerText('Operational Explanation')),
                      Expanded(child: _headerText('M')),
                      Expanded(child: _headerText('S')),
                      Expanded(child: _headerText('Sh')),
                      Expanded(child: _headerText('A')),
                    ],
                  ),
                ),
                ...rows,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valuePropositionSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 44, isWide ? 42 : 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Why Choose Smart Retail', 'Everything you need to run and grow a modern retail operation.'),
          const SizedBox(height: 12),
          const _RailStep(title: 'Lightning Fast', subtitle: 'Process transactions in seconds with an optimized POS workflow.'),
          const _RailStep(title: 'Secure and Reliable', subtitle: 'Bank-grade approach with offline continuity and dependable sync.'),
          const _RailStep(title: 'Growth Focused', subtitle: 'Use data-rich reporting and promotion control to grow revenue quality.'),
          const _RailStep(title: '24/7 Team Support', subtitle: 'Support channels are available through email and Telegram pathways.'),
        ],
      ),
    );
  }

  Widget _coreFeaturesSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Core Features', 'Powerful tools to run your retail business efficiently.'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 920;
              final pos = const _FeatureColumn(
                title: 'Point of Sale (POS)',
                subtitle: 'Fast, intuitive checkout with offline support and cloud sync.',
                bullets: [
                  'Quick product search and barcode scanning',
                  'Multiple payment methods support',
                  'Real-time promotion application',
                  'Instant receipt generation and sales history',
                ],
              );
              final inv = const _FeatureColumn(
                title: 'Inventory Management',
                subtitle: 'Complete control over stock with multi-location visibility.',
                bullets: [
                  'Real-time stock level monitoring',
                  'Low stock alerts and notifications',
                  'Stock transfer between shop locations',
                  'Supplier-linked product management',
                ],
              );
              if (stacked) {
                return Column(children: [pos, const SizedBox(height: 14), inv]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: pos),
                  const SizedBox(width: 14),
                  Expanded(child: inv),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _advancedCapabilitiesSection(bool isWide) {
    final features = const [
      'Customer management and purchase history',
      'Promotions and discount campaigns',
      'Supplier relationship workflows',
      'Multi-shop centralized control',
      'Stock transfer tracking',
      'Smart notifications for key events',
      'Offline-first data synchronization',
    ];
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 40, isWide ? 42 : 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Advanced Capabilities', 'Advanced tools that create a measurable operational edge.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: features
                .map((f) => SizedBox(
                      width: isWide ? 360 : double.infinity,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.arrow_right, color: _ocean, size: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              f,
                              style: GoogleFonts.manrope(
                                color: _slate,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _multiRoleDetailSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F213A),
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 44, isWide ? 42 : 18, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Built for Every Team Member',
            style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Role-based access and workflows tailored for every team member.',
            style: GoogleFonts.manrope(color: const Color(0xFFB7C6D6), height: 1.6),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 960;
              final merchant = const _DarkRoleDetail(
                title: 'Merchant',
                bullets: [
                  'Manage all shops and inventory',
                  'Staff management and controls',
                  'Complete financial reports',
                  'Supplier relationships and insights',
                ],
              );
              final shop = const _DarkRoleDetail(
                title: 'Shop',
                bullets: [
                  'Shop-level inventory operations',
                  'POS and customer workflows',
                  'Daily branch performance tracking',
                  'Stock request and execution',
                ],
              );
              final staff = const _DarkRoleDetail(
                title: 'Staff',
                bullets: [
                  'Checkout and basket execution',
                  'Product lookup and service flow',
                  'Stock updates and inventory actions',
                  'Sales and invoice handling',
                ],
              );
              if (stacked) {
                return Column(children: [merchant, const SizedBox(height: 12), shop, const SizedBox(height: 12), staff]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: merchant),
                  const SizedBox(width: 12),
                  Expanded(child: shop),
                  const SizedBox(width: 12),
                  Expanded(child: staff),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _analyticsReportsSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Data-Driven Insights', 'Make confident decisions with analytics and reporting.'),
          const SizedBox(height: 12),
          const _RailStep(title: 'Sales Reports', subtitle: 'Detailed sales analysis by date, product, shop, and staff with trend visibility.'),
          const _RailStep(title: 'Inventory Reports', subtitle: 'Track stock levels, movement, and valuation across all operating locations.'),
          const _RailStep(title: 'AI Analysis', subtitle: 'Use AI-supported sales insights for recommendations and proactive planning.'),
        ],
      ),
    );
  }

  Widget _loginOptionsSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF4FA),
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 42, isWide ? 42 : 18, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Get Started Today', 'Choose your role and start operating in minutes.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
                icon: const Icon(Icons.business_center_rounded),
                label: const Text('Merchant Login'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
              ),
              // FilledButton.icon(
              //   onPressed: () => Get.toNamed(Routes.SHOP_LOGIN),
              //   icon: const Icon(Icons.storefront_rounded),
              //   label: const Text('Shop Login'),
              //   style: FilledButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
              // ),
              FilledButton.icon(
                onPressed: () => Get.toNamed(Routes.STAFF_LOGIN),
                icon: const Icon(Icons.badge_rounded),
                label: const Text('Staff Login'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 36),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: const [
          _MetricText(label: '99.9%', value: 'Uptime'),
          _MetricText(label: '24/7', value: 'Support'),
          _MetricText(label: '100%', value: 'Secure'),
          _MetricText(label: 'Offline', value: 'Capable'),
          _MetricText(label: 'Cloud', value: 'Based'),
        ],
      ),
    );
  }

  Widget _dataVisualSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Operational Signal Layer', 'Visual snapshots of throughput rhythm and queue health.'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final trend = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Throughput Trend',
                    style: GoogleFonts.playfairDisplay(color: _ink, fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  AspectRatio(aspectRatio: 16 / 8, child: CustomPaint(painter: _OpsTrendPainter())),
                ],
              );
              final status = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _KpiLine(title: 'Completed Processing', value: 0.72, color: Color(0xFF2B8A3E)),
                  _KpiLine(title: 'In Queue', value: 0.19, color: Color(0xFFE67700)),
                  _KpiLine(title: 'Flagged', value: 0.09, color: Color(0xFFC92A2A)),
                ],
              );

              if (stacked) {
                return Column(children: [trend, const SizedBox(height: 16), status]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: trend),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: status),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleWorkspaceSection(bool isWide) {
    final items = [
      _RoleThemeData(
        role: 'Merchant Workspace',
        colorA: const Color(0xFF0B7285),
        colorB: const Color(0xFF2EC4B6),
        icon: Icons.storefront_rounded,
        route: Routes.MERCHANT_LOGIN,
        summary: 'Growth command, stock strategy, campaign orchestration, and financial visibility.',
      ),
      _RoleThemeData(
        role: 'Staff Workspace',
        colorA: const Color(0xFFE67700),
        colorB: const Color(0xFFFFB703),
        icon: Icons.groups_2_outlined,
        route: Routes.STAFF_LOGIN,
        summary: 'Fast in-store execution for POS, stock actions, and customer servicing flow.',
      ),
      _RoleThemeData(
        role: 'Shop Workspace',
        colorA: const Color(0xFF2B8A3E),
        colorB: const Color(0xFF51CF66),
        icon: Icons.point_of_sale_rounded,
        route: Routes.SHOP_LOGIN,
        summary: 'Branch-focused visibility and control across items, customers, and invoice rhythm.',
      ),
      _RoleThemeData(
        role: 'Admin Workspace',
        colorA: const Color(0xFF364FC7),
        colorB: const Color(0xFF5C7CFA),
        icon: Icons.admin_panel_settings_outlined,
        route: Routes.ADMIN_LOGIN,
        summary: 'System-level governance and global control for platform and user operations.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 38, isWide ? 42 : 18, 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Workspace Architecture', 'Role-based paths with clear identity and operational boundaries.'),
          const SizedBox(height: 14),
          ...items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Reveal(delay: 80 + entry.key * 70, child: _WorkspaceBand(data: entry.value)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _orchestrationSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Operational Orchestration', 'Four core stages that keep the system coordinated across every location.'),
          const SizedBox(height: 12),
          const _FlowStep(index: 1, title: 'Capture', subtitle: 'Shop and staff actions are captured instantly at transaction level.'),
          const _FlowStep(index: 2, title: 'Sync', subtitle: 'Central inventory and sales state sync across all workspaces in one timeline.'),
          const _FlowStep(index: 3, title: 'Decide', subtitle: 'Merchant leadership sees live trends and can steer campaigns, stock, and planning.'),
          const _FlowStep(index: 4, title: 'Scale', subtitle: 'Repeat high-performing playbooks across branches without fragmentation.'),
        ],
      ),
    );
  }

  Widget _implementationSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDF4FA),
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 44, isWide ? 42 : 18, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Implementation Journey', 'A practical sequence from setup to stable multi-branch operations.'),
          const SizedBox(height: 12),
          const _JourneyRow(stage: 'Week 1', title: 'Foundation Setup', body: 'Portal entrypoint selection, workspace access model, and environment mapping.'),
          const _JourneyRow(stage: 'Week 2', title: 'Catalog + Inventory Migration', body: 'Import item data, shop structures, suppliers, and baseline stock positions.'),
          const _JourneyRow(stage: 'Week 3', title: 'Operational Launch', body: 'Staff onboarding, POS go-live, and support channel calibration.'),
          const _JourneyRow(stage: 'Week 4+', title: 'Optimization', body: 'Promotion strategy, KPI tuning, and reporting automation improvements.'),
        ],
      ),
    );
  }

  Widget _faqSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Frequently Asked Questions', 'Common rollout and operations questions from scaling retail teams.'),
          const SizedBox(height: 12),
          const _FaqLine(question: 'Can we start with one branch and scale later?', answer: 'Yes. The architecture supports a single-branch launch first, then expansion to multi-branch operations without changing platforms.'),
          const _FaqLine(question: 'Does support include Telegram and bot-assisted triage?', answer: 'Yes. Teams can use direct Telegram support and a Telegram bot flow for quick checks and structured requests.'),
          const _FaqLine(question: 'Can support and contact channels be customized per deployment?', answer: 'Yes. Contact channels are read from environment values, so you can configure support email, phone, Telegram, and bot details.'),
        ],
      ),
    );
  }

  Widget _contactSection(bool isWide) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 42, isWide ? 42 : 18, 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Support and Contact Channels', 'Reach the team through direct contact or bot-assisted support flows.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: PublicContactLauncher.openSupportEmail,
                icon: const Icon(Icons.email_outlined),
                label: Text(PublicContactConfig.supportEmail),
                style: FilledButton.styleFrom(backgroundColor: _ocean, foregroundColor: Colors.white),
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
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.PUBLIC_CONTACT),
                icon: const Icon(Icons.alternate_email),
                label: const Text('Open Contact Page'),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(Routes.PUBLIC_SUPPORT),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Open Support Page'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _testimonials(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 42 : 18, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('What Teams Say', 'Feedback from operations teams transitioning to unified workflows.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _TestimonialCard(
                quote: 'We moved from fragmented tools to one clean operating layer. Execution became predictable.',
                author: 'A. Rahman',
                role: 'Retail Operations Lead',
              ),
              _TestimonialCard(
                quote: 'The role-based workspaces are clear and fast. We onboarded teams in days, not weeks.',
                author: 'N. Putri',
                role: 'Branch Program Manager',
              ),
              _TestimonialCard(
                quote: 'It looks premium and works like a serious system. Leadership finally sees live truth.',
                author: 'B. Santoso',
                role: 'Founder',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomCta(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 16, isWide ? 42 : 18, 36),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _midnight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 560,
              child: Text(
                'Want the complete picture? Explore Features and About, then continue to your workspace.',
                style: GoogleFonts.manrope(
                  color: const Color(0xFFDBE7F0),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => Get.toNamed(Routes.PUBLIC_FEATURES),
                  icon: const Icon(Icons.auto_awesome_motion_outlined),
                  label: const Text('Features'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _ink),
                ),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed(Routes.PUBLIC_ABOUT),
                  icon: const Icon(Icons.apartment_outlined),
                  label: const Text('About'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(bool isWide) {
    return Container(
      width: double.infinity,
      color: _midnight,
      padding: EdgeInsets.fromLTRB(isWide ? 42 : 18, 36, isWide ? 42 : 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 22,
            runSpacing: 18,
            children: [
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Retail Central',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'One operating layer for Merchant, Staff, Shop, and Admin workspaces with synchronized data and role clarity.',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFFBCCCDC),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Links',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FooterLink(text: 'Features', onTap: () => Get.toNamed(Routes.PUBLIC_FEATURES)),
                    _FooterLink(text: 'About', onTap: () => Get.toNamed(Routes.PUBLIC_ABOUT)),
                    _FooterLink(text: 'Support', onTap: () => Get.toNamed(Routes.PUBLIC_SUPPORT)),
                    _FooterLink(text: 'Contact', onTap: () => Get.toNamed(Routes.PUBLIC_CONTACT)),
                  ],
                ),
              ),
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Info',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FooterInfo(
                      label: 'Support Email',
                      value: PublicContactConfig.supportEmail,
                      onTap: PublicContactLauncher.openSupportEmail,
                    ),
                    _FooterInfo(
                      label: 'Contact Email',
                      value: PublicContactConfig.contactEmail,
                      onTap: PublicContactLauncher.openContactEmail,
                    ),
                    _FooterInfo(
                      label: 'Phone',
                      value: PublicContactConfig.contactPhone,
                      onTap: PublicContactLauncher.openPhone,
                    ),
                    _FooterInfo(
                      label: 'Telegram',
                      value: '@${PublicContactConfig.telegramUsername}',
                      onTap: PublicContactLauncher.openTelegramSupport,
                    ),
                    _FooterInfo(
                      label: 'Telegram Bot',
                      value: '@${PublicContactConfig.telegramBotUsername}',
                      onTap: PublicContactLauncher.openTelegramBot,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x334A6572), height: 1),
          const SizedBox(height: 10),
          Text(
            'Copyright 2026 Smart Retail. All rights reserved.',
            style: GoogleFonts.manrope(
              color: const Color(0xFF90A7BB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(color: _ink, fontSize: 36, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.manrope(color: _slate, fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(color: _ink, fontWeight: FontWeight.w800),
      textAlign: TextAlign.center,
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.manrope(color: const Color(0xFF1F3C56), height: 1.4),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _RailStep extends StatelessWidget {
  const _RailStep({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 8), decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0B7285))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ink, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.55)),
                const Divider(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  const _FeatureColumn({
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: CustomerLandingView._ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              color: const Color(0xFF486581),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle, size: 16, color: CustomerLandingView._ocean),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF334E68),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _DarkRoleDetail extends StatelessWidget {
  const _DarkRoleDetail({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF142B48),
        border: Border.all(color: const Color(0x334A6572)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.arrow_right, size: 16, color: Color(0xFF8BD3E6)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.manrope(
                        color: const Color(0xFFBFD0DD),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({required this.feature, required this.detail, required this.merchant, required this.staff, required this.shop, this.admin = false});

  final String feature;
  final String detail;
  final bool merchant;
  final bool staff;
  final bool shop;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFDCE5EE)))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(feature, style: GoogleFonts.playfairDisplay(fontSize: 23, color: CustomerLandingView._ink, fontWeight: FontWeight.w700))),
          Expanded(flex: 5, child: Text(detail, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.5))),
          Expanded(child: _flag(merchant, const Color(0xFF0B7285))),
          Expanded(child: _flag(staff, const Color(0xFFE67700))),
          Expanded(child: _flag(shop, const Color(0xFF2B8A3E))),
          Expanded(child: _flag(admin, const Color(0xFF364FC7))),
        ],
      ),
    );
  }

  Widget _flag(bool active, Color color) {
    return Text(
      active ? 'Yes' : '-',
      textAlign: TextAlign.center,
      style: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        color: active ? color : const Color(0xFF8AA0B5),
      ),
    );
  }
}

class _KpiLine extends StatelessWidget {
  const _KpiLine({required this.title, required this.value, required this.color});

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 24, color: CustomerLandingView._ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: value,
              backgroundColor: const Color(0xFFE6ECF2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleThemeData {
  const _RoleThemeData({
    required this.role,
    required this.colorA,
    required this.colorB,
    required this.icon,
    required this.route,
    required this.summary,
  });

  final String role;
  final Color colorA;
  final Color colorB;
  final IconData icon;
  final String route;
  final String summary;
}

class _WorkspaceBand extends StatelessWidget {
  const _WorkspaceBand({required this.data});

  final _RoleThemeData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(data.route),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(width: 6, color: data.colorA),
            bottom: const BorderSide(color: Color(0xFFDCE5EE)),
          ),
          gradient: LinearGradient(colors: [data.colorA.withValues(alpha: 0.06), Colors.transparent]),
        ),
        child: Row(
          children: [
            Icon(data.icon, color: data.colorA),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.role, style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ink, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(data.summary, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text('Open', style: GoogleFonts.manrope(color: data.colorA, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.index, required this.title, required this.subtitle});

  final int index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index', style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ocean, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ink, fontSize: 28, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.5)),
                const Divider(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({required this.stage, required this.title, required this.body});

  final String stage;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(stage, style: GoogleFonts.manrope(color: const Color(0xFF0B7285), fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ink, fontSize: 26, fontWeight: FontWeight.w700)),
                Text(body, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.55)),
                const Divider(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqLine extends StatelessWidget {
  const _FaqLine({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 10),
      title: Text(question, style: GoogleFonts.playfairDisplay(color: CustomerLandingView._ink, fontSize: 25, fontWeight: FontWeight.w700)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(answer, style: GoogleFonts.manrope(color: const Color(0xFF486581), height: 1.6)),
        ),
        const Divider(height: 18),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.quote, required this.author, required this.role});

  final String quote;
  final String author;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E2EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x13000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: CustomerLandingView._ocean),
          const SizedBox(height: 8),
          Text(
            quote,
            style: GoogleFonts.manrope(
              color: CustomerLandingView._ink,
              fontSize: 15,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            author,
            style: GoogleFonts.playfairDisplay(
              color: CustomerLandingView._ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            role,
            style: GoogleFonts.manrope(
              color: const Color(0xFF486581),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            color: const Color(0xFFC3D3E0),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  const _FooterInfo({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final Future<bool> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.manrope(
            color: const Color(0xFFC3D3E0),
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: onTap != null ? const Color(0xFF9BE7FF) : null,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: () => onTap!.call(),
      child: child,
    );
  }
}

class _PublicAiChatFab extends StatefulWidget {
  const _PublicAiChatFab();

  @override
  State<_PublicAiChatFab> createState() => _PublicAiChatFabState();
}

class _PublicAiChatFabState extends State<_PublicAiChatFab> {
  final PublicAiChatService _chatService = Get.find<PublicAiChatService>();
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: 'Hello. I am Smart Retail Assistant. Ask me about features, onboarding, or support.',
    ),
  ];

  bool _open = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _loading) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: prompt));
      _loading = true;
    });
    _controller.clear();

    try {
      final answer = await _chatService.ask(prompt);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: answer));
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(
          const _ChatMessage(
            role: _ChatRole.assistant,
            text: 'I could not reach the AI service right now. Please try again in a moment.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: _open ? 360 : 56,
      height: _open ? 480 : 56,
      child: Material(
        elevation: 14,
        borderRadius: BorderRadius.circular(_open ? 20 : 28),
        color: Colors.transparent,
        child: _open ? _chatPanel() : _launcher(),
      ),
    );
  }

  Widget _launcher() {
    return InkWell(
      onTap: () => setState(() => _open = true),
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B7285), Color(0xFF2EC4B6)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
    );
  }

  Widget _chatPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B7285), Color(0xFF2EC4B6)],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Smart Retail AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _open = false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.role == _ChatRole.user;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF0B7285) : const Color(0xFFF2F7F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFF102A43),
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask about pricing, setup, features...',
                        filled: true,
                        fillColor: const Color(0xFFF5FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loading ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0B7285),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _ChatRole role;
  final String text;
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD9E2EC), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: CustomerLandingView._ink),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.manrope(
                  color: CustomerLandingView._ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: CustomerLandingView._ink,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OpsTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFEAF1F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bgPaint);
    }

    final points = [
      Offset(size.width * 0.03, size.height * 0.76),
      Offset(size.width * 0.16, size.height * 0.64),
      Offset(size.width * 0.29, size.height * 0.68),
      Offset(size.width * 0.42, size.height * 0.48),
      Offset(size.width * 0.55, size.height * 0.52),
      Offset(size.width * 0.68, size.height * 0.38),
      Offset(size.width * 0.81, size.height * 0.31),
      Offset(size.width * 0.94, size.height * 0.24),
    ];

    final areaPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x662EC4B6), Color(0x002EC4B6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B7285), Color(0xFF2EC4B6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF0B7285);
    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = const Color(0x220B7285)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SystemMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodeA = Offset(size.width * 0.18, size.height * 0.27);
    final nodeB = Offset(size.width * 0.52, size.height * 0.20);
    final nodeC = Offset(size.width * 0.82, size.height * 0.38);
    final nodeD = Offset(size.width * 0.30, size.height * 0.68);
    final nodeE = Offset(size.width * 0.64, size.height * 0.72);

    final List<List<Offset>> links = [
      [nodeA, nodeB],
      [nodeB, nodeC],
      [nodeA, nodeD],
      [nodeB, nodeD],
      [nodeB, nodeE],
      [nodeC, nodeE],
      [nodeD, nodeE],
    ];

    final linePaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.6;
    for (final pair in links) {
      canvas.drawLine(pair[0], pair[1], linePaint);
    }

    void drawNode(Offset center, Color c) {
      canvas.drawCircle(
        center,
        18,
        Paint()
          ..color = c.withValues(alpha: 0.28)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(center, 8, Paint()..color = c);
    }

    drawNode(nodeA, const Color(0xFF2EC4B6));
    drawNode(nodeB, const Color(0xFF5C7CFA));
    drawNode(nodeC, const Color(0xFFFFB703));
    drawNode(nodeD, const Color(0xFF51CF66));
    drawNode(nodeE, const Color(0xFFE67700));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      duration: Duration(milliseconds: 520 + delay),
      builder: (context, value, widgetChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}
