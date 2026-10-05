import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../widgets/common.dart';

/// Pastikan pengguna sudah login. Bila belum, buka halaman masuk (Navigator.push)
/// dan kembalikan true bila login berhasil. Dipakai sebelum aksi yang butuh akun.
Future<bool> ensureLogin(BuildContext context) async {
  final auth = context.read<AuthState>();
  if (auth.ensureSessionValid()) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen(popOnSuccess: true)),
  );
  return ok == true;
}

class _AuthHeader extends StatelessWidget {
  final String title, subtitle;
  const _AuthHeader(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(color: AppColors.wood900, borderRadius: BorderRadius.circular(16)),
          child: Image.asset('assets/images/logo-gold.png', height: 42),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.wood900)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 22),
      ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF4D9D9), borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
      );
}

class LoginScreen extends StatefulWidget {
  /// Dipakai di tab Akun (tanpa app bar).
  final bool embedded;

  /// Tutup halaman dan kembalikan true setelah berhasil (dipakai ensureLogin).
  final bool popOnSuccess;

  /// Tujuan semula yang dihadang penjaga rute. Setelah login, Navigator
  /// mengganti halaman ini dengan tujuan tersebut.
  final RouteSettings? redirect;

  const LoginScreen({super.key, this.embedded = false, this.popOnSuccess = false, this.redirect});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error; // jawaban dari server (lapisan 2/3)

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSuccess() {
    final nav = Navigator.of(context);
    if (widget.popOnSuccess) {
      nav.pop(true);
    } else if (widget.redirect?.name != null) {
      nav.pushReplacementNamed(widget.redirect!.name!, arguments: widget.redirect!.arguments);
    } else if (!widget.embedded && nav.canPop()) {
      nav.pop(true);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    // Lapisan 1: validasi UI
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // Lapisan 3: autentikasi ke server
      await context.read<AuthState>().login(_email.text.trim().toLowerCase(), _password.text);
      if (mounted) _onSuccess();
    } on ApiException catch (e) {
      // Lapisan 2: server menolak (email/password salah, input tidak valid)
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goRegister() async {
    final ok = await Navigator.pushNamed<bool>(context, Routes.register);
    if (ok == true && mounted) _onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(children: [
          const _AuthHeader('Masuk', 'Masuk untuk mendaftar kelas, memesan topeng, dan ikut diskusi.'),
          if (_error != null) _ErrorBanner(_error!),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            inputFormatters: InputFormats.maxLen(120),
            decoration: inputDec('Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            autofillHints: const [AutofillHints.password],
            enableSuggestions: false,
            autocorrect: false,
            decoration: inputDec('Password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            validator: Validators.passwordLogin,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Masuk...' : 'Masuk')),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _goRegister, child: const Text('Belum punya akun? Daftar')),
        ]),
      ),
    );
    if (widget.embedded) return SafeArea(child: Center(child: body));
    return AppScaffold(title: 'Masuk', body: body);
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _emailServerError; // mis. "Email sudah terdaftar" (409 dari server)
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _emailServerError = null;
    });
    // Lapisan 1: validasi UI
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthState>().register(
            name: Validators.clean(_name.text),
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
            phone: _phone.text.replaceAll(RegExp(r'[\s\-]'), ''),
          );
      if (!mounted) return;
      showSnack(context, 'Akun berhasil dibuat. Selamat datang!');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Lapisan 2: server menolak. Pesan dipetakan ke kolom yang tepat.
      if (e.status == 409) {
        setState(() => _emailServerError = e.message);
        _form.currentState!.validate();
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Daftar Akun',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(children: [
            const _AuthHeader('Buat akun', 'Gratis dan cuma butuh satu menit.'),
            if (_error != null) _ErrorBanner(_error!),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(60),
              decoration: inputDec('Nama lengkap'),
              validator: Validators.name,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(120),
              decoration: inputDec('Email'),
              onChanged: (_) => _emailServerError = null,
              validator: (v) => Validators.email(v) ?? _emailServerError,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.phone,
              decoration: inputDec('Nomor WhatsApp (opsional)', hint: '08xxxxxxxxxx'),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _hide,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(72),
              decoration: inputDec('Password', hint: 'Min. 8 karakter, huruf dan angka').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: Validators.passwordRegister,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: _hide,
              enableSuggestions: false,
              autocorrect: false,
              decoration: inputDec('Ulangi password'),
              validator: Validators.confirmPassword(() => _password.text),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Mendaftar...' : 'Daftar')),
            ),
          ]),
        ),
      ),
    );
  }
}
