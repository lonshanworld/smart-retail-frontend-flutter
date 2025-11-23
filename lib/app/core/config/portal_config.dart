/// Portal types for different deployments
enum PortalType { admin, customer }

/// Configuration for different portal deployments
class PortalConfig {
  final PortalType portalType;
  final String portalName;
  final String introRoute;

  const PortalConfig({
    required this.portalType,
    required this.portalName,
    required this.introRoute,
  });

  /// Returns true if this is the admin portal
  bool get isAdminPortal => portalType == PortalType.admin;

  /// Returns true if this is the customer portal
  bool get isCustomerPortal => portalType == PortalType.customer;

  /// Factory to create portal config from environment string
  factory PortalConfig.fromEnvironment(String? portalEnv) {
    // Default to customer portal if not specified
    final portalType = portalEnv?.toLowerCase() == 'admin'
        ? PortalType.admin
        : PortalType.customer;

    switch (portalType) {
      case PortalType.admin:
        return const PortalConfig(
          portalType: PortalType.admin,
          portalName: 'Smart Retail Admin',
          introRoute: '/admin-intro',
        );
      case PortalType.customer:
        return const PortalConfig(
          portalType: PortalType.customer,
          portalName: 'Smart Retail',
          introRoute: '/customer-intro',
        );
    }
  }

  /// Admin portal configuration
  static const PortalConfig admin = PortalConfig(
    portalType: PortalType.admin,
    portalName: 'Smart Retail Admin',
    introRoute: '/admin-intro',
  );

  /// Customer portal configuration
  static const PortalConfig customer = PortalConfig(
    portalType: PortalType.customer,
    portalName: 'Smart Retail',
    introRoute: '/customer-intro',
  );
}
