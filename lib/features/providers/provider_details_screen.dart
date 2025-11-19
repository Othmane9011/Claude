import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import 'package:go_router/go_router.dart';

class ProviderDetailsScreen extends ConsumerWidget {
  final String providerId;
  const ProviderDetailsScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiProvider);
    return FutureBuilder(
      future: api.providerDetails(providerId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          if (snap.hasError) return Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: ${snap.error}')));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final p = snap.data as Map<String, dynamic>;
        final services = (p['services'] as List?) ?? const [];
        final ratingAvg = (p['ratingAvg'] ?? 0).toString();
        final ratingCount = (p['ratingCount'] ?? 0).toString();
        return Scaffold(
          appBar: AppBar(title: Text(p['displayName'] ?? 'Détails')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p['address'] ?? '', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text('⭐ $ratingAvg  ($ratingCount avis)'),
              const SizedBox(height: 16),
              const Text('Services', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final s in services)
                Card(
                  child: ListTile(
                    title: Text(s['title'] ?? ''),
                    subtitle: Text((s['description'] ?? '').toString()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/book/$providerId/${s['id']}'),
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
