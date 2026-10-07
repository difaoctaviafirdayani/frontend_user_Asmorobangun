import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../widgets/common.dart';

/// Halaman LUPA PASSWORD: email + nomor HP (harus sama dengan saat daftar) + password baru.
/// Setelah berhasil muncul dialog notifikasi, lalu kembali ke halaman login.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _busy = false;
  String? _error;

  static final _alnum = RegExp(r'^[A-Za-z0-9]+$');
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email wajib diisi.';
    if (!_emailRe.hasMatch(s)) return 'Format email tidak valid.';
    return null;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Nomor HP wajib diisi.';
    if (digits.length < 9 || digits.length > 15) return 'Nomor HP tidak valid.';
    return null;
  }

  /// Aturan sama dengan server: hanya huruf dan angka, 6-64 karakter.
  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password baru wajib diisi.';
    if (s.length < 6) return 'Password minimal 6 karakter.';
    if (s.length > 64) return 'Password maksimal 64 karakter.';
    if (!_alnum.hasMatch(s)) {
      return 'Hanya boleh huruf dan angka (tanpa spasi, titik, koma, atau simbol lain).';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '').isEmpty) return 'Ulangi password baru.';
    if (v != _newPass.text) return 'Konfirmasi password tidak sama.';
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthState>();
    try {
      final message = await auth.resetPassword(
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        newPassword: _newPass.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF3F7D4A), size: 48),
          title: const Text('Password berhasil diganti'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Masuk sekarang'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      title: 'Lupa password',
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Masukkan email dan nomor HP yang kamu pakai saat mendaftar, lalu buat password baru.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP saat daftar',
                        hintText: '08xxxxxxxxxx',
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _newPass,
                      obscureText: _hideNew,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password baru',
                        helperText: 'Huruf dan angka saja, 6-64 karakter.',
                        suffixIcon: IconButton(
                          tooltip: _hideNew ? 'Tampilkan' : 'Sembunyikan',
                          icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hideNew = !_hideNew),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _hideConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Ulangi password baru',
                        suffixIcon: IconButton(
                          tooltip: _hideConfirm ? 'Tampilkan' : 'Sembunyikan',
                          icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                        ),
                      ),
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ganti password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}