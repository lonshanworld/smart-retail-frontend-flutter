import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

enum AppEnvironment { dev, prod }

class AppConfig extends GetxService {
  late final AppEnvironment appEnvironment;
  late final bool localStorageOnly;

  Future<AppConfig> init() async {
    final env = dotenv.env['APP_ENV'] ?? 'prod';
    appEnvironment = AppEnvironment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => AppEnvironment.prod,
    );

    localStorageOnly = _parseBool(dotenv.env['LOCAL_STORAGE_ONLY']);

    return this;
  }

  bool get isDevelopment => appEnvironment == AppEnvironment.dev;

  bool get isCloudSyncEnabled => !localStorageOnly;

  bool _parseBool(String? value) {
    switch ((value ?? 'false').trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
        return true;
      default:
        return false;
    }
  }
}
