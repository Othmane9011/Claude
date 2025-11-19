import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';

final myBookingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return await ref.read(apiProvider).myBookings();
});

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes rendez-vous')),
      body: asyncList.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final b = items[i] as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text('Status: ${b['status']}'),
                subtitle: Text('Le: ${b['scheduledAt']}'),
              ),
            );
          },
        ),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
