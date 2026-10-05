import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// LAPISAN 5 (bagian "data tersimpan"): ENKRIPSI AT-REST.
///
/// Token login dan data profil disimpan lewat flutter_secure_storage:
///  - Android: dienkripsi AES, kuncinya dijaga Android Keystore
///  - iOS    : disimpan di Keychain
/// Jadi token tidak tergeletak sebagai teks biasa seperti pada SharedPreferences.
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
      // Keystore bisa rusak setelah restore perangkat. Hapus agar tidak macet.
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
