import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProApplicationSubmittedScreen extends StatelessWidget {
  const ProApplicationSubmittedScreen({super.key});

  static const coral = Color(0xFFF36C6C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/gate'), // ⬅️ retour à la page n°1 (RoleGateScreen)
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône circulaire
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    color: coral.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.mark_email_read_rounded, size: 44, color: coral),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'C’est envoyé !',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Merci. Nous vous contacterons dans les plus brefs délais '
                  'pour confirmer votre compte vétérinaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.35, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                // Bandeau info: compte inactif tant que non validé par l’admin
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.info_outline, size: 18, color: Colors.black87),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre compte professionnel est en attente de validation par un administrateur. '
                          'Vous ne pourrez pas utiliser les fonctionnalités PRO tant qu’il n’aura pas été activé.',
                          style: TextStyle(fontSize: 13.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Boutons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: coral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => context.go('/gate'), // ⬅️ vers la page de départ
                    child: const Text('Revenir à l’accueil'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Revenir à l’inscription'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
