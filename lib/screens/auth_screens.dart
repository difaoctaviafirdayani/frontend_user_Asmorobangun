import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_state.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../viewmodels/login_viewmodel.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/auth_ui.dart';
import '../widgets/common.dart';

Future<bool> ensureLogin(BuildContext context) async {
  final auth = context.read<AuthState>();
  if (auth.ensureSessionValid()) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen(popOnSuccess: true)),
  );
  return ok == true;
}

final RegExp _alnumRe = RegExp(r'^[A-Za-z0-9]+$');

String? _passwordAlnum(String? v) {
  final s = v ?? '';
  if (s.isEmpty) return 'Password wajib diisi.';
  if (s.length < 6) return 'Password minimal 6 karakter.';
  if (s.length > 64) return 'Password maksimal 64 karakter.';
  if (!_alnumRe.hasMatch(s)) {
    return 'Hanya boleh huruf dan angka (tanpa spasi atau simbol).';
  }
  return null;
}

String? _phoneRequired(String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Nomor HP wajib diisi.';
  return null;
}

class LoginScreen extends StatelessWidget {
  final bool embedded;

  final bool popOnSuccess;

  final RouteSettings? redirect;

  const LoginScreen({super.key, this.embedded = false, this.popOnSuccess = false, this.redirect});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => LoginViewModel(c.read<AuthState>()),
      child: _LoginView(embedded: embedded, popOnSuccess: popOnSuccess, redirect: redirect),
    );
  }
}

class _LoginView extends StatefulWidget {
  final bool embedded;
  final bool popOnSuccess;
  final RouteSettings? redirect;
  const _LoginView({required this.embedded, required this.popOnSuccess, required this.redirect});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

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
    final vm = context.read<LoginViewModel>();
    vm.clearError();
    if (!_form.currentState!.validate()) return;
    final ok = await vm.submit(_email.text, _password.text);
    if (ok && mounted) _onSuccess();
  }

  Future<void> _goRegister() async {
    FocusScope.of(context).unfocus();
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(settings: const RouteSettings(name: Routes.register), builder: (_) => const RegisterScreen()),
    );
    if (ok == true && mounted) _onSuccess();
  }

  void _goForgotPassword() {
    FocusScope.of(context).unfocus();
    Navigator.of(context, rootNavigator: true).pushNamed(
      Routes.forgotPassword,
      arguments: _email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    return AuthScaffold(
      showBack: !widget.embedded,
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              'Masuk',
              'Masuk untuk mendaftar kelas, memesan topeng, dan mengikuti forum diskusi',
            ),
            if (vm.error != null) AuthErrorBanner(vm.error!),
            AuthField(
              label: 'Email',
              hint: 'Tulis Email Anda di sini',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(120),
              validator: Validators.email,
            ),
            AuthField(
              label: 'Password',
              hint: 'Tulis password Anda di sini',
              controller: _password,
              obscureText: _hide,
              onToggleObscure: () => setState(() => _hide = !_hide),
              autofillHints: const [AutofillHints.password],
              enableSuggestions: false,
              autocorrect: false,
              inputFormatters: InputFormats.maxLen(64),
              validator: _passwordAlnum,
              onFieldSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: vm.busy ? null : _goForgotPassword,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    'Lupa password?',
                    style: TextStyle(
                      color: AppColors.wood700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AuthButton(label: 'Masuk', busy: vm.busy, onPressed: _submit),
            const SizedBox(height: 10),
            AuthLink(
              lead: 'Belum punya akun?',
              action: 'Daftar Sekarang',
              onTap: vm.busy ? null : _goRegister,
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => RegisterViewModel(c.read<AuthState>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<RegisterViewModel>();
    vm.clearErrors();
    if (!_form.currentState!.validate()) return;
    final ok = await vm.submit(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (ok) {
      showSnack(context, 'Akun berhasil dibuat. Selamat datang!');
      Navigator.pop(context, true);
    } else if (vm.emailServerError != null) {
      _form.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    return AuthScaffold(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeading(
              'Daftar Akun',
              'Buat akun untuk bisa mendaftar kelas, memesan topeng, dan booking pentas',
            ),
            if (vm.error != null) AuthErrorBanner(vm.error!),
            AuthField(
              label: 'Nama Lengkap',
              hint: 'Tulis nama Anda di sini',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(60),
              validator: Validators.name,
            ),
            AuthField(
              label: 'Email',
              hint: 'contoh@gmail.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(120),
              onChanged: (_) => vm.clearEmailServerError(),
              validator: (v) => Validators.email(v) ?? vm.emailServerError,
            ),
            AuthField(
              label: 'Nomor HP/WhatsApp',
              hint: '08xxxxxxxxxx',
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.phone,
              validator: (v) => _phoneRequired(v) ?? Validators.phone(v),
            ),
            AuthField(
              label: 'Buat Password',
              hint: '6-64 karakter, hanya huruf dan angka',
              controller: _password,
              obscureText: _hide,
              onToggleObscure: () => setState(() => _hide = !_hide),
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              inputFormatters: InputFormats.maxLen(64),
              validator: _passwordAlnum,
            ),
            AuthField(
              label: 'Verifikasi Password',
              hint: 'Ulangi password Anda',
              controller: _confirm,
              obscureText: _hide,
              enableSuggestions: false,
              autocorrect: false,
              validator: Validators.confirmPassword(() => _password.text),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 4),
            AuthButton(label: 'Daftar', busy: vm.busy, onPressed: _submit),
            const SizedBox(height: 10),
            AuthLink(
              lead: 'Sudah punya akun?',
              action: 'Masuk di sini.',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}