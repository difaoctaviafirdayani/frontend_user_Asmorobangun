import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../widgets/common.dart';
import 'facilities_screen.dart';
import 'forum_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'topeng_screen.dart';

class AppShell extends StatefulWidget {
  final RouteFactory onGenerateRoute;
  final RouteFactory onUnknownRoute;
  const AppShell({super.key, required this.onGenerateRoute, required this.onUnknownRoute});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  void _go(int i) {
    if (i == _index) {
      _keys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  Widget _tabNavigator(int i, Widget root) => Navigator(
        key: _keys[i],
        onGenerateRoute: (settings) {
          if (settings.name == Navigator.defaultRouteName) {
            return MaterialPageRoute(settings: settings, builder: (_) => root);
          }
          return widget.onGenerateRoute(settings);
        },
        onUnknownRoute: widget.onUnknownRoute,
      );

  void _onBack() {
    final nav = _keys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    } else if (_index != 0) {
      setState(() => _index = 0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _tabNavigator(0, HomeScreen(onNavigate: _go)),
      _tabNavigator(1, const FacilitiesScreen()),
      _tabNavigator(2, const ForumScreen()),
      _tabNavigator(3, const TopengScreen()),
      _tabNavigator(4, const ProfileScreen()),
    ];
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: ShellScope(
        goHome: () => _go(0),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(index: _index, children: tabs),
          bottomNavigationBar: keyboardOpen
              ? null
              : NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: AppColors.wood900,
                    indicatorColor: Colors.white.withAlpha(36),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                    iconTheme: WidgetStateProperty.resolveWith(
                      (states) => IconThemeData(
                        size: 28,
                        color: states.contains(WidgetState.selected) ? AppColors.gold300 : AppColors.cream100,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _go,
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda', tooltip: 'Beranda'),
                      NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Fasilitas', tooltip: 'Fasilitas'),
                      NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Forum', tooltip: 'Forum'),
                      NavigationDestination(icon: Icon(Icons.theater_comedy_outlined), selectedIcon: Icon(Icons.theater_comedy), label: 'Topeng', tooltip: 'Topeng'),
                      NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Akun', tooltip: 'Akun'),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}