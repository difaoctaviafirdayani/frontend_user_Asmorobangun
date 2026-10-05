import 'package:flutter/material.dart';

import '../screens/auth_screens.dart';
import '../screens/my_orders_screen.dart';
import '../screens/shell.dart';
import '../screens/topeng_screen.dart';
import '../widgets/common.dart';
import 'auth_state.dart';

/// Nama-nama rute untuk Navigator.
class Routes {
  Routes._();
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const myOrders = '/my-orders'; // butuh login
  static const order = '/order'; // butuh login, arguments: String orderId
}

/// LAPISAN 4 (sisi klien): OTORISASI RUTE.
/// Rute di [_protected] hanya boleh dibuka oleh pengguna yang sudah login dan
/// berperan sesuai. Bila belum, pengguna diarahkan ke halaman masuk lalu
/// dikembalikan ke tujuan semula (lihat LoginScreen.redirect).
/// Ini hanya pagar di aplikasi. Pagar yang sebenarnya ada di server:
/// tiap endpoint memeriksa token, peran (requireAdmin), dan kepemilikan data.
class AppRouter {
  final AuthState auth;
  AppRouter(this.auth);

  /// rute -> peran yang diizinkan (kosong berarti semua peran yang sudah login).
  static const Map<String, Set<String>> _protected = {
    Routes.myOrders: {},
    Routes.order: {},
  };

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? Routes.home;

    if (_protected.containsKey(name)) {
      // Autentikasi: harus login dan token belum kedaluwarsa.
      if (!auth.ensureSessionValid()) {
        return _page(settings, LoginScreen(redirect: settings));
      }
      // Otorisasi: peran harus termasuk yang diizinkan (bila dibatasi).
      final roles = _protected[name]!;
      if (roles.isNotEmpty && !roles.contains(auth.user?.role)) {
        return _page(settings, const _ForbiddenScreen());
      }
    }

    switch (name) {
      case Routes.home:
        return _page(settings, const AppShell());
      case Routes.login:
        return _page(settings, const LoginScreen());
      case Routes.register:
        return _page(settings, const RegisterScreen());
      case Routes.myOrders:
        return _page(settings, const MyOrdersScreen());
      case Routes.order:
        final id = settings.arguments;
        if (id is String && id.isNotEmpty) return _page(settings, OrderDetailScreen(orderId: id));
        return _page(settings, const _NotFoundScreen());
      default:
        return _page(settings, const _NotFoundScreen());
    }
  }

  Route<dynamic> onUnknownRoute(RouteSettings settings) => _page(settings, const _NotFoundScreen());

  static MaterialPageRoute<T> _page<T>(RouteSettings settings, Widget child) =>
      MaterialPageRoute<T>(settings: settings, builder: (_) => child);
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) => const AppScaffold(
        title: 'Akses ditolak',
        body: EmptyState('Akunmu tidak punya izin untuk membuka halaman ini.', icon: Icons.lock_outline_rounded),
      );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => const AppScaffold(
        title: 'Tidak ditemukan',
        body: EmptyState('Halaman yang kamu cari tidak ada.', icon: Icons.search_off_rounded),
      );
}
