import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'facilities_screen.dart';
import 'forum_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'topeng_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(onNavigate: _go),
      const FacilitiesScreen(),
      const ForumScreen(),
      const TopengScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBarTheme(
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
    );
  }
}