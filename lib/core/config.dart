import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envBase = String.fromEnvironment('API_BASE');

  static String get apiBase {
    if (_envBase.isNotEmpty) return _envBase.replaceFirst(RegExp(r'/$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  static String get origin => apiBase.replaceFirst(RegExp(r'/api/?$'), '');

  static bool get isSecureTransport {
    final uri = Uri.tryParse(apiBase);
    if (uri == null) return false;
    if (uri.scheme == 'https') return true;
    if (kReleaseMode) return false;
    return const ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host) ||
        RegExp(r'^(192\.168|10\.|172\.(1[6-9]|2\d|3[01]))\.').hasMatch(uri.host);
  }

  static const String adminWhatsapp = '628175404437';

  static const String sanggarName = 'Sanggar Asmorobangun';
  static const String sanggarAddress =
      'Dusun Kedungmonggo, Desa Karangpandan, Kec. Pakisaji, Kab. Malang, Jawa Timur.';
  static const String mapsUrl =
      'https://www.google.com/maps/search/Sanggar+Asmorobangun+Pakisaji+Malang';
}
