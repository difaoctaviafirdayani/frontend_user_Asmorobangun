# Asmorobangun App (Flutter)

Aplikasi pengunjung Sanggar Wayang Topeng Malangan. Memakai backend Express yang sama
(`../backend`), dan dashboard admin ada di `../frontend-admin-next`.

## Menjalankan

```bash
# 1. Jalankan backend dulu
cd ../backend && npm install && npm start      # http://localhost:4000

# 2. Buat folder platform (android/ios/web) sekali saja
cd ../frontend-app-flutter
flutter create . --project-name asmorobangun_app --org id.asmorobangun
flutter pub get

# 3. Jalankan
flutter run                                           # emulator Android otomatis ke 10.0.2.2:4000
flutter run --dart-define=API_BASE=http://192.168.1.10:4000/api   # HP fisik, pakai IP laptop
```

## Pengaturan platform yang wajib

`flutter create .` membuat folder `android/` dan `ios/`. Setelah itu:

**Android** (`android/app/build.gradle`): `minSdkVersion` minimal **23** (syarat `flutter_secure_storage`).

**Android** (`android/app/src/main/AndroidManifest.xml`), di dalam `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
</queries>
```

**Android, hanya untuk development lewat http** (`android/app/src/debug/AndroidManifest.xml`),
pada tag `<application>` tambahkan `android:usesCleartextTraffic="true"`. Jangan taruh ini di
manifest utama, supaya build rilis tetap menolak http.

**iOS** (`ios/Runner/Info.plist`): tambahkan `NSPhotoLibraryUsageDescription`
(mis. "Untuk memilih foto profil dan bukti pembayaran").

## Rilis

Build rilis **menolak** alamat non-HTTPS. Gunakan:
```bash
flutter build apk --release --dart-define=API_BASE=https://api.domainmu.id/api
```

## Lima lapisan keamanan

| # | Lapisan | Di mana |
|---|---------|---------|
| 1 | Validasi UI | `lib/core/validators.dart` dipakai lewat `Form` + `validator:` di semua form, plus `inputFormatters` |
| 2 | Validasi server | Server memvalidasi ulang; `ApiException.isValidation` (400/409/422) ditampilkan, mis. "email sudah terdaftar" muncul di kolom email |
| 3 | Autentikasi | `lib/core/auth_state.dart`: login JWT, header Bearer, cek `exp`, logout otomatis saat 401 |
| 4 | Otorisasi | `lib/core/routes.dart`: `AppRouter` menjaga rute bernama; server memeriksa peran dan kepemilikan data |
| 5 | Enkripsi | In-transit: HTTPS wajib di rilis (`api.dart`). At-rest: token disimpan di `flutter_secure_storage` (`secure_store.dart`) |

## Navigator

- `pushNamed` / `onGenerateRoute` / `onUnknownRoute`: `lib/core/routes.dart`
- `push` + `pop(result)`: detail halaman dan `ensureLogin` (hasil `true` bila login sukses)
- `pushReplacementNamed`: kembali ke tujuan semula setelah login
- `pushNamedAndRemoveUntil`: bersihkan tumpukan halaman saat logout/sesi habis (`main.dart`)
