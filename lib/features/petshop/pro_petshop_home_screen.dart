import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

const _coral = Color(0xFFF36C6C);
const _bgSoft = Color(0xFFF7F8FA);

/// ========================= PROVIDERS =========================

final myPetshopProviderProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) => ref.read(apiProvider).myProvider(),
);

final myProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myProducts();
  } catch (_) {
    return [];
  }
});

final myOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myPetshopOrders();
  } catch (_) {
    return [];
  }
});

final pendingOrdersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.read(apiProvider).myPetshopOrders(status: 'PENDING');
  } catch (_) {
    return [];
  }
});

/// Statistiques rapides
final petshopStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final products = await ref.watch(myProductsProvider.future);
  final orders = await ref.watch(myOrdersProvider.future);
  final pending = await ref.watch(pendingOrdersProvider.future);

  int totalRevenue = 0;
  for (final order in orders) {
    final status = (order['status'] ?? '').toString().toUpperCase();
    if (status == 'DELIVERED' || status == 'COMPLETED') {
      final total = _asInt(order['totalDa'] ?? order['total'] ?? 0);
      totalRevenue += total;
    }
  }

  return {
    'totalProducts': products.length,
    'activeProducts': products.where((p) => p['active'] != false).length,
    'totalOrders': orders.length,
    'pendingOrders': pending.length,
    'totalRevenue': totalRevenue,
  };
});

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// ========================= MAIN SCREEN =========================

class PetshopHomeScreen extends ConsumerStatefulWidget {
  const PetshopHomeScreen({super.key});

  @override
  ConsumerState<PetshopHomeScreen> createState() => _PetshopHomeScreenState();
}

class _PetshopHomeScreenState extends ConsumerState<PetshopHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);
    final user = state.user ?? {};
    final first = (user['firstName'] ?? '').toString().trim();
    final last = (user['lastName'] ?? '').toString().trim();
    final fallbackUserName =
        [if (first.isNotEmpty) first, if (last.isNotEmpty) last].join(' ').trim();

    final provAsync = ref.watch(myPetshopProviderProfileProvider);
    final shopName = provAsync.maybeWhen(
      data: (p) {
        final dn = (p?['displayName'] ?? '').toString().trim();
        if (dn.isNotEmpty) return dn;
        return fallbackUserName.isNotEmpty ? fallbackUserName : 'Animalerie';
      },
      orElse: () =>
          (fallbackUserName.isNotEmpty ? fallbackUserName : 'Animalerie'),
    );

    final statsAsync = ref.watch(petshopStatsProvider);
    final pendingAsync = ref.watch(pendingOrdersProvider);

    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (!mounted) return;
              context.go('/auth/login?as=pro');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPetshopProviderProfileProvider);
          ref.invalidate(myProductsProvider);
          ref.invalidate(myOrdersProvider);
          ref.invalidate(pendingOrdersProvider);
          ref.invalidate(petshopStatsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Header(shopName: shopName),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // Statistiques
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: statsAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (e, _) => _SectionCard(
                    child: Text('Erreur: $e'),
                  ),
                  data: (stats) => _StatsGrid(stats: stats),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Commandes en attente
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: pendingAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (pending) {
                    if (pending.isEmpty) return const SizedBox.shrink();
                    return _PendingOrdersBanner(
                      count: pending.length,
                      onTap: () => context.push('/petshop/orders'),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Actions principales
            const SliverToBoxAdapter(child: _ActionGrid()),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Produits récents
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mes produits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.push('/petshop/products'),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ref.watch(myProductsProvider).when(
                      loading: () => const _LoadingCard(),
                      error: (e, _) => _SectionCard(
                        child: Text('Erreur: $e'),
                      ),
                      data: (products) {
                        if (products.isEmpty) {
                          return _SectionCard(
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('Aucun produit'),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/petshop/products/new'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter un produit'),
                                ),
                              ],
                            ),
                          );
                        }
                        return _ProductsPreview(products: products.take(3).toList());
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _coral,
        onPressed: () => context.push('/petshop/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau produit'),
      ),
    );
  }
}

/// ========================= WIDGETS =========================

class _Header extends StatelessWidget {
  final String shopName;
  const _Header({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_coral, Color(0xFFFF9D9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              shopName.isNotEmpty
                  ? shopName.characters.first.toUpperCase()
                  : 'A',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bienvenue', style: TextStyle(color: Colors.white70)),
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.storefront, color: Colors.white, size: 26),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          icon: Icons.inventory_2,
          label: 'Produits',
          value: '${stats['totalProducts'] ?? 0}',
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.shopping_cart,
          label: 'Commandes',
          value: '${stats['totalOrders'] ?? 0}',
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.pending_actions,
          label: 'En attente',
          value: '${stats['pendingOrders'] ?? 0}',
          color: Colors.amber,
        ),
        _StatCard(
          icon: Icons.attach_money,
          label: 'Revenus',
          value: _da(_asInt(stats['totalRevenue'] ?? 0)),
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOrdersBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingOrdersBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pending_actions, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count commande${count > 1 ? 's' : ''} en attente',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Appuyez pour voir les détails',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _Action('Produits', Icons.inventory_2, '/petshop/products',
          const Color(0xFF3A86FF)),
      _Action('Commandes', Icons.shopping_cart, '/petshop/orders',
          const Color(0xFFFF6D00)),
      _Action('Statistiques', Icons.analytics, '/petshop/stats',
          const Color(0xFF7B2CBF)),
      _Action('Paramètres', Icons.settings, '/pro/settings',
          const Color(0xFF1F7A8C)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _ActionCard(item: items[i]),
      ),
    );
  }
}

class _Action {
  final String title;
  final IconData icon;
  final String route;
  final Color color;
  const _Action(this.title, this.icon, this.route, this.color);
}

class _ActionCard extends StatelessWidget {
  final _Action item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(item.route),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: item.color.withOpacity(.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: item.color.withOpacity(.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.color.withOpacity(.15),
                child: Icon(item.icon, color: item.color),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsPreview extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _ProductsPreview({required this.products});

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products.map((product) {
        final title = (product['title'] ?? '').toString();
        final price = _asInt(product['priceDa'] ?? product['price'] ?? 0);
        final stock = _asInt(product['stock'] ?? 0);
        final active = product['active'] != false;
        final imageUrl = (product['imageUrls'] is List && (product['imageUrls'] as List).isNotEmpty)
            ? (product['imageUrls'] as List).first.toString()
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: imageUrl != null && imageUrl.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    ),
                  )
                : const Icon(Icons.image),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${_da(price)} • Stock: $stock'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!active)
                  const Icon(Icons.visibility_off, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/petshop/products/${product['id']}'),
          ),
        );
      }).toList(),
    );
  }
}
