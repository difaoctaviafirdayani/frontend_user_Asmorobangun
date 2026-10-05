import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_state.dart';
import 'core/routes.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthState();
  await auth.init();
  runApp(
    ChangeNotifierProvider<AuthState>.value(value: auth, child: AsmorobangunApp(auth: auth)),
  );
}

class AsmorobangunApp extends StatefulWidget {
  final AuthState auth;
  const AsmorobangunApp({super.key, required this.auth});

  @override
  State<AsmorobangunApp> createState() => _AsmorobangunAppState();
}

class _AsmorobangunAppState extends State<AsmorobangunApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AppRouter _router = AppRouter(widget.auth);
  late bool _wasLoggedIn = widget.auth.isLoggedIn;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Saat pengguna keluar (tombol Keluar, token habis, atau ditolak server),
  /// bersihkan seluruh tumpukan halaman agar layar yang butuh login tidak tertinggal.
  void _onAuthChanged() {
    final auth = widget.auth;
    if (_wasLoggedIn && !auth.isLoggedIn) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.home, (_) => false);
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.wood900,
          content: Text(auth.sessionExpired ? 'Sesi login berakhir. Silakan masuk lagi.' : 'Kamu sudah keluar dari akun.'),
        ));
      auth.sessionExpired = false;
    }
    _wasLoggedIn = auth.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asmorobangun',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      initialRoute: Routes.home,
      onGenerateRoute: _router.onGenerateRoute,
      onUnknownRoute: _router.onUnknownRoute,
    );
  }
}
