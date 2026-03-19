import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicContactConfig {
  static String get supportEmail =>
      _env('PUBLIC_SUPPORT_EMAIL', fallback: 'support@yourdomain.com');

  static String get contactEmail =>
      _env('PUBLIC_CONTACT_EMAIL', fallback: 'hello@yourdomain.com');

  static String get contactPhone =>
      _env('PUBLIC_CONTACT_PHONE', fallback: '+621234567890');

  static String get telegramUsername => _normalizeUsername(
    _env('PUBLIC_TELEGRAM_USERNAME', fallback: 'your_support_channel'),
  );

  static String get telegramBotUsername => _normalizeUsername(
    _env('PUBLIC_TELEGRAM_BOT_USERNAME', fallback: 'your_support_bot'),
  );

  static String get telegramBotStartParam =>
      _env('PUBLIC_TELEGRAM_BOT_START', fallback: 'hello');

  static String get supportEmailSubject => _env(
    'PUBLIC_SUPPORT_EMAIL_SUBJECT',
    fallback: 'Smart Retail Support Request',
  );

  static String get contactEmailSubject => _env(
    'PUBLIC_CONTACT_EMAIL_SUBJECT',
    fallback: 'Smart Retail Contact Request',
  );

  static String _env(String key, {required String fallback}) {
    final value = (dotenv.env[key] ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  static String _normalizeUsername(String raw) {
    return raw.startsWith('@') ? raw.substring(1) : raw;
  }
}

class PublicContactLauncher {
  static Future<bool> openSupportEmail() {
    final uri = Uri(
      scheme: 'mailto',
      path: PublicContactConfig.supportEmail,
      queryParameters: {'subject': PublicContactConfig.supportEmailSubject},
    );
    return launchUrl(uri);
  }

  static Future<bool> openContactEmail() {
    final uri = Uri(
      scheme: 'mailto',
      path: PublicContactConfig.contactEmail,
      queryParameters: {'subject': PublicContactConfig.contactEmailSubject},
    );
    return launchUrl(uri);
  }

  static Future<bool> openPhone() {
    final uri = Uri(scheme: 'tel', path: PublicContactConfig.contactPhone);
    return launchUrl(uri);
  }

  static Future<bool> openTelegramSupport() {
    final uri = Uri.parse(
      'https://t.me/${PublicContactConfig.telegramUsername}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openTelegramBot() {
    final bot = PublicContactConfig.telegramBotUsername;
    final start = PublicContactConfig.telegramBotStartParam;
    final uri = Uri.parse('https://t.me/$bot?start=$start');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
