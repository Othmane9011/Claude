import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_controller.dart';

class RequireRole extends ConsumerWidget {
  final List<String> roles; // ex: ['PRO','ADMIN']
  final Widget child;
  const RequireRole({super.key, required this.roles, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = (ref.watch(sessionProvider).user?['role'] as String?) ?? 'USER';
    if (!roles.contains(role)) {
      // Accès refusé → on affiche une page neutre (tu peux rediriger si tu préfères)
      return const _ForbiddenScreen();
    }
    return child;
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Accès interdit', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
