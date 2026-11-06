import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/auth_state.dart';
import 'core/error_reporter.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'repositories/announcement_repository.dart';
import 'repositories/article_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/facility_repository.dart';
import 'repositories/forum_repository.dart';
import 'repositories/gallery_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/review_repository.dart';
import 'repositories/topeng_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorReporter.report(details.exceptionAsString(), path: 'flutter', detail: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.report(error.toString(), path: 'flutter', detail: stack);
    return true;
  };

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
    return MultiProvider(
      providers: [
        Provider<AnnouncementRepository>(create: (_) => AnnouncementRepository(api)),
        Provider<ArticleRepository>(create: (_) => ArticleRepository(api)),
        Provider<AuthRepository>.value(value: widget.auth.repository),
        Provider<FacilityRepository>(create: (_) => FacilityRepository(api)),
        Provider<ForumRepository>(create: (_) => ForumRepository(api)),
        Provider<GalleryRepository>(create: (_) => GalleryRepository(api)),
        Provider<PaymentRepository>(create: (_) => PaymentRepository(api)),
        Provider<ReviewRepository>(create: (_) => ReviewRepository(api)),
        Provider<TopengRepository>(create: (_) => TopengRepository(api)),
      ],
      child: MaterialApp(
        title: 'Asmorobangun',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        initialRoute: Routes.home,
        onGenerateRoute: _router.onGenerateRoute,
        onUnknownRoute: _router.onUnknownRoute,
      ),
    );
  }
}