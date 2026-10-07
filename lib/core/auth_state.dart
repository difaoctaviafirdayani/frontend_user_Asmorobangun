import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api.dart';
import 'secure_store.dart';

/// Pusat LAPISAN 3 (autentikasi) dan sisi klien dari LAPISAN 4 (otorisasi).
///
/// Autentikasi: login ke server -> dapat JWT -> disimpan terenkripsi (SecureStore)
///   -> dikirim sebagai header Bearer pada tiap request -> dibuang saat logout,
///   saat server menjawab 401, atau saat klaim `exp` pada token sudah lewat.
/// Otorisasi (klien): menentukan siapa boleh membuka rute apa. Keputusan akhir
///   tetap di server (requireAuth, requireAdmin, cek kepemilikan data).
class AuthState extends ChangeNotifier {
  static const _tokenKey = 'asmoro_token';
  static const _userKey = 'asmoro_user';

  AppUser? user;
  String? token;
  bool ready = false;

  /// True bila logout terjadi karena sesi habis/ditolak server (bukan tombol Keluar).
  bool sessionExpired = false;

  bool get isLoggedIn => token != null && user != null;
  bool get isAdmin => user?.role == 'admin';
  bool hasRole(String role) => user?.role == role;

  Future<void> init() async {
    token = await secureStore.read(_tokenKey);
    final raw = await secureStore.read(_userKey);
    if (raw != null) {
      try {
        user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }
    if (user == null || token == null || _isExpired(token!)) {
      // Data tidak lengkap atau token sudah kedaluwarsa: mulai bersih.
      token = null;
      user = null;
      await _wipe();
    }
    api.token = token;
    api.onUnauthorized = () {
      sessionExpired = true;
      logout();
    };
    ready = true;
    notifyListeners();
    if (isLoggedIn) refreshMe();
  }

  /// Membaca klaim `exp` dari payload JWT. Ini hanya untuk UX (logout otomatis);
  /// tanda tangan token tetap diverifikasi oleh server, bukan oleh aplikasi.
  static bool _isExpired(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'];
      if (exp is! num) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp.toInt();
    } catch (_) {
      return true;
    }
  }

  /// Dipakai sebelum aksi penting: bila token sudah habis, keluarkan pengguna.
  bool ensureSessionValid() {
    if (token != null && _isExpired(token!)) {
      sessionExpired = true;
      logout();
      return false;
    }
    return isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    final res = await api.post('/auth/login', body: {'email': email, 'password': password});
    await _setSession(res);
  }

  Future<void> register({required String name, required String email, required String password, String phone = ''}) async {
    final res = await api.post('/auth/register',
        body: {'name': name, 'email': email, 'password': password, 'phone': phone});
    await _setSession(res);
  }

  /// LUPA PASSWORD. Email dan nomor HP harus cocok dengan data saat daftar.
  /// Tidak membuat sesi login: setelah berhasil, pengguna login dengan password baru.
  /// Mengembalikan pesan sukses dari server untuk ditampilkan sebagai notifikasi.
  Future<String> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await api.post('/auth/reset-password', body: {
      'email': email,
      'phone': phone,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return (res['message'] as String?) ?? 'Password berhasil diganti. Silakan login dengan password baru.';
  }

  /// GANTI PASSWORD saat sudah login. Server memberi token baru, jadi perangkat ini
  /// tetap login sedangkan perangkat lain otomatis keluar.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await api.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    await _setSession(res);
    return (res['message'] as String?) ?? 'Password berhasil diganti.';
  }

  Future<void> _setSession(Map<String, dynamic> res) async {
    token = res['token'] as String;
    user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    api.token = token;
    await _persist();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    try {
      final res = await api.get('/auth/me');
      user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      await _persist();
      notifyListeners();
    } catch (_) {
      // Abaikan: data lokal tetap dipakai. Kalau 401, onUnauthorized sudah logout.
    }
  }

  Future<void> setUserFromResponse(Map<String, dynamic> res) async {
    user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    api.token = null;
    await _wipe();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (token != null) await secureStore.write(_tokenKey, token!);
    if (user != null) await secureStore.write(_userKey, jsonEncode(user!.toJson()));
  }

  Future<void> _wipe() async {
    await secureStore.delete(_tokenKey);
    await secureStore.delete(_userKey);
  }
}