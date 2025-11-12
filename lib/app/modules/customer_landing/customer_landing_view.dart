import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/routes/app_pages.dart';

class CustomerLandingView extends StatelessWidget {
  const CustomerLandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Section with Navigation
              SliverToBoxAdapter(
                child: _HeroSection(),
              ),

              // Value Proposition
              SliverToBoxAdapter(
                child: _ValuePropositionSection(),
              ),

              // Core Features - POS & Inventory
              SliverToBoxAdapter(
                child: _CoreFeaturesSection(),
              ),

              // Advanced Features Grid
              SliverToBoxAdapter(
                child: _AdvancedFeaturesSection(),
              ),

              // Multi-Role Support
              SliverToBoxAdapter(
                child: _MultiRoleSupportSection(),
              ),

              // Analytics & Reporting
              SliverToBoxAdapter(
                child: _AnalyticsSection(),
              ),

              // Login Options Section
              SliverToBoxAdapter(
                child: _LoginOptionsSection(),
              ),

              // Stats
              SliverToBoxAdapter(
                child: _StatsSection(),
              ),

              // CTA Section
              SliverToBoxAdapter(
                child: _CTASection(),
              ),

              // Footer
              SliverToBoxAdapter(
                child: _Footer(),
              ),
            ],
          ),
          
          // Floating Admin Button
          Positioned(
            top: 50,
            right: 20,
            child: SafeArea(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.ADMIN_LOGIN),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5E72E4),
                          Color(0xFF825EE4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF5E72E4).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Admin Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HERO SECTION ====================
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 60,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Main Title
                    const Text(
                      'Smart Retail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Complete Retail Management Solution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Modern POS, Inventory Management, Analytics & More\nAll in One Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Quick Feature Pills
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _FeaturePill(icon: Icons.point_of_sale, label: 'POS System'),
                        _FeaturePill(icon: Icons.inventory_2, label: 'Inventory'),
                        _FeaturePill(icon: Icons.analytics, label: 'Analytics'),
                        _FeaturePill(icon: Icons.people, label: 'Customers'),
                        _FeaturePill(icon: Icons.cloud, label: 'Cloud-Based'),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Scroll indicator
                    Column(
                      children: [
                        Text(
                          'Explore Features',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.9),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== VALUE PROPOSITION ====================
class _ValuePropositionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Why Choose Smart Retail?',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need to manage and grow your retail business',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 70),

          // Value Props
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _ValueProp(
                icon: Icons.speed,
                title: 'Lightning Fast',
                description: 'Process transactions in seconds with our optimized POS system',
                color: Colors.blue,
              ),
              _ValueProp(
                icon: Icons.security,
                title: 'Secure & Reliable',
                description: 'Bank-level security with automatic backups and data protection',
                color: Colors.green,
              ),
              _ValueProp(
                icon: Icons.trending_up,
                title: 'Grow Your Business',
                description: 'Powerful analytics and insights to make data-driven decisions',
                color: Colors.orange,
              ),
              _ValueProp(
                icon: Icons.support_agent,
                title: '24/7 Support',
                description: 'Always here to help you succeed with dedicated support team',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ValueProp({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CORE FEATURES ====================
class _CoreFeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Core Features',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Powerful tools to run your retail business efficiently',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 70),

          _BigFeatureCard(
            icon: Icons.point_of_sale_rounded,
            title: 'Point of Sale (POS)',
            description: 'Fast, intuitive checkout system with support for multiple payment methods, promotions, and receipt printing',
            features: [
              'Quick product search & barcode scanning',
              'Multiple payment methods support',
              'Real-time promotion application',
              'Customer management integration',
              'Instant receipt generation',
              'Sales tracking & history',
            ],
            color: Colors.blue,
            gradient: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          const SizedBox(height: 40),

          _BigFeatureCard(
            icon: Icons.inventory_2_rounded,
            title: 'Inventory Management',
            description: 'Complete control over your stock with real-time tracking, automated alerts, and multi-location support',
            features: [
              'Real-time stock level monitoring',
              'Low stock alerts & notifications',
              'Multi-shop inventory tracking',
              'Stock transfer between locations',
              'Supplier management',
              'Product categorization',
            ],
            color: Colors.green,
            gradient: [Colors.green.shade600, Colors.green.shade800],
            reverse: true,
          ),
        ],
      ),
    );
  }
}

class _BigFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  final List<Color> gradient;
  final bool reverse;

  const _BigFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
    required this.gradient,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        children: reverse
            ? [
                Expanded(child: _featureList()),
                const SizedBox(width: 40),
                Expanded(child: _iconSection()),
              ]
            : [
                Expanded(child: _iconSection()),
                const SizedBox(width: 40),
                Expanded(child: _featureList()),
              ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _iconSection(),
              const SizedBox(height: 30),
              _featureList(),
            ],
          );
        }
        return content;
      },
    );
  }

  Widget _iconSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ==================== ADVANCED FEATURES ====================
class _AdvancedFeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Advanced Capabilities',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sophisticated features to give you the competitive edge',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 70),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                icon: Icons.people_rounded,
                title: 'Customer Management',
                description: 'Build customer database, track purchase history, and create loyalty programs',
                color: Colors.purple,
              ),
              _FeatureCard(
                icon: Icons.discount_rounded,
                title: 'Promotions & Discounts',
                description: 'Create flexible promotions with percentage or fixed discounts for any product',
                color: Colors.pink,
              ),
              _FeatureCard(
                icon: Icons.local_shipping_rounded,
                title: 'Supplier Management',
                description: 'Manage supplier relationships, track orders, and streamline procurement',
                color: Colors.orange,
              ),
              _FeatureCard(
                icon: Icons.store_rounded,
                title: 'Multi-Shop Support',
                description: 'Manage multiple locations from a single platform with centralized control',
                color: Colors.teal,
              ),
              _FeatureCard(
                icon: Icons.sync_rounded,
                title: 'Stock Transfer',
                description: 'Easily transfer inventory between shops with complete tracking',
                color: Colors.indigo,
              ),
              _FeatureCard(
                icon: Icons.notifications_active_rounded,
                title: 'Smart Notifications',
                description: 'Get alerts for low stock, sales milestones, and important events',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MULTI-ROLE SUPPORT ====================
class _MultiRoleSupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Built for Every Team Member',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Role-based access and features tailored for your entire team',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 70),

          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _RoleCard(
                icon: Icons.business_center_rounded,
                title: 'Merchant',
                description: 'Full business oversight',
                features: [
                  'Manage all shops & inventory',
                  'Staff management & scheduling',
                  'Complete financial reports',
                  'Supplier relationships',
                  'Analytics & insights',
                ],
                color: Colors.blue,
              ),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: 'Shop Manager',
                description: 'Shop-level control',
                features: [
                  'Shop inventory management',
                  'POS operations',
                  'Customer management',
                  'Daily sales reports',
                  'Stock requests',
                ],
                color: Colors.green,
              ),
              _RoleCard(
                icon: Icons.badge_rounded,
                title: 'Staff',
                description: 'Operational excellence',
                features: [
                  'POS checkout',
                  'Product search',
                  'Customer service',
                  'Stock updates',
                  'Sales tracking',
                ],
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ==================== ANALYTICS SECTION ====================
class _AnalyticsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            'Data-Driven Insights',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Make informed decisions with powerful analytics and reporting',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 70),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _AnalyticsCard(
                icon: Icons.assessment_rounded,
                title: 'Sales Reports',
                description: 'Detailed sales analysis by date, product, shop, and staff',
                metrics: ['Daily/Weekly/Monthly', 'Product Performance', 'Revenue Tracking'],
                color: Colors.blue,
              ),
              _AnalyticsCard(
                icon: Icons.inventory_rounded,
                title: 'Inventory Reports',
                description: 'Track stock levels, movement, and valuation across all locations',
                metrics: ['Stock Levels', 'Turnover Rate', 'Dead Stock Analysis'],
                color: Colors.green,
              ),
              _AnalyticsCard(
                icon: Icons.psychology_rounded,
                title: 'AI Analysis',
                description: 'Gemini-powered insights for smarter business decisions',
                metrics: ['Sales Predictions', 'Trend Analysis', 'Recommendations'],
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> metrics;
  final Color color;

  const _AnalyticsCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.metrics,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...metrics.map((metric) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_right, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      metric,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ==================== LOGIN OPTIONS ====================
class _LoginOptionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Get Started Today',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your role and start managing your retail business',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 70),

          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _LoginCard(
                icon: Icons.business_center_rounded,
                title: 'Merchant Login',
                description: 'Access full business management',
                gradient: [Colors.blue.shade600, Colors.blue.shade800],
                onTap: () => Get.toNamed(Routes.MERCHANT_LOGIN),
              ),
              _LoginCard(
                icon: Icons.storefront_rounded,
                title: 'Shop Login',
                description: 'Manage your shop operations',
                gradient: [Colors.green.shade600, Colors.green.shade800],
                onTap: () => Get.toNamed(Routes.SHOP_LOGIN),
              ),
              _LoginCard(
                icon: Icons.badge_rounded,
                title: 'Staff Login',
                description: 'Access staff features',
                gradient: [Colors.orange.shade600, Colors.orange.shade800],
                onTap: () => Get.toNamed(Routes.STAFF_LOGIN),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _LoginCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 300,
        height: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, size: 30, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
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

// ==================== STATS SECTION ====================
class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: Colors.white,
      child: Wrap(
        spacing: 60,
        runSpacing: 40,
        alignment: WrapAlignment.center,
        children: [
          _StatItem(
            number: '99.9%',
            label: 'Uptime',
            icon: Icons.cloud_done_rounded,
          ),
          _StatItem(
            number: '24/7',
            label: 'Support',
            icon: Icons.support_agent_rounded,
          ),
          _StatItem(
            number: '100%',
            label: 'Secure',
            icon: Icons.security_rounded,
          ),
          _StatItem(
            number: 'Cloud',
            label: 'Based',
            icon: Icons.cloud_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue.shade600),
        const SizedBox(height: 12),
        Text(
          number,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==================== CTA SECTION ====================
class _CTASection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Transform Your Retail Business?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join hundreds of retailers who trust Smart Retail for their business operations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.MERCHANT_LOGIN),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.business_center_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Merchant Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.SHOP_LOGIN),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF11998e),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.storefront_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Shop Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.toNamed(Routes.STAFF_LOGIN),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFf46b45),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.badge_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Staff Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== FOOTER ====================
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Retail',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Complete Retail Management Solution',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink('Features'),
              Text('•', style: TextStyle(color: Colors.grey.shade600)),
              _FooterLink('Pricing'),
              Text('•', style: TextStyle(color: Colors.grey.shade600)),
              _FooterLink('Documentation'),
              Text('•', style: TextStyle(color: Colors.grey.shade600)),
              _FooterLink('Support'),
              Text('•', style: TextStyle(color: Colors.grey.shade600)),
              _FooterLink('Privacy Policy'),
              Text('•', style: TextStyle(color: Colors.grey.shade600)),
              _FooterLink('Terms of Service'),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 1,
            width: 200,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 24),
          Text(
            '© 2025 Smart Retail. All rights reserved.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _FooterLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
