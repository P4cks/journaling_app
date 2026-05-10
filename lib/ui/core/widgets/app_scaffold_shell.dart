import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onDestinationTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Entries',
          ),
        ],
      ),
    );
  }
}
