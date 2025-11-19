// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

/// Palette saumon (rose crevette)
const _salmon = Color(0xFFF36C6C);
const _salmonDark = Color(0xFFD55858);
const _salmonSoft = Color(0xFFFFE7E7);
const _ink = Colors.black87;

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // 'pending' | 'approved' | 'rejected'
  String _tab = 'pending';

  Future<List<dynamic>> _load(String status) async {
    final api = ref.read(apiProvider);
    await api.ensureAuth();
    return await api.listProviderApplications(status: status, limit: 100, offset: 0);
  }

  Future<void> _approve(String providerId) async {
    final api = ref.read(apiProvider);
    await api.ensureAuth();
    await api.approveProvider(providerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Approuvé ✅')),
    );
    setState(() {}); // reload
  }

  Future<void> _reject(String providerId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la candidature ?'),
        content: const Text("Le profil sera marqué comme rejeté. Vous pourrez le ré-approuver plus tard."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rejeter')),
        ],
      ),
    );
    if (ok != true) return;

    final api = ref.read(apiProvider);
    await api.ensureAuth();
    await api.rejectProvider(providerId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejeté ❌')));
    setState(() {}); // reload
  }

  // ===== Helpers carte statique (preview non cliquable) =====

String? _staticMapUrl(double? lat, double? lng, {int w = 900, int h = 360, int z = 16}) {
  if (lat == null || lng == null) return null;
  if (lat == 0 || lng == 0) return null;
  final ll = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  const base = 'https://staticmap.openstreetmap.de/staticmap.php';
  // Pas de cb=... -> laisse le cache HTTP travailler
  return '$base?center=$ll&zoom=$z&size=${w}x$h&maptype=mapnik&markers=$ll,red-pushpin';
}


  // ====== Sanitize + petite extraction lat/lng côté admin (confort) ======

  String _sanitizeMaps(String u) {
    final raw = u.trim();
    if (raw.isEmpty) return '';
    final withScheme = RegExp(r'^(https?://)', caseSensitive: false).hasMatch(raw) ? raw : 'https://$raw';
    Uri uri;
    try {
      uri = Uri.parse(withScheme);
    } catch (_) {
      return raw;
    }

    const banned = {
      'ts','entry','g_ep','utm_source','utm_medium','utm_campaign','utm_term','utm_content','hl','ved','source','opi','sca_esv'
    };
    final qp = Map<String, String>.from(uri.queryParameters)..removeWhere((k, _) => banned.contains(k));
    var path = uri.path.replaceAll(RegExp(r'/+'), '/');
    // On garde /data=!… si la cible contient des coords ou un identifiant utile, sinon on purge
    final hasImportant = RegExp(r'/data=![^/?#]*(?:!3d|!4d|:0x|ChI)', caseSensitive: false).hasMatch(path);
    if (!hasImportant) {
      path = path.replaceAll(RegExp(r'/data=![^/?#]*'), '');
    }
    final clean = uri.replace(queryParameters: qp, path: path);
    return clean.toString().replaceAll(RegExp(r'[?#]$'), '');
  }

  ({double? lat, double? lng}) _extractLatLngFromUrl(String url) {
    final s = url.trim();
    if (s.isEmpty) return (lat: null, lng: null);
    final dec = Uri.decodeFull(s);

    // @lat,lng
    final at = RegExp(r'@(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)').allMatches(dec).toList();
    if (at.isNotEmpty) {
      final m = at.last;
      final lat = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      final lng = double.tryParse(m.group(2)!.replaceAll(',', '.'));
      if (lat != null && lng != null) return (lat: lat, lng: lng);
    }

    // !3dlat!4dlng  ou  !4dlng!3dlat
    final m34 = RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(dec);
    if (m34 != null) {
      final lat = double.tryParse(m34.group(1)!.replaceAll(',', '.'));
      final lng = double.tryParse(m34.group(2)!.replaceAll(',', '.'));
      return (lat: lat, lng: lng);
    }
    final m43 = RegExp(r'!4d(-?\d+(?:\.\d+)?)!3d(-?\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(dec);
    if (m43 != null) {
      final lat = double.tryParse(m43.group(2)!.replaceAll(',', '.'));
      final lng = double.tryParse(m43.group(1)!.replaceAll(',', '.'));
      return (lat: lat, lng: lng);
    }

    return (lat: null, lng: null);
  }

  // ===== Feuille “détail + validation” =====

Future<void> _openProviderSheet(Map<String, dynamic> p) async {
  final provId = (p['id'] ?? '') as String;
  final name = (p['displayName'] ?? '') as String;
  final addr = (p['address'] ?? '') as String;
  final approved = (p['isApproved'] == true);
  final appliedAt = (p['appliedAt'] ?? '').toString();
  final rejectedAt = (p['rejectedAt'] ?? '').toString();
  final specialties = (p['specialties'] as Map?) ?? const {};
  final user = (p['user'] as Map?) ?? const {};
  final email = (user['email'] ?? '') as String;
  final phone = (user['phone'] ?? '') as String?;

  final currentLat = (p['lat'] as num?)?.toDouble();
  final currentLng = (p['lng'] as num?)?.toDouble();
  final currentMaps = (specialties['mapsUrl'] ?? '').toString();

  final mapsCtrl = TextEditingController(text: currentMaps);
  final latCtrl  = TextEditingController(text: currentLat == null ? '' : currentLat.toStringAsFixed(6));
  final lngCtrl  = TextEditingController(text: currentLng == null ? '' : currentLng.toStringAsFixed(6));

  String? errMaps, errLat, errLng;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) {
      bool saving = false;

      Future<void> saveEdits(StateSetter setLocal) async {
        // 1) validations
        final maps = mapsCtrl.text.trim();
        final mapsOk = maps.isEmpty || RegExp(r'^(https?://)', caseSensitive: false).hasMatch(maps);
        double? lat = double.tryParse(latCtrl.text.replaceAll(',', '.'));
        double? lng = double.tryParse(lngCtrl.text.replaceAll(',', '.'));

        // 2) extraction auto si coords manquantes mais URL fournie
        if ((lat == null || lng == null) && maps.isNotEmpty) {
          final e = _extractLatLngFromUrl(maps);
          lat ??= e.lat;
          lng ??= e.lng;
        }

        setLocal(() {
          errMaps = mapsOk ? null : 'URL invalide';
          errLat  = (lat == null) ? 'Latitude invalide'  : null;
          errLng  = (lng == null) ? 'Longitude invalide' : null;
        });
        if (!mapsOk || lat == null || lng == null) return;

        // 3) appel API
        setLocal(() => saving = true);
        try {
          final sanitized = maps.isEmpty ? '' : _sanitizeMaps(maps);
          await ref.read(apiProvider).adminUpdateProvider(
            provId,
            lat: lat,
            lng: lng,
            mapsUrl: sanitized,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modifications enregistrées')),
          );
          Navigator.pop(ctx);            // ferme le sheet
          setState(() {});               // relance le FutureBuilder de la liste
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        } finally {
          if (mounted) setLocal(() => saving = false);
        }
      }

      return DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => StatefulBuilder(
          builder: (ctx, setLocal) {
            final double? lat = double.tryParse(latCtrl.text.replaceAll(',', '.'));
            final double? lng = double.tryParse(lngCtrl.text.replaceAll(',', '.'));
            final previewUrl = _staticMapUrl(lat, lng);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ListView(
                  controller: scroll,
                  children: [
                    // header
                    Row(
                      children: [
                        CircleAvatar(radius: 24, backgroundColor: _salmonSoft,
                          child: Text((name.isEmpty ? email : name).substring(0,1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? '(Sans nom)' : name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Wrap(spacing: 8, runSpacing: 6, children: [
                              Chip(label: Text(
                                (rejectedAt.isNotEmpty) ? 'REJETÉ' : ( (p['isApproved']==true) ? 'APPROUVÉ' : 'EN ATTENTE'),
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                                backgroundColor: (rejectedAt.isNotEmpty) ? Colors.redAccent
                                  : ( (p['isApproved']==true) ? Colors.green : Colors.orange),
                                visualDensity: VisualDensity.compact),
                            ]),
                          ],
                        )),
                        IconButton(tooltip: 'Appeler', icon: const Icon(Icons.call),
                          onPressed: () => _showCallSheet(phone, name: name.isEmpty ? email : name)),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(),

                    // coordonnées simples
                    const Text('Coordonnées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    _kv('Email', email),
                    _kv('Téléphone', (phone ?? '').isEmpty ? '—' : phone!),
                    _kv('Adresse', addr.isEmpty ? '—' : addr),

                    const SizedBox(height: 14),
                    const Divider(),

                    // localisation
                    const Text('Validation de la localisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),

                    _label('Lien Google Maps (PC, court ou long)'),
                    TextField(
                      controller: mapsCtrl,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        isDense: true,
                        errorText: errMaps,
                        hintText: 'https://www.google.com/maps/... ou https://maps.app.goo.gl/...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Nettoyer',
                              icon: const Icon(Icons.link),
                              onPressed: () {
                                final s = _sanitizeMaps(mapsCtrl.text);
                                setLocal(() => mapsCtrl.text = s);
                              },
                            ),
                            IconButton(
                              tooltip: 'Extraire coords',
                              icon: const Icon(Icons.my_location),
                              onPressed: () {
                                final e = _extractLatLngFromUrl(mapsCtrl.text);
                                if (e.lat != null && e.lng != null) {
                                  setLocal(() {
                                    latCtrl.text = e.lat!.toStringAsFixed(6);
                                    lngCtrl.text = e.lng!.toStringAsFixed(6);
                                    errLat = null; errLng = null;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Aucune coordonnée trouvée dans l’URL')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Latitude'),
                        TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))],
                          decoration: InputDecoration(isDense: true, errorText: errLat,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          onChanged: (_) => setLocal(() {}),
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Longitude'),
                        TextField(
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))],
                          decoration: InputDecoration(isDense: true, errorText: errLng,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          onChanged: (_) => setLocal(() {}),
                        ),
                      ])),
                    ]),

                    const SizedBox(height: 12),
                    _MapPreviewCard(url: previewUrl),

                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save, color: _salmon),
                          label: Text(saving ? 'Enregistrement…' : 'Enregistrer',
                            style: const TextStyle(color: _salmon)),
                          onPressed: saving ? null : () => saveEdits(setLocal),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: _salmon)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!approved && rejectedAt.isEmpty)
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.verified),
                            label: const Text('Approuver'),
                            onPressed: saving ? null : () async {
                              await saveEdits(setLocal);
                              // saveEdits ferme le sheet et rafraîchit la liste
                              await _approve(provId);
                            },
                            style: FilledButton.styleFrom(backgroundColor: _salmon),
                          ),
                        )
                      else if (!approved && rejectedAt.isNotEmpty)
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Ré-approuver'),
                            onPressed: saving ? null : () async {
                              Navigator.pop(ctx);
                              await _approve(provId);
                              setState(() {});
                            },
                            style: FilledButton.styleFrom(backgroundColor: _salmon),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.block, color: Colors.red),
                            label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                            onPressed: saving ? null : () async {
                              Navigator.pop(ctx);
                              await _reject(provId);
                              setState(() {});
                            },
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}


  // ===== UI principal =====

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).user;
    final role = (user?['role'] as String?) ?? 'USER';
    if (role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Accès refusé (ADMIN requis)'),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Revenir')),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: _salmon, secondary: _salmon),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: _salmon, foregroundColor: Colors.white),
        ),
        chipTheme: Theme.of(context).chipTheme.copyWith(
          side: const BorderSide(color: Colors.transparent),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(color: Color(0x11000000)),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin — Candidatures Pro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await ref.read(sessionProvider.notifier).logout();
                if (!mounted) return;
                context.go('/auth/login?as=pro');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _salmonSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _salmon.withValues(alpha: 0.35)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    color: _ink,
                    fillColor: _salmon,
                    isSelected: [
                      _tab == 'pending',
                      _tab == 'approved',
                      _tab == 'rejected',
                    ],
                    onPressed: (i) {
                      setState(() {
                        _tab = (i == 0) ? 'pending' : (i == 1) ? 'approved' : 'rejected';
                      });
                    },
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('En attente')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Approuvés')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('Rejetés')),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _load(_tab),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erreur: ${snap.error}'));
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(child: Text('Aucune candidature'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = items[i] as Map<String, dynamic>;
                        final id = (p['id'] ?? '') as String;
                        final name = (p['displayName'] ?? '') as String;
                        final addr = (p['address'] ?? '') as String;
                        final approved = (p['isApproved'] == true);
                        final rejectedAt = (p['rejectedAt'] ?? '').toString();
                        final u = (p['user'] as Map?) ?? const {};
                        final email = (u['email'] ?? '') as String;
                        final phone = (u['phone'] ?? '') as String?;

                        return ListTile(
                          onTap: () => _openProviderSheet(p),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _salmonSoft,
                            child: Text(
                              (name.isEmpty ? email : name).substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
                            ),
                          ),
                          title: Text(
                            name.isEmpty ? '(Sans nom)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (email.isNotEmpty) email,
                              if (addr.isNotEmpty) addr,
                            ].join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Appeler',
                                icon: const Icon(Icons.call),
                                onPressed: () => _showCallSheet(phone, name: name.isEmpty ? email : name),
                              ),
                              if (!approved && rejectedAt.isEmpty) ...[
                                TextButton(
                                  onPressed: () => _reject(id),
                                  child: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  onPressed: () => _approve(id),
                                  child: const Text('Approuver'),
                                ),
                              ] else if (!approved && rejectedAt.isNotEmpty) ...[
                                FilledButton(
                                  onPressed: () => _approve(id),
                                  child: const Text('Ré-approuver'),
                                ),
                              ] else ...[
                                const Icon(Icons.verified, color: Colors.green),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers communs =====

  Future<void> _showCallSheet(String? phone, {String? name}) async {
    final p = (phone ?? '').trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name == null || name.isEmpty ? 'Téléphone' : 'Téléphone — $name',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(p.isEmpty ? '—' : p,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      tooltip: 'Copier',
                      onPressed: p.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: p));
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Numéro copié')),
                              );
                            },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(k, style: TextStyle(color: Colors.black.withValues(alpha: 0.6)))),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _label(String s) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13)));
}

class _MapPreviewCard extends StatelessWidget {
  final String? url;
  const _MapPreviewCard({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Prévisualisation indisponible — coordonnées manquantes'),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url!,
              key: ValueKey(url),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (c, child, prog) {
                if (prog == null) return child;
                return Container(
                  color: Colors.black.withValues(alpha: 0.04),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (c, err, st) => Container(
                color: Colors.black.withOpacity(0.04),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: const Text('Impossible de charger la carte'),
              ),
            ),
          ),
          // Non-cliquable
          Positioned.fill(child: IgnorePointer(child: Container(color: Colors.transparent))),
        ],
      ),
    );
  }
}
