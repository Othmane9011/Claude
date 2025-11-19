// lib/features/petshop/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'cart_provider.dart';

const _coral = Color(0xFFF36C6C);
const _bgSoft = Color(0xFFF7F8FA);

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Vider le panier ?'),
                    content: const Text('Tous les articles seront supprimés.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () {
                          cartNotifier.clear();
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Vider'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Vider', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre panier est vide',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Parcourez les animaleries pour\najouter des produits',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/explore/petshop'),
                    icon: const Icon(Icons.storefront),
                    label: const Text('Voir les animaleries'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Grouper par boutique
                      ...cart.itemsByProvider.entries.map((entry) {
                        final providerId = entry.key;
                        final items = entry.value;
                        final providerName = items.first.providerName;
                        final providerSubtotal = items.fold<int>(0, (sum, i) => sum + i.totalDa);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                              // Header boutique
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEF0),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.storefront, color: _coral, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        providerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _da(providerSubtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: _coral,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Items
                              ...items.map((item) => _CartItemTile(
                                    item: item,
                                    onIncrement: () => cartNotifier.incrementQuantity(item.productId),
                                    onDecrement: () => cartNotifier.decrementQuantity(item.productId),
                                    onRemove: () => cartNotifier.removeItem(item.productId),
                                  )),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // Résumé des coûts
                      Container(
                        padding: const EdgeInsets.all(16),
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
                          children: [
                            _SummaryRow(
                              label: 'Sous-total',
                              value: _da(cart.subtotalDa),
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Commission (${cart.providerCount} boutique${cart.providerCount > 1 ? 's' : ''})',
                              value: _da(cart.commissionDa),
                              isSecondary: true,
                            ),
                            const Divider(height: 24),
                            _SummaryRow(
                              label: 'Total',
                              value: _da(cart.totalDa),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info commission
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Une commission de $kPetshopCommissionDa DA est appliquée par boutique pour les frais de service.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100), // Espace pour le bouton
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            _da(cart.totalDa),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/checkout'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _coral,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Commander',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (item.imageUrl != null && item.imageUrl!.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 24),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 24),
            ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_da(item.priceDa)} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                // Contrôles quantité
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onDecrement,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                item.quantity == 1 ? Icons.delete_outline : Icons.remove,
                                size: 18,
                                color: item.quantity == 1 ? Colors.red : _coral,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: item.quantity >= item.stock ? null : onIncrement,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: item.quantity >= item.stock ? Colors.grey : _coral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _da(item.totalDa),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isSecondary;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isSecondary ? Colors.black.withValues(alpha: 0.6) : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: isBold ? _coral : (isSecondary ? Colors.black.withValues(alpha: 0.6) : null),
          ),
        ),
      ],
    );
  }
}
