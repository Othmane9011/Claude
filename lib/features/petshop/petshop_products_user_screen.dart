// lib/features/petshop/petshop_products_user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);

/// Provider pour les détails d'une animalerie
final _petshopProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(apiProvider).providerDetails(id);
});

/// Provider pour les produits d'une animalerie
final _petshopProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, providerId) async {
  try {
    final api = ref.read(apiProvider);
    return await api.listPublicProducts(providerId);
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

    return Scaffold(
      appBar: AppBar(
        title: petshopAsync.maybeWhen(
          data: (p) => Text((p['displayName'] ?? 'Animalerie').toString()),
          orElse: () => const Text('Animalerie'),
        ),
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
                                      color: Colors.black.withOpacity(0.6),
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
                            color: Colors.black.withOpacity(0.7),
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
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _ProductCard(product: product);
                      },
                      childCount: products.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context) {
    final title = (product['title'] ?? '').toString();
    final description = (product['description'] ?? '').toString();
    final price = _asInt(product['priceDa'] ?? product['price'] ?? 0);
    final stock = _asInt(product['stock'] ?? 0);
    final imageUrls = product['imageUrls'] as List?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty
        ? imageUrls.first.toString()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              )
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, size: 32),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _da(price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _coral,
                        ),
                      ),
                      if (stock > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'En stock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Rupture',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
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

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

