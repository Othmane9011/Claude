import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProShell extends StatelessWidget {
  final Widget child;
  const ProShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _ProBottomBar(),
    );
  }
}

class _ProBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.toString();

    int indexFromLocation() {
      if (current.startsWith('/pro/agenda')) return 1;
      if (current.startsWith('/pro/services')) return 2;
      return 0; // /pro/home
    }

    void onTap(int i) {
      switch (i) {
        case 0: context.go('/pro/home'); break;
        case 1: context.go('/pro/agenda'); break;
        case 2: context.go('/pro/services'); break;
      }
    }

    return NavigationBar(
      selectedIndex: indexFromLocation(),
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Accueil'),
        NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Agenda'),
        NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Services'),
      ],
    );
  }
}
