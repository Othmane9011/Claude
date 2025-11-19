// lib/features/map/nearby_vets_map_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

const _coral = Color(0xFFF36C6C);
const _coralLight = Color(0xFFFFEEF0);
const _ink = Color(0xFF222222);

// ---------------- Centre utilisateur (DEVICE -> PROFIL -> fallback) ----------------
final _userCenterProvider = FutureProvider<LatLng>((ref) async {
  try {
    if (await Geolocator.isLocationServiceEnabled()) {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
        final last = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(milliseconds: 300), onTimeout: () => null);
        if (last != null) return LatLng(last.latitude, last.longitude);
        final cur = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 2));
        return LatLng(cur.latitude, cur.longitude);
      }
    }
  } catch (_) {}
  final me = ref.read(sessionProvider).user ?? {};
  final pLat = (me['lat'] as num?)?.toDouble();
  final pLng = (me['lng'] as num?)?.toDouble();
  if (pLat != null && pLng != null && pLat != 0 && pLng != 0) return LatLng(pLat, pLng);
  return const LatLng(36.75, 3.06);
});

// ID du provider courant (pour surligner mon marqueur)
final _myProviderIdProvider = FutureProvider<String?>((ref) async {
  final api = ref.read(apiProvider);
  final meProv = await api.myProvider();
  final id = (meProv?['id'] ?? '').toString();
  return id.isEmpty ? null : id;
});

// ---------------- Tous les pros (le back exclut déjà specialties.visible == false) ----------------
final allVetsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiProvider);
  final center = await ref.watch(_userCenterProvider.future);

  final raw = await api.nearby(
    lat: center.latitude,
    lng: center.longitude,
    radiusKm: 40000.0,
    limit: 5000,
    status: 'approved',
  );

  double? toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // Fallback Haversine si distance_km absente
  double? haversineKm(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    const r = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat - center.latitude);
    final dLng = toRad(lng - center.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(center.latitude)) * math.cos(toRad(lat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  // Normalisation
  final rows = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  bool validNum(dynamic v) => v is num && v.isFinite && v != 0;

  final out = <Map<String, dynamic>>[];
  for (final m in rows) {
    final lat = toDouble(m['lat']);
    final lng = toDouble(m['lng']);
    if (!validNum(lat) || !validNum(lng)) continue;
    m['__lat'] = lat;
    m['__lng'] = lng;
    m['__distKm'] = toDouble(m['distance_km']) ?? haversineKm(lat, lng);
    out.add(m);
  }
  return out;
});

// ---------------- Écran ----------------
class NearbyVetsMapScreen extends ConsumerStatefulWidget {
  const NearbyVetsMapScreen({super.key});
  @override
  ConsumerState<NearbyVetsMapScreen> createState() => _NearbyVetsMapScreenState();
}

class _NearbyVetsMapScreenState extends ConsumerState<NearbyVetsMapScreen> {
  final _mapCtl = MapController();
  LatLng? _center;

  // Filtres (rail vertical)
  bool _showVet = true;
  bool _showDaycare = true;
  bool _showPetshop = true;

  // Carrousel
  final _pageCtl = PageController();
  bool _showCarousel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = await ref.read(_userCenterProvider.future);
      if (!mounted) return;
      setState(() => _center = c);
      _mapCtl.move(c, 12);
    });
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    super.dispose();
  }

  String _kindOf(Map<String, dynamic> m) {
    final sp = (m['specialties'] is Map) ? Map<String, dynamic>.from(m['specialties']) : const {};
    final k = (sp['kind'] ?? m['kind'] ?? '').toString().trim().toLowerCase();
    if (k == 'vet' || k == 'veto' || k == 'vétérinaire') return 'vet';
    if (k == 'daycare' || k == 'garderie') return 'daycare';
    if (k == 'petshop' || k == 'shop') return 'petshop';
    return 'vet';
  }

  bool _explicitInvisible(Map<String, dynamic> m) {
    bool isFalse(dynamic v) {
      if (v is bool) return v == false;
      if (v is String) return v.toLowerCase() == 'false';
      return false;
    }
    if (isFalse(m['visible'])) return true;
    final sp = (m['specialties'] is Map) ? Map<String, dynamic>.from(m['specialties']) : const {};
    if (isFalse(sp['visible'])) return true;
    return false;
  }

  Color _markerColor(String kind, {required bool isMine}) {
    if (isMine) return _coral;
    switch (kind) {
      case 'vet': return Colors.redAccent;
      case 'daycare': return Colors.teal;
      case 'petshop': return Colors.amber;
      default: return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vetsAsync = ref.watch(allVetsProvider);
    final myPidAsync = ref.watch(_myProviderIdProvider);

    return Scaffold(
      // AppBar retirée → on dessine tout en overlay
      body: vetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (rows) {
          // On exclut uniquement les invisibles explicites
          final filtered = <Map<String, dynamic>>[];
          for (final m in rows) {
            if (_explicitInvisible(m)) continue;
            final kind = _kindOf(m);
            if (kind == 'vet' && !_showVet) continue;
            if (kind == 'daycare' && !_showDaycare) continue;
            if (kind == 'petshop' && !_showPetshop) continue;
            filtered.add(m);
          }

          // Tri par distance
          filtered.sort((a, b) {
            final da = (a['__distKm'] as num?)?.toDouble() ?? double.maxFinite;
            final db = (b['__distKm'] as num?)?.toDouble() ?? double.maxFinite;
            return da.compareTo(db);
          });

          final center = _center ?? const LatLng(36.75, 3.06);
          final myPid = myPidAsync.maybeWhen(data: (v) => v, orElse: () => null);

          // Marqueurs
          final markers = <Marker>[
            Marker(
              width: 36, height: 36, point: center,
              child: const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20),
            ),
          ];
          for (final m in filtered) {
            final lat = ((m['__lat'] as num?)?.toDouble())!;
            final lng = ((m['__lng'] as num?)?.toDouble())!;
            final id = (m['id'] ?? '').toString();
            final isMine = (myPid != null && id == myPid);
            final kind = _kindOf(m);
            markers.add(
              Marker(
                width: 44, height: 44, point: LatLng(lat, lng),
                child: _VetMarker(
                  color: _markerColor(kind, isMine: isMine),
                  data: m,
                ),
              ),
            );
          }

          return Stack(
            children: [
              // --- MAP ---
              FlutterMap(
                mapController: _mapCtl,
                options: MapOptions(initialCenter: center, initialZoom: 12),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vethome.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // --- TOP-LEFT : retour (bouton rond blanc/corail) + séparation + filtres ---
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconFab(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () {
                            final nav = Navigator.of(context);
                            if (nav.canPop()) {
                              nav.pop();
                            } else {
                              context.go('/pro/home');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _FilterPill(
                          emoji: '🐶', label: 'Vétos',
                          selected: _showVet,
                          onTap: () => setState(() => _showVet = !_showVet),
                        ),
                        const SizedBox(height: 8),
                        _FilterPill(
                          emoji: '🏡', label: 'Gard.',
                          selected: _showDaycare,
                          onTap: () => setState(() => _showDaycare = !_showDaycare),
                        ),
                        const SizedBox(height: 8),
                        _FilterPill(
                          emoji: '🛍️', label: 'Shops',
                          selected: _showPetshop,
                          onTap: () => setState(() => _showPetshop = !_showPetshop),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- TOP-RIGHT : MAJ / MOI (même style que la flèche) ---
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconFab(
                          icon: Icons.refresh,
                          onTap: () {
                            ref.invalidate(allVetsProvider);
                            ref.invalidate(_userCenterProvider);
                          },
                        ),
                        const SizedBox(width: 8),
                        _IconFab(
                          icon: Icons.my_location,
                          onTap: () async {
                            final c = await ref.read(_userCenterProvider.future);
                            if (!mounted) return;
                            setState(() => _center = c);
                            _mapCtl.move(c, 12);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- FLÈCHE (ouvre carrousel du plus proche au plus loin) ---
              Positioned(
                bottom: _showCarousel ? 200 : 24, left: 0, right: 0,
                child: Center(
                  child: FloatingActionButton(
                    backgroundColor: _coral,
                    heroTag: 'openCarousel',
                    onPressed: () {
                      if (filtered.isEmpty) return;
                      setState(() => _showCarousel = true);
                      // évite "PageController is not attached"
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _pageCtl.jumpToPage(0);
                        final m = filtered.first;
                        _mapCtl.move(LatLng((m['__lat'] as double), (m['__lng'] as double)), 14);
                      });
                    },
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  ),
                ),
              ),

              // --- CARROUSEL ---
              if (_showCarousel)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _ProviderCarousel(
                    pageCtl: _pageCtl,
                    items: filtered,
                    onClose: () => setState(() => _showCarousel = false),
                    onPageChanged: (idx) {
                      if (idx < 0 || idx >= filtered.length) return;
                      final m = filtered[idx];
                      _mapCtl.move(LatLng((m['__lat'] as double), (m['__lng'] as double)), 14);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------- Widgets ----------------
class _VetMarker extends StatelessWidget {
  final Color color;
  final Map<String, dynamic> data;
  const _VetMarker({required this.color, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true, // pour une hauteur adaptée
        builder: (_) => _ProviderSheet(data: data),
      ),
      child: Icon(Icons.location_pin, size: 44, color: color),
    );
  }
}

class _IconFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _IconFab({required this.icon, required this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _coral,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _coral : Colors.white;
    final fg = selected ? Colors.white : _coral;
    final br = selected ? _coral : _coral.withValues(alpha: 0.35);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      elevation: selected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: br),
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, letterSpacing: .2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderSheet extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _ProviderSheet({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = MediaQuery.of(context).size.height;
    final maxH = (h * 0.34).clamp(190.0, 320.0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxH,
          minHeight: 200,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          // Un SEUL bouton "Détail" via la mini-card → pas de doublon
          child: _ProviderMiniCard(provider: data, showDetailOnly: true),
        ),
      ),
    );
  }
}

class _SquareAvatar extends StatelessWidget {
  final String? url;
  final String initial;
  final double size;
  const _SquareAvatar({required this.url, required this.initial, this.size = 64});

  String _fixUrl(String? u) {
    if (u == null || u.isEmpty) return '';
    // Force https sur domaine API pour éviter les 404 http
    if (u.startsWith('http://api.piecespro.com/')) return u.replaceFirst('http://', 'https://');
    return u;
  }

  @override
  Widget build(BuildContext context) {
    final u = _fixUrl(url);
    final radius = BorderRadius.circular(12);
    if (u.isEmpty) {
      return Container(
        width: size, height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _coralLight, borderRadius: radius),
        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        u,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size, height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _coralLight, borderRadius: radius),
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        ),
      ),
    );
  }
}

class _ProviderMiniCard extends ConsumerWidget {
  final Map<String, dynamic> provider;
  final bool showDetailOnly; // pas d’itinéraire ici
  const _ProviderMiniCard({required this.provider, this.showDetailOnly = false});

  String? _photoOf(Map<String, dynamic> m) {
    final p1 = (m['photoUrl'] ?? m['avatar'])?.toString();
    if (p1 != null && p1.isNotEmpty) return p1;
    final user = (m['user'] is Map) ? Map<String, dynamic>.from(m['user']) : const {};
    final p2 = (user['photoUrl'] ?? user['avatar'])?.toString();
    return (p2 != null && p2.isNotEmpty) ? p2 : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiProvider);
    final pid = (provider['id'] ?? '').toString();
    final photo = _photoOf(provider);
    final name  = (provider['displayName'] ?? 'Professionnel').toString();
    final bio   = (provider['bio'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SquareAvatar(url: photo, initial: initial, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: api.listServices(pid),
              builder: (context, snap) {
                final list = (snap.data ?? const <dynamic>[])
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                final top = list.take(3).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (top.isNotEmpty) ...[
  for (final s in top)
    Text(
      '• ${(s['title'] ?? s['name'] ?? 'Consultation').toString()}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.black54),
    ),
  const SizedBox(height: 6),
],

                    //   '• ${(s['title'] ?? s['name'] ?? 'Consultation').toString()} — ${_fmtPrice(...)}'

                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black87, height: 1.25),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final id = (provider['id'] ?? '').toString();
              if (id.isNotEmpty) context.push('/explore/vets/$id');
            },
            child: const Text('Détail'),
          ),
        ],
      ),
    );
  }
}



class _ProviderCarousel extends StatelessWidget {
  final PageController pageCtl;
  final List<Map<String, dynamic>> items;
  final VoidCallback onClose;
  final ValueChanged<int> onPageChanged;
  const _ProviderCarousel({
    required this.pageCtl,
    required this.items,
    required this.onClose,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 40, height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x22000000),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            SizedBox(
              height: 210,
              child: PageView.builder(
                controller: pageCtl,
                onPageChanged: onPageChanged,
                itemCount: items.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: _ProviderMiniCard(provider: items[i], showDetailOnly: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
