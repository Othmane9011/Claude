import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);

final petshopProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myProducts();
  } catch (e) {
    return [];
  }
});

class PetshopProductsScreen extends ConsumerWidget {
  const PetshopProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(petshopProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/petshop/products/new'),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun produit'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/petshop/products/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un produit'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(petshopProductsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductCard(product: products[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _coral,
        onPressed: () => context.push('/petshop/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
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
    final active = product['active'] != false;
    final imageUrls = product['imageUrls'] as List?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty
        ? imageUrls.first.toString()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/petshop/products/${product['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (imageUrl != null && imageUrl.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!active)
                          const Icon(Icons.visibility_off,
                              size: 18, color: Colors.grey),
                      ],
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _da(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _coral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stock > 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stock > 0 ? 'Stock: $stock' : 'Rupture',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: stock > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
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



