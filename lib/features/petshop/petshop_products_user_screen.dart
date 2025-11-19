// lib/features/petshop/petshop_products_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import 'cart_provider.dart';

const _coral = Color(0xFFF36C6C);
const _bgSoft = Color(0xFFF7F8FA);

/// Provider pour les détails d'une animalerie
final _petshopProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(apiProvider).providerDetails(id);
});

/// Provider pour les produits d'une animalerie
final _petshopProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  try {
    final api = ref.read(apiProvider);
    final products = await api.listPublicProducts(providerId);
    // Filtrer seulement les produits actifs avec du stock
    return products.where((p) {
      final active = p['active'] ?? true;
      return active == true;
    }).toList();
  } catch (_) {
    return [];
  }
});

class PetshopProductsUserScreen extends ConsumerWidget {
  final String providerId;
  const PetshopProductsUserScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petshopAsync = ref.watch(_petshopProvider(providerId));
    final productsAsync = ref.watch(_petshopProductsProvider(providerId));
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: petshopAsync.maybeWhen(
          data: (p) => Text((p['displayName'] ?? 'Animalerie').toString()),
          orElse: () => const Text('Animalerie'),
        ),
        actions: [
          // Badge panier
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _coral,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: petshopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (petshop) {
          final name = (petshop['displayName'] ?? 'Animalerie').toString();
          final address = (petshop['address'] ?? '').toString();
          final bio = (petshop['bio'] ?? '').toString();

          return CustomScrollView(
            slivers: [
              // Header avec infos de l'animalerie
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFFFEEF0),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'A',
                              style: TextStyle(
                                color: Colors.pink[400],
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                if (address.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    address,
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          bio,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Liste des produits
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Produits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              productsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Erreur: $e'),
                    ),
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aucun produit disponible pour le moment.'),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          return _ProductCard(
                            product: product,
                            providerId: providerId,
                            providerName: name,
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
      // Bouton flottant pour voir le panier si non vide
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              backgroundColor: _coral,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Voir le panier ($cartCount)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Map<String, dynamic> product;
  final String providerId;
  final String providerName;

  const _ProductCard({
    required this.product,
    required this.providerId,
    required this.providerName,
  });

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = (product['id'] ?? '').toString();
    final title = (product['title'] ?? '').toString();
    final description = (product['description'] ?? '').toString();
    final price = _asInt(product['priceDa'] ?? product['price'] ?? 0);
    final stock = _asInt(product['stock'] ?? 0);
    final imageUrls = product['imageUrls'] as List?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty
        ? imageUrls.first.toString()
        : null;

    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.watch(cartProvider);
    final inCart = cartState.items.any((i) => i.productId == productId);
    final cartQty = cartNotifier.getQuantity(productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl != null && imageUrl.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              )
            else
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 32),
              ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Prix et stock
                  Row(
                    children: [
                      Text(
                        _da(price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _coral,
                        ),
                      ),
                      const Spacer(),
                      if (stock > 0)
                        Text(
                          '$stock en stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        )
                      else
                        Text(
                          'Rupture',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[700],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Boutons d'action
                  if (stock > 0)
                    inCart
                        ? _QuantitySelector(
                            quantity: cartQty,
                            maxQuantity: stock,
                            onIncrement: () => cartNotifier.incrementQuantity(productId),
                            onDecrement: () => cartNotifier.decrementQuantity(productId),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                cartNotifier.addItem(
                                  productId: productId,
                                  providerId: providerId,
                                  providerName: providerName,
                                  title: title,
                                  priceDa: price,
                                  stock: stock,
                                  imageUrl: imageUrl,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$title ajouté au panier'),
                                    duration: const Duration(seconds: 1),
                                    action: SnackBarAction(
                                      label: 'Voir',
                                      onPressed: () => context.push('/cart'),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('Ajouter'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _coral,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        child: const Text('Indisponible'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur de quantité
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantitySelector({
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              quantity == 1 ? Icons.delete_outline : Icons.remove,
              size: 20,
              color: quantity == 1 ? Colors.red : _coral,
            ),
            onPressed: onDecrement,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 20,
              color: quantity >= maxQuantity ? Colors.grey : _coral,
            ),
            onPressed: quantity >= maxQuantity ? null : onIncrement,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
