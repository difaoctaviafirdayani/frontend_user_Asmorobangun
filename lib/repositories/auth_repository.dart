import 'dart:convert';

import '../core/api.dart';
import '../core/secure_store.dart';
import '../models/models.dart';

class AuthRepository {
  static const _tokenKey = 'asmoro_token';
  static const _userKey = 'asmoro_user';

  final ApiClient _api;
  final SecureStore _store;
  AuthRepository(this._api, this._store);

  set token(String? value) => _api.token = value;

  set onUnauthorized(void Function()? callback) => _api.onUnauthorized = callback;

  Future<Map<String, dynamic>> login(String email, String password) =>
      _api.post('/auth/login', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) =>
      _api.post('/auth/register', body: {'name': name, 'email': email, 'password': password, 'phone': phone});

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _api.post('/auth/reset-password', body: {
        'email': email,
        'phone': phone,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _api.post('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });

  Future<Map<String, dynamic>> fetchMe() => _api.get('/auth/me');

  Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String filename) =>
      _api.upload('/auth/me/avatar', field: 'avatar', bytes: bytes, filename: filename);

  Future<Map<String, dynamic>> deleteAvatar() => _api.delete('/auth/me/avatar');

  Future<String?> readToken() => _store.read(_tokenKey);

  Future<AppUser?> readUser() async {
    final raw = await _store.read(_userKey);
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({String? token, AppUser? user}) async {
    if (token != null) await _store.write(_tokenKey, token);
    if (user != null) await _store.write(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _store.delete(_tokenKey);
    await _store.delete(_userKey);
  }
}
