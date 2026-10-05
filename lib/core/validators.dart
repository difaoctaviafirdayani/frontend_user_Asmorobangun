import 'package:flutter/services.dart';

/// LAPISAN 1: VALIDASI UI.
/// Semua input pengguna dicek di sini sebelum dikirim ke server.
/// Setiap fungsi mengembalikan pesan error (String) atau null bila valid,
/// sehingga bisa dipakai langsung di `validator:` milik TextFormField.
///
/// Catatan: validasi di UI hanya untuk kenyamanan dan mengurangi request sia-sia.
/// Server tetap menjadi penentu akhir (lapisan 2), karena UI bisa dilewati.
class Validators {
  Validators._();

  static final _emailRe = RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$");
  // Nomor Indonesia: 08xx..., 628xx..., atau +628xx..., total 9-13 digit setelah awalan.
  static final _phoneRe = RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{7,11}$');
  static final _nameRe = RegExp(r"^[A-Za-z\u00C0-\u024F][A-Za-z\u00C0-\u024F .'\-]*$");

  static String? requiredField(String? v, [String label = 'Kolom ini']) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Email wajib diisi';
    if (t.length > 120) return 'Email terlalu panjang';
    if (!_emailRe.hasMatch(t)) return 'Format email tidak valid';
    return null;
  }

  /// Untuk halaman masuk: cukup memastikan tidak kosong. Aturan kekuatan
  /// password hanya dipakai saat mendaftar agar akun lama tetap bisa masuk.
  static String? passwordLogin(String? v) =>
      (v == null || v.isEmpty) ? 'Password wajib diisi' : null;

  static String? passwordRegister(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'Password wajib diisi';
    if (t.length < 8) return 'Minimal 8 karakter';
    if (t.length > 72) return 'Maksimal 72 karakter'; // batas input bcrypt
    if (!RegExp(r'[A-Za-z]').hasMatch(t)) return 'Harus mengandung huruf';
    if (!RegExp(r'[0-9]').hasMatch(t)) return 'Harus mengandung angka';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (v) => (v == null || v.isEmpty)
          ? 'Ulangi password kamu'
          : (v != original() ? 'Password tidak sama' : null);

  static String? name(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Nama wajib diisi';
    if (t.length < 2) return 'Nama terlalu pendek';
    if (t.length > 60) return 'Maksimal 60 karakter';
    if (!_nameRe.hasMatch(t)) return 'Nama hanya boleh huruf, spasi, titik, atau tanda hubung';
    return null;
  }

  static String? phone(String? v, {bool required = false}) {
    final t = (v ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (t.isEmpty) return required ? 'Nomor WhatsApp wajib diisi' : null;
    if (!_phoneRe.hasMatch(t)) return 'Gunakan format 08xxxxxxxxxx atau +62...';
    return null;
  }

  static String? Function(String?) text(String label, {int min = 1, int max = 500, bool required = true}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return required ? '$label wajib diisi' : null;
        if (t.length < min) return '$label minimal $min karakter';
        if (t.length > max) return '$label maksimal $max karakter';
        return null;
      };

  static String? Function(String?) integer(String label, {int min = 1, int max = 1000, bool required = true}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return required ? '$label wajib diisi' : null;
        final n = int.tryParse(t);
        if (n == null) return '$label harus berupa angka';
        if (n < min) return '$label minimal $min';
        if (n > max) return '$label maksimal $max';
        return null;
      };

  /// Pembersih ringan: buang karakter kontrol dan rapikan spasi berlebih.
  /// (Pencegahan XSS yang sebenarnya ada di sisi render: Flutter menampilkan
  /// teks apa adanya, bukan HTML, sehingga tag tidak dieksekusi.)
  static String clean(String v) =>
      v.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '').trim();
}

/// Pembatas karakter yang diizinkan saat mengetik.
class InputFormats {
  InputFormats._();
  static final digitsOnly = <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
  static final phone = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
    LengthLimitingTextInputFormatter(16),
  ];
  static List<TextInputFormatter> maxLen(int n) => [LengthLimitingTextInputFormatter(n)];
}
