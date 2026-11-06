import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../repositories/auth_repository.dart';
import 'api.dart';
import 'secure_store.dart';

class AuthState extends ChangeNotifier {
  final AuthRepository _repo;

  AuthState({AuthRepository? repository}) : _repo = repository ?? AuthRepository(api, secureStore);

  AuthRepository get repository => _repo;

  AppUser? user;
  String? token;
  bool ready = false;

  bool sessionExpired = false;

  bool get isLoggedIn => token != null && user != null;
  bool get isAdmin => user?.role == 'admin';
  bool hasRole(String role) => user?.role == role;

  Future<void> init() async {
    token = await _repo.readToken();
    user = await _repo.readUser();
    if (user == null || token == null || _isExpired(token!)) {
      token = null;
      user = null;
      await _repo.clearSession();
    }
    _repo.token = token;
    _repo.onUnauthorized = () {
      sessionExpired = true;
      logout();
    };
    ready = true;
    notifyListeners();
    if (isLoggedIn) refreshMe();
  }

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

  bool ensureSessionValid() {
    if (token != null && _isExpired(token!)) {
      sessionExpired = true;
      logout();
      return false;
    }
    return isLoggedIn;
  }

  Future<void> login(String email, String password) async {
    final res = await _repo.login(email, password);
    await _setSession(res);
  }

  Future<void> register({required String name, required String email, required String password, String phone = ''}) async {
    final res = await _repo.register(name: name, email: email, password: password, phone: phone);
    await _setSession(res);
  }

  Future<String> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _repo.resetPassword(
      email: email,
      phone: phone,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return (res['message'] as String?) ?? 'Password berhasil diganti. Silakan login dengan password baru.';
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    await _setSession(res);
    return (res['message'] as String?) ?? 'Password berhasil diganti.';
  }

  Future<void> _setSession(Map<String, dynamic> res) async {
    token = res['token'] as String;
    user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    _repo.token = token;
    await _persist();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    try {
      final res = await _repo.fetchMe();
      user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
      await _persist();
      notifyListeners();
    } catch (_) {
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
    _repo.token = null;
    await _repo.clearSession();
    notifyListeners();
  }

  Future<void> _persist() => _repo.saveSession(token: token, user: user);
}
