import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppUrls {
  static String get webFrontendBaseUrl {
    // 1. Check explicit environment configuration
    final explicitUrl = dotenv.env['WEB_FRONTEND_URL'];
    if (explicitUrl != null && explicitUrl.trim().isNotEmpty) {
      return explicitUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    // 2. Derive dynamically from API_BASE_URL as per environment
    final apiBase = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.11:8000/api';
    final uri = Uri.tryParse(apiBase);
    if (uri != null) {
      // In local/LAN development, Vite frontend typically runs on port 5173
      if (uri.port == 8000) {
        return '${uri.scheme}://${uri.host}:5173';
      }
      // Production or custom domain setup
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    }

    return 'http://192.168.1.11:5173';
  }

  static String get termsAndConditionsUrl => '$webFrontendBaseUrl/terms';
  static String get privacyPolicyUrl => '$webFrontendBaseUrl/privacy';
}
