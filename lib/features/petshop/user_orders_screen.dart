// lib/features/petshop/user_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);
const _bgSoft = Color(0xFFF7F8FA);

/// Provider pour les commandes du client
final _clientOrdersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiProvider);
  return api.myClientOrders();
});

class UserOrdersScreen extends ConsumerWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_clientOrdersProvider);

    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: const Text('Mes commandes'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(_clientOrdersProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune commande',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos commandes apparaîtront ici',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            );
          }

          // Trier par date décroissante
          orders.sort((a, b) {
            final dateA = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(2000);
            final dateB = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_clientOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _OrderCard(order: orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
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

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'En attente';
      case 'CONFIRMED':
        return 'Confirmée';
      case 'SHIPPED':
        return 'Expédiée';
      case 'DELIVERED':
        return 'Livrée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'SHIPPED':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = (order['id'] ?? '').toString();
    final status = (order['status'] ?? 'PENDING').toString();
    final totalDa = _asInt(order['totalDa'] ?? order['total'] ?? 0);
    final createdAt = DateTime.tryParse((order['createdAt'] ?? '').toString())?.toLocal();
    final items = order['items'] as List? ?? [];

    // Provider info
    final provider = order['provider'] as Map? ?? {};
    final providerName = (provider['displayName'] ?? 'Boutique').toString();

    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(createdAt)
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                const SizedBox(width: 8),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Boutique
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: _coral),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        providerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Items
                if (items.isNotEmpty)
                  Text(
                    items.map((i) {
                      final title = (i['title'] ?? i['product']?['title'] ?? 'Article').toString();
                      final qty = _asInt(i['quantity'] ?? 1);
                      return '$qty× $title';
                    }).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),

                const SizedBox(height: 8),

                // Date et total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      _da(totalDa),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _coral,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
