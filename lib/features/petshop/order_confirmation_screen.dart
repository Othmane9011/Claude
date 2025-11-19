// lib/features/petshop/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _coral = Color(0xFFF36C6C);

class OrderConfirmationScreen extends StatelessWidget {
  final List<String> orderIds;
  final int total;

  const OrderConfirmationScreen({
    super.key,
    required this.orderIds,
    required this.total,
  });

  String _da(int v) => '${NumberFormat.decimalPattern("fr_FR").format(v)} DA';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icône de succès
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green[600],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Commande confirmée !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                orderIds.length > 1
                    ? '${orderIds.length} commandes ont été créées'
                    : 'Votre commande a été créée',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Montant total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total à payer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _da(total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _coral,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Numéros de commande
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          orderIds.length > 1 ? 'Numéros de commande' : 'Numéro de commande',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...orderIds.map((id) => Text(
                          id.length > 8 ? '${id.substring(0, 8)}...' : id,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le vendeur vous contactera pour confirmer la livraison. Paiement à la réception.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Boutons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/my-orders'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _coral,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Voir mes commandes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Retour à l\'accueil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
