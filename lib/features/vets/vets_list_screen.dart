// lib/features/vets/vets_list_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

const _coral = Color(0xFFF36C6C);
const _coralSoft = Color(0xFFFFEEF0);
const _ink = Color(0xFF222222);

/// Provider qui charge la liste des vétos autour du centre (device -> profil -> fallback)
final _vetsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiProvider);

  // ---------- 1) Centre utilisateur: DEVICE d'abord, puis PROFIL, sinon fallback ----------
  Future<({double lat, double lng})> getCenter() async {
    // a) Device (GPS/Wi-Fi) — timeouts courts pour éviter les spinners infinis
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          // Last known (ultra rapide)
          final last = await Geolocator.getLastKnownPosition().timeout(
            const Duration(milliseconds: 300),
            onTimeout: () => null,
          );
          if (last != null) {
            return (lat: last.latitude, lng: last.longitude);
          }
          // Current position (timeout court)
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(const Duration(seconds: 2));
            return (lat: pos.latitude, lng: pos.longitude);
          } on TimeoutException {
            // On tombera sur profil/fallback
          } catch (_) {
            // ignore et on tombe sur profil/fallback
          }
        }
      }
    } catch (_) {/* ignore */}

    // b) Profil utilisateur (fallback)
    final me = ref.read(sessionProvider).user ?? {};
    final pLat = (me['lat'] as num?)?.toDouble();
    final pLng = (me['lng'] as num?)?.toDouble();
    if (pLat != null && pLng != null && pLat != 0 && pLng != 0) {
      return (lat: pLat, lng: pLng);
    }

    // c) Fallback absolu (Alger)
    return (lat: 36.75, lng: 3.06);
  }

  final center = await getCenter();

  // ---------- 2) API: on récupère les pros depuis le backend ----------
  final raw = await api.nearby(
    lat: center.lat,
    lng: center.lng,
    radiusKm: 40000.0,
    limit: 5000,
    status: 'approved',
  );

  // ---------- 3) Normalisation légère côté client ----------
  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // Haversine (fallback au cas où le backend n'aurait pas mis distance_km)
  double? _haversineKm(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    const R = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(lat - center.lat);
    final dLng = toRad(lng - center.lng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(center.lat)) * math.cos(toRad(lat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  final rows = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  // Filter to only show vets (exclude petshops and daycares)
  final vetsOnly = rows.where((m) {
    final specialties = m['specialties'] as Map<String, dynamic>?;
    final kind = (specialties?['kind'] ?? '').toString().toLowerCase();
    return kind == 'vet' || kind.isEmpty; // Include if vet or no kind specified
  }).toList();

  // On prépare l'output minimum: id, displayName, bio, address, distanceKm
  final mapped = vetsOnly.map((m) {
    final id = (m['id'] ?? m['providerId'] ?? '').toString();
    final name = (m['displayName'] ?? m['name'] ?? 'Vétérinaire').toString();
    final bio = (m['bio'] ?? '').toString();
    final address = (m['address'] ?? '').toString();

    // distance_km fournie par le backend si centre valide
    double? dKm = _toDouble(m['distance_km']);

    // Fallback si distance_km manquante: calcule localement avec lat/lng
    if (dKm == null) {
      final lat = _toDouble(m['lat']);
      final lng = _toDouble(m['lng']);
      dKm = _haversineKm(lat, lng);
    }

    return <String, dynamic>{
      'id': id,
      'displayName': name,
      'bio': bio,
      'address': address,
      'distanceKm': dKm,
    };
  }).toList();

  // Dédoublonnage soft
  final seen = <String>{};
  final unique = <Map<String, dynamic>>[];
  for (final m in mapped) {
    final id = (m['id'] as String?) ?? '';
    final key = id.isNotEmpty
        ? 'id:$id'
        : 'na:${(m['displayName'] ?? '').toString().toLowerCase()}';
    if (seen.add(key)) unique.add(m);
  }

  // Tri: distance si dispo, sinon nom
  unique.sort((a, b) {
    final da = a['distanceKm'] as double?;
    final db = b['distanceKm'] as double?;
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    final na = (a['displayName'] ?? '').toString().toLowerCase();
    final nb = (b['displayName'] ?? '').toString().toLowerCase();
    return na.compareTo(nb);
  });

  return unique;
});

class VetListScreen extends ConsumerStatefulWidget {
  const VetListScreen({super.key});
  @override
  ConsumerState<VetListScreen> createState() => _VetListScreenState();
}

class _VetListScreenState extends ConsumerState<VetListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Réévalue à chaque ouverture (nouvelle géoloc)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_vetsProvider);
    });
  }

  List<Map<String, dynamic>> _filterVets(List<Map<String, dynamic>> vets) {
    return vets.where((vet) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (vet['displayName'] ?? '').toString().toLowerCase();
        final address = (vet['address'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !address.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_vetsProvider);

    return Theme(
      data: _themed(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Column(
            children: [
              // Custom header
              _buildHeader(context),

              // Content
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: _coral)),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (rows) {
                    final filtered = _filterVets(rows);
                    if (filtered.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      color: _coral,
                      onRefresh: () async => ref.invalidate(_vetsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final m = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VetCard(
                              id: (m['id'] ?? '').toString(),
                              name: (m['displayName'] ?? 'Vétérinaire').toString(),
                              distanceKm: m['distanceKm'] as double?,
                              bio: (m['bio'] ?? '').toString(),
                              address: (m['address'] ?? '').toString(),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: _coralSoft,
                  foregroundColor: _coral,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vétérinaires',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Trouvez un vétérinaire proche de vous',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(_vetsProvider),
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: _coralSoft,
                  foregroundColor: _coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un vétérinaire...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _coral, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _coralSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_hospital, size: 48, color: _coral),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun vétérinaire trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres termes'
                : 'Aucun vétérinaire disponible pour le moment',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(() => _searchQuery = ''),
              style: OutlinedButton.styleFrom(
                foregroundColor: _coral,
                side: const BorderSide(color: _coral),
              ),
              child: const Text('Effacer la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  ThemeData _themed(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: _coral,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _coral),
    );
  }
}

class _VetCard extends StatelessWidget {
  const _VetCard({
    required this.id,
    required this.name,
    required this.bio,
    required this.address,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String bio;
  final String address;
  final double? distanceKm;

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final inits = parts.take(2).map((e) => e[0]).join().toUpperCase();
    return inits.isEmpty ? 'DR' : inits;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/explore/vets/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with initials
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _coralSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: _coral,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _ink,
                          ),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (distanceKm != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _coralSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 12, color: _coral),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Bottom row with action
              Row(
                children: [
                  // Availability indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Disponible',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // View profile button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir profil',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
