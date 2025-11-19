import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);

final petshopOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myPetshopOrders();
  } catch (e) {
    return [];
  }
});

class PetshopOrdersScreen extends ConsumerStatefulWidget {
  const PetshopOrdersScreen({super.key});

  @override
  ConsumerState<PetshopOrdersScreen> createState() =>
      _PetshopOrdersScreenState();
}

class _PetshopOrdersScreenState extends ConsumerState<PetshopOrdersScreen> {
  String _filterStatus = 'ALL';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(petshopOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ALL', label: Text('Toutes')),
                      ButtonSegment(value: 'PENDING', label: Text('En attente')),
                      ButtonSegment(value: 'CONFIRMED', label: Text('Confirmées')),
                      ButtonSegment(value: 'DELIVERED', label: Text('Livrées')),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _filterStatus = newSelection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (orders) {
          final filtered = _filterStatus == 'ALL'
              ? orders
              : orders.where((o) {
                  final status = (o['status'] ?? '').toString().toUpperCase();
                  return status == _filterStatus;
                }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucune commande'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(petshopOrdersProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = (order['id'] ?? '').toString();
    final status = (order['status'] ?? 'PENDING').toString().toUpperCase();
    final total = _asInt(order['totalDa'] ?? order['total'] ?? 0);
    final createdAt = order['createdAt'] ?? order['created_at'];
    final items = order['items'] as List? ?? [];

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt.toString());
      } catch (_) {}
    }

    final user = order['user'] as Map? ?? {};
    final userName = (user['displayName'] ?? user['firstName'] ?? 'Client').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/petshop/orders/$id'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm', 'fr_FR')
                                .format(date),
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _statusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Client: $userName',
                  style: TextStyle(color: Colors.black.withOpacity(0.7))),
              const SizedBox(height: 8),
              if (items.isNotEmpty) ...[
                Text(
                  '${items.length} article${items.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _da(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _coral,
                    ),
                  ),
                  if (status == 'PENDING' || status == 'CONFIRMED')
                    FilledButton(
                      onPressed: () => _updateStatus(context, ref, id, status),
                      style: FilledButton.styleFrom(
                        backgroundColor: _coral,
                      ),
                      child: Text(status == 'PENDING' ? 'Confirmer' : 'Marquer livré'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String orderId, String currentStatus) async {
    final api = ref.read(apiProvider);
    String newStatus;
    if (currentStatus == 'PENDING') {
      newStatus = 'CONFIRMED';
    } else if (currentStatus == 'CONFIRMED') {
      newStatus = 'DELIVERED';
    } else {
      return;
    }

    try {
      await api.updatePetshopOrderStatus(orderId: orderId, status: newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commande mise à jour: $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

