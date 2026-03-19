import 'package:smart_retail/main.dart' as app;

Future<void> main() async {
  await app.startSmartRetailApp(envFile: '.env.admin', forcedPortal: 'admin');
}
