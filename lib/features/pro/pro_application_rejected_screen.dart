import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import 'package:go_router/go_router.dart';

class ProApplicationRejectedScreen extends ConsumerWidget {
  const ProApplicationRejectedScreen({super.key});

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v as Map);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: () async {
        await api.ensureAuth();
        final raw = await api.myProvider();
        final rawMap  = _asMap(raw);
        final dataMap = _asMap(rawMap?['data']) ?? rawMap;
        return dataMap;
      }(),
      builder: (ctx, snap) {
        const coral = Color(0xFFF36C6C);

        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final Map<String, dynamic> prov = snap.data ?? <String, dynamic>{};
        final String reason = (prov['rejectionReason'] as String?)?.trim().isNotEmpty == true
            ? (prov['rejectionReason'] as String)
            : 'Votre demande a été refusée par l’équipe.';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Demande refusée'),
            surfaceTintColor: Colors.transparent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.block, size: 64, color: coral),
                const SizedBox(height: 16),
                const Text(
                  'Votre candidature a été rejetée',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 24),
                // OK -> retour écran de login PRO
                FilledButton(
                  onPressed: () {
                    context.go('/auth/login?as=pro'); // 👈 direct login pro
                  },
                  child: const Text('OK'),
                ),
                const SizedBox(height: 8),
                // Refaire une demande -> POST /providers/me/reapply + redirection "submitted"
                TextButton(
                  onPressed: () async {
                    try {
                      await api.ensureAuth();
                      await api.reapplyMyProvider();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Votre nouvelle demande a été envoyée.')),
                        );
                        context.go('/pro/application/submitted');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Refaire une demande'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
