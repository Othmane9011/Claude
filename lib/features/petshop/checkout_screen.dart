// lib/features/petshop/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';
import 'cart_provider.dart';

const _coral = Color(0xFFF36C6C);
const _bgSoft = Color(0xFFF7F8FA);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final state = ref.read(sessionProvider);
    final user = state.user ?? {};
    _addressController.text = (user['city'] ?? user['address'] ?? '').toString();
    _phoneController.text = (user['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  Future<void> _placeOrders() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer une adresse de livraison');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un numéro de téléphone');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final api = ref.read(apiProvider);

      final deliveryAddress = _addressController.text.trim();
      final notes = _notesController.text.trim().isNotEmpty
          ? '${_notesController.text.trim()}\nTél: ${_phoneController.text.trim()}'
          : 'Tél: ${_phoneController.text.trim()}';

      // Créer une commande par boutique
      final orderIds = <String>[];

      for (final entry in cart.itemsByProvider.entries) {
        final providerId = entry.key;
        final items = cartNotifier.toApiItems(providerId);

        try {
          final result = await api.createPetshopOrder(
            providerId: providerId,
            items: items,
            deliveryAddress: deliveryAddress,
            notes: notes,
          );

          final orderId = (result['id'] ?? '').toString();
          if (orderId.isNotEmpty) {
            orderIds.add(orderId);
          }
        } catch (e) {
          // Continuer avec les autres boutiques même en cas d'erreur
          debugPrint('Erreur commande $providerId: $e');
        }
      }

      if (orderIds.isEmpty) {
        setState(() {
          _error = 'Impossible de créer la commande. Veuillez réessayer.';
          _isLoading = false;
        });
        return;
      }

      // Vider le panier
      cartNotifier.clear();

      // Naviguer vers la confirmation
      if (mounted) {
        context.go('/order-confirmation', extra: {
          'orderIds': orderIds,
          'total': cart.totalDa,
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Finaliser')),
        body: const Center(
          child: Text('Votre panier est vide'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Récapitulatif
          _SectionCard(
            title: 'Récapitulatif',
            child: Column(
              children: [
                ...cart.itemsByProvider.entries.map((entry) {
                  final items = entry.value;
                  final providerName = items.first.providerName;
                  final subtotal = items.fold<int>(0, (sum, i) => sum + i.totalDa);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Text(
                            _da(subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(left: 22, top: 4),
                            child: Text(
                              '${item.quantity}× ${item.title}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sous-total'),
                    Text(_da(cart.subtotalDa)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commission',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                    Text(
                      _da(cart.commissionDa),
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _da(cart.totalDa),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _coral,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Livraison
          _SectionCard(
            title: 'Livraison',
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse de livraison',
                    hintText: 'Ex: 123 Rue des Fleurs, Alger',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: 0555 12 34 56',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    hintText: 'Instructions spéciales, étage, etc.',
                    prefixIcon: Icon(Icons.note_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Paiement
          _SectionCard(
            title: 'Paiement',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: _coral),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paiement à la livraison',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Payez en espèces à la réception',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
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
          child: FilledButton(
            onPressed: _isLoading ? null : _placeOrders,
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirmer la commande • ${_da(cart.totalDa)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
