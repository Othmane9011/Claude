import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

class DaycareHomeScreen extends ConsumerStatefulWidget {
  const DaycareHomeScreen({super.key});

  @override
  ConsumerState<DaycareHomeScreen> createState() => _DaycareHomeScreenState();
}

class _DaycareHomeScreenState extends ConsumerState<DaycareHomeScreen> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Map<String, dynamic>? _unwrap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map && raw.containsKey('data')) {
      final d = raw['data'];
      if (d == null || (d is Map && d.isEmpty)) return null;
      return (d is Map) ? Map<String, dynamic>.from(d) : null;
    }
    if (raw is Map && raw.isEmpty) return null;
    return (raw is Map) ? Map<String, dynamic>.from(raw) : null;
  }

  bool _isApproved(Map<String, dynamic>? p) => p?['isApproved'] == true;
  bool _isRejected(Map<String, dynamic>? p) {
    if (p == null) return false;
    final v = p['rejectedAt'];
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    return true;
  }

  Future<Map<String, dynamic>?> _load() async {
    final api = ref.read(apiProvider);
    await api.ensureAuth();
    final raw = await api.myProvider();
    return _unwrap(raw);
  }

  Future<void> _logout() async {
    await ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;
    context.go('/auth/login?as=pro');
  }

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF36C6C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garderie — Tableau de bord'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erreur: ${snap.error}'));
          }
          final p = snap.data;

          if (p == null) {
            return _EmptyState(
              title: 'Aucun profil pro trouvé',
              message:
                  'Créez un compte pro (garderie) afin d’accéder à votre tableau de bord.',
              cta: 'Créer mon compte pro',
              onTap: () => context.go('/auth/register?as=pro'),
            );
          }

          final name = (p['displayName'] ?? '') as String? ?? '';
          final addr = (p['address'] ?? '') as String? ?? '';
          final approved = _isApproved(p);
          final rejected = _isRejected(p);
          final reason = (p['rejectionReason'] ?? '') as String? ?? '';

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (rejected)
                  _StatusBanner(
                    color: Colors.redAccent,
                    text: 'Votre candidature a été rejetée.',
                    trailing: TextButton(
                      onPressed: () => context.go('/pro/application/rejected'),
                      child: const Text('Voir détails'),
                    ),
                  )
                else if (!approved)
                  _StatusBanner(
                    color: Colors.orange,
                    text: 'Votre candidature est en attente d’approbation.',
                    trailing: TextButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Actualiser'),
                    ),
                  ),

                // En-tête
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black12,
                      child: Text(
                        (name.isEmpty ? 'G' : name.substring(0, 1)).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? '(Sans nom)' : name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(addr.isEmpty ? '—' : addr,
                              style: TextStyle(color: Colors.black.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        rejected
                            ? 'REJETÉ'
                            : (approved ? 'APPROUVÉ' : 'EN ATTENTE'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      backgroundColor:
                          rejected ? Colors.redAccent : (approved ? Colors.green : Colors.orange),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),

                // Actions principales (placeholders)
                const SizedBox(height: 12),
                _SectionTitle('Actions'),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.calendar_month,
                  title: 'Planning (bientôt)',
                  subtitle: 'Gérez vos créneaux et disponibilités.',
                  onTap: () => _toast(context, 'Planning — bientôt disponible'),
                ),
                _ActionTile(
                  icon: Icons.event_available,
                  title: 'Réservations (bientôt)',
                  subtitle: 'Consultez et confirmez vos demandes.',
                  onTap: () => _toast(context, 'Réservations — bientôt disponible'),
                ),
                _ActionTile(
                  icon: Icons.pets_outlined,
                  title: 'Services (bientôt)',
                  subtitle: 'Ajoutez/éditez vos prestations de garderie.',
                  onTap: () => _toast(context, 'Services — bientôt disponible'),
                ),

                if (rejected && reason.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  _SectionTitle('Motif du rejet'),
                  const SizedBox(height: 6),
                  _NoteBox(reason),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: coral,
        onPressed: () => _toast(context, 'Créer une réservation — bientôt'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  static void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final String text;
  final Widget? trailing;
  const _StatusBanner({required this.color, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;
  const _NoteBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String cta;
  final VoidCallback onTap;
  const _EmptyState({required this.title, required this.message, required this.cta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pets, size: 56),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: Text(cta)),
            ],
          ),
        ),
      ),
    );
  }
}
