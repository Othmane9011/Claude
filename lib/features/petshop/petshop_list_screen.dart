// lib/features/petshop/petshop_list_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api.dart';
import '../../core/session_controller.dart';

/// Provider qui charge la liste des animaleries autour du centre
final _petshopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiProvider);

  // ---------- 1) Centre utilisateur: DEVICE d'abord, puis PROFIL, sinon fallback ----------
  Future<({double lat, double lng})> getCenter() async {
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final last = await Geolocator.getLastKnownPosition().timeout(
            const Duration(milliseconds: 300),
            onTimeout: () => null,
          );
          if (last != null) {
            return (lat: last.latitude, lng: last.longitude);
          }
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(const Duration(seconds: 2));
            return (lat: pos.latitude, lng: pos.longitude);
          } on TimeoutException {
            // Fallback
          } catch (_) {}
        }
      }
    } catch (_) {}

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

  // Récupérer tous les providers et filtrer pour petshop
  final raw = await api.nearby(
    lat: center.lat,
    lng: center.lng,
    radiusKm: 40000.0,
    limit: 5000,
    status: 'approved',
  );

  // Filtrer pour ne garder que les petshops
  final rows = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  final petshops = rows.where((m) {
    final specialties = m['specialties'];
    if (specialties is Map) {
      final kind = (specialties['kind'] ?? '').toString().toLowerCase();
      return kind == 'petshop';
    }
    return false;
  }).toList();

  // Normalisation
  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

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

  final mapped = petshops.map((m) {
    final id = (m['id'] ?? '').toString();
    final name = (m['displayName'] ?? m['name'] ?? 'Animalerie').toString();
    final bio = (m['bio'] ?? '').toString();
    final address = (m['address'] ?? '').toString();

    double? dKm = _toDouble(m['distance_km']);
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

  // Dédoublonnage
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

class PetshopListScreen extends ConsumerStatefulWidget {
  const PetshopListScreen({super.key});

  @override
  ConsumerState<PetshopListScreen> createState() => _PetshopListScreenState();
}

class _PetshopListScreenState extends ConsumerState<PetshopListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_petshopsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_petshopsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animaleries'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(_petshopsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger',
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Aucune animalerie trouvée.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_petshopsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final m = rows[i];
                return _PetshopRow(
                  id: (m['id'] ?? '').toString(),
                  name: (m['displayName'] ?? 'Animalerie').toString(),
                  distanceKm: m['distanceKm'] as double?,
                  bio: (m['bio'] ?? '').toString(),
                  address: (m['address'] ?? '').toString(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PetshopRow extends StatelessWidget {
  const _PetshopRow({
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
    return inits.isEmpty ? 'SH' : inits;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/explore/petshop/$id'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFFEEF0),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: Colors.pink[400],
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (distanceKm != null) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(Icons.place, size: 16, color: Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      '${distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



