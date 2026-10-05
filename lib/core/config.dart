import 'package:flutter/foundation.dart';

class AppConfig {
  /// Ganti lewat: flutter run --dart-define=API_BASE=https://api.contoh.id/api
  static const String _envBase = String.fromEnvironment('API_BASE');

  static String get apiBase {
    if (_envBase.isNotEmpty) return _envBase.replaceFirst(RegExp(r'/$'), '');
    // Emulator Android mengakses komputer host lewat 10.0.2.2, bukan localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }

  /// Alamat dasar server (tanpa /api), dipakai untuk file /uploads dan aset lama.
  static String get origin => apiBase.replaceFirst(RegExp(r'/api/?$'), '');

  // ---- LAPISAN 5 - ENKRIPSI DATA SAAT TRANSIT ----
  /// Build rilis hanya boleh bicara lewat HTTPS. HTTP biasa hanya diizinkan
  /// untuk pengembangan lokal (localhost / emulator) pada build debug.
  static bool get isSecureTransport {
    final uri = Uri.tryParse(apiBase);
    if (uri == null) return false;
    if (uri.scheme == 'https') return true;
    if (kReleaseMode) return false;
    return const ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host) ||
        RegExp(r'^(192\.168|10\.|172\.(1[6-9]|2\d|3[01]))\.').hasMatch(uri.host);
  }

  /// Cadangan bila pengaturan WhatsApp dari server belum terbaca.
  static const String adminWhatsapp = '6281234567890';

  static const String sanggarName = 'Sanggar Asmorobangun';
  static const String sanggarAddress =
      'Dusun Kedungmonggo, Desa Karangpandan, Kec. Pakisaji, Kab. Malang, Jawa Timur.';
  static const String mapsUrl =
      'https://www.google.com/maps/search/Sanggar+Asmorobangun+Pakisaji+Malang';
}
