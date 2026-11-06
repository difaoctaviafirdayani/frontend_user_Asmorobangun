import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

final secureStore = SecureStore.instance;
