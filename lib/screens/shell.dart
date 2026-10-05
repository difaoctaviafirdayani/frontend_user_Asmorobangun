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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        backgroundColor: AppColors.cream100,
        indicatorColor: AppColors.gold300,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.theater_comedy_outlined), selectedIcon: Icon(Icons.theater_comedy), label: 'Fasilitas'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Forum'),
          NavigationDestination(icon: Icon(Icons.face_retouching_natural_outlined), selectedIcon: Icon(Icons.face_retouching_natural), label: 'Topeng'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Akun'),
        ],
      ),
    );
  }
}
