// lib/features/adopt/adopt_chats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';

final _requestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // TODO backend: endpoint "likes reçus" pour vos annonces.
  // Sans endpoint inbound, on affiche liste vide pour "Demandes".
  // Laisse la structure en place pour brancher plus tard.
  return <Map<String, dynamic>>[];
});

final _chatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiProvider);
  // Hypothèse: adoptMyLikes() peut renvoyer un champ "mutual": true
  final likes = await api.adoptMyLikes();
  return likes.where((m) {
    final mutual = (m['mutual'] ?? false) == true;
    return mutual;
  }).toList();
});

class AdoptChatsScreen extends ConsumerWidget {
  const AdoptChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: _initialTabFromQuery(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discussions'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.mark_email_unread_outlined), text: 'Demandes'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Confirmés'),
          ]),
        ),
        body: const TabBarView(
          children: [
            _RequestsTab(),
            _ChatsTab(),
          ],
        ),
      ),
    );
  }

  int _initialTabFromQuery(BuildContext context) {
    final q = GoRouterState.of(context).uri.queryParameters['tab'];
    if (q == 'chats') return 1;
    return 0;
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_requestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const _Empty(text: 'Aucune demande pour le moment.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RequestTile(item: list[i]),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _RequestTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // Masque identité utilisateur — n’affiche que l’animal
    final petName = (item['petName'] ?? item['title'] ?? 'Animal').toString();
    final species = (item['species'] ?? '').toString();
    final city = (item['city'] ?? '').toString();

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.pets)),
        title: Text(petName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([species, city].where((s) => s.isNotEmpty).join(' · ')),
        trailing: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {
                // TODO backend: refuser la demande
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande refusée (mock)')));
              },
              child: const Text('Refuser'),
            ),
            FilledButton(
              onPressed: () {
                // TODO backend: accepter/confirm -> ouvre chat
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande acceptée (mock)')));
              },
              child: const Text('Accepter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatsTab extends ConsumerWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_chatsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const _Empty(text: 'Aucun chat confirmé.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final m = list[i];
            final petName = (m['petName'] ?? m['title'] ?? 'Animal').toString();
            final species = (m['species'] ?? '').toString();
            final city = (m['city'] ?? '').toString();

            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text(petName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text([species, city].where((s) => s.isNotEmpty).join(' · ')),
                onTap: () {
                  // TODO: ouvrir écran de chat (non demandé ici)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ouvrir chat (TODO)')));
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Text(text, style: const TextStyle(color: Colors.black54)));
}