import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

enum AppEnvironment { dev, prod }

class AppConfig extends GetxService {
  late final AppEnvironment appEnvironment;

  Future<AppConfig> init() async {
    final env = dotenv.env['APP_ENV'] ?? 'prod';
    appEnvironment = AppEnvironment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => AppEnvironment.prod,
    );

    return this;
  }

  bool get isDevelopment => appEnvironment == AppEnvironment.dev;
}
