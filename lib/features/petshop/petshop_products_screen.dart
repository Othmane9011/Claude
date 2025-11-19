import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

const _primary = Color(0xFF2E7D32);

final petshopProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myProducts();
  } catch (e) {
    return [];
  }
});

class PetshopProductsScreen extends ConsumerStatefulWidget {
  const PetshopProductsScreen({super.key});

  @override
  ConsumerState<PetshopProductsScreen> createState() => _PetshopProductsScreenState();
}

class _PetshopProductsScreenState extends ConsumerState<PetshopProductsScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'active', 'inactive', 'low_stock'

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(petshopProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un produit',
            onPressed: () => context.push('/petshop/products/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Actifs',
                        selected: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Masques',
                        selected: _filter == 'inactive',
                        onTap: () => setState(() => _filter = 'inactive'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Stock faible',
                        selected: _filter == 'low_stock',
                        onTap: () => setState(() => _filter = 'low_stock'),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products list
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (products) {
                // Apply filters
                var filtered = products.where((p) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final title = (p['title'] ?? '').toString().toLowerCase();
                    final desc = (p['description'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    if (!title.contains(query) && !desc.contains(query)) {
                      return false;
                    }
                  }
                  // Status filter
                  final active = p['active'] != false;
                  final stock = _asInt(p['stock'] ?? 0);
                  switch (_filter) {
                    case 'active':
                      return active;
                    case 'inactive':
                      return !active;
                    case 'low_stock':
                      return stock > 0 && stock <= 5;
                    default:
                      return true;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    hasProducts: products.isNotEmpty,
                    filter: _filter,
                    onAdd: () => context.push('/petshop/products/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(petshopProductsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: filtered[i],
                      onToggleVisibility: () => _toggleVisibility(filtered[i]),
                      onDelete: () => _deleteProduct(filtered[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: () => context.push('/petshop/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  Future<void> _toggleVisibility(Map<String, dynamic> product) async {
    final api = ref.read(apiProvider);
    final productId = (product['id'] ?? '').toString();
    final currentActive = product['active'] != false;

    try {
      await api.updateProduct(productId, active: !currentActive);
      ref.invalidate(petshopProductsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentActive ? 'Produit masque' : 'Produit visible'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final productId = (product['id'] ?? '').toString();
    final title = (product['title'] ?? 'ce produit').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Voulez-vous vraiment supprimer "$title" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiProvider);
      await api.deleteProduct(productId);
      ref.invalidate(petshopProductsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprime')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? _primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasProducts;
  final String filter;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.hasProducts,
    required this.filter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    if (!hasProducts) {
      message = 'Aucun produit\nAjoutez votre premier produit';
      icon = Icons.inventory_2_outlined;
    } else {
      switch (filter) {
        case 'active':
          message = 'Aucun produit actif';
          icon = Icons.visibility_off;
          break;
        case 'inactive':
          message = 'Aucun produit masque';
          icon = Icons.visibility;
          break;
        case 'low_stock':
          message = 'Aucun produit en stock faible';
          icon = Icons.inventory;
          break;
        default:
          message = 'Aucun produit trouve';
          icon = Icons.search_off;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (!hasProducts) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onToggleVisibility,
    required this.onDelete,
  });

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

    return Dismissible(
      key: Key(product['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => context.push('/petshop/products/${product['id']}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image
                if (imageUrl != null && imageUrl.startsWith('http'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                    ),
                  )
                else
                  _ImagePlaceholder(),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: active ? Colors.black87 : Colors.grey,
                          decoration: active ? null : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _da(price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StockBadge(stock: stock),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    // Visibility toggle
                    IconButton(
                      icon: Icon(
                        active ? Icons.visibility : Icons.visibility_off,
                        color: active ? _primary : Colors.grey,
                      ),
                      tooltip: active ? 'Masquer' : 'Rendre visible',
                      onPressed: onToggleVisibility,
                    ),
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Modifier',
                      onPressed: () =>
                          context.push('/petshop/products/${product['id']}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, size: 30, color: Colors.grey[400]),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (stock == 0) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      label = 'Rupture';
    } else if (stock <= 5) {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      label = 'Stock: $stock';
    } else {
      bgColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green;
      label = 'Stock: $stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
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
