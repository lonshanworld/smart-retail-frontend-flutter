class RuntimePortal {
  static String? _portal;

  static void set(String portal) {
    _portal = portal.trim().toLowerCase();
  }

  static String? get value => _portal;

  static void clear() {
    _portal = null;
  }
}
