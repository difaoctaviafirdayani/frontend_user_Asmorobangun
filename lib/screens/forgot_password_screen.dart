import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_state.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../widgets/auth_ui.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ForgotPasswordViewModel(c.read<AuthState>()),
      child: _ForgotPasswordView(initialEmail: initialEmail),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  final String? initialEmail;
  const _ForgotPasswordView({this.initialEmail});

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;

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
    final vm = context.read<ForgotPasswordViewModel>();
    if (vm.busy) return;
    if (!_formKey.currentState!.validate()) return;
    final message = await vm.submit(
      email: _email.text,
      phone: _phone.text,
      newPassword: _newPass.text,
      confirmPassword: _confirm.text,
    );
    if (message == null || !mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ForgotPasswordViewModel>();
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              'Lupa Password',
              'Masukkan email dan nomor HP yang Anda pakai saat mendaftar, lalu buat password baru.',
            ),
            if (vm.error != null) AuthErrorBanner(vm.error!),
            AuthField(
              label: 'Email',
              hint: 'contoh@gmail.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            AuthField(
              label: 'Nomor HP saat daftar',
              hint: '08xxxxxxxxxx',
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            AuthField(
              label: 'Password Baru',
              hint: 'Tulis password baru Anda',
              helperText: 'Huruf dan angka saja, 6-64 karakter.',
              controller: _newPass,
              obscureText: _hideNew,
              onToggleObscure: () => setState(() => _hideNew = !_hideNew),
              textInputAction: TextInputAction.next,
              enableSuggestions: false,
              autocorrect: false,
              validator: _validatePassword,
            ),
            AuthField(
              label: 'Ulangi Password Baru',
              hint: 'Ulangi password baru Anda',
              controller: _confirm,
              obscureText: _hideConfirm,
              onToggleObscure: () =>
                  setState(() => _hideConfirm = !_hideConfirm),
              textInputAction: TextInputAction.done,
              enableSuggestions: false,
              autocorrect: false,
              onFieldSubmitted: (_) => _submit(),
              validator: _validateConfirm,
            ),
            const SizedBox(height: 4),
            AuthButton(
              label: 'Ganti Password',
              busy: vm.busy,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            AuthLink(
              lead: 'Ingat password?',
              action: 'Masuk di sini.',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}