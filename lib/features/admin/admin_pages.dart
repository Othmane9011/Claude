import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import 'admin_shared.dart';
import 'admin_editor.dart';

/// ================= Thème admin (saumon) =================
ThemeData _adminTheme(BuildContext context) {
  final base = Theme.of(context);
  const salmon = AdminColors.salmon;
  const ink = AdminColors.ink;
  const soft = Color(0xFFFFE7E7);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: salmon,
      secondary: salmon,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(salmon),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(salmon.withValues(alpha:.12)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(salmon),
        side: const WidgetStatePropertyAll(
          BorderSide(color: salmon, width: 1.2),
        ),
        overlayColor: WidgetStatePropertyAll(salmon.withValues(alpha:.08)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      fillColor: salmon,
      selectedColor: Colors.white,
      color: ink,
      borderRadius: BorderRadius.circular(10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: salmon),
    dividerColor: soft,
  );
}

/// ================= Helpers =================
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _firstLetter(String s) =>
    s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();

/// Canonicalise 'YYYY-M' → 'YYYY-MM'
String _canonYm(String s) {
  final t = s.replaceAll('/', '-').trim();
  final m = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(t) ??
      RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(t);
  if (m == null) return t;
  final y = m.group(1)!;
  final mo = int.parse(m.group(2)!);
  return '$y-${mo.toString().padLeft(2, '0')}';
}

/// ============ Badges status (soft #FFE7E7 + emoji blanc) ============
class _StatusEmojiBar extends StatelessWidget {
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;
  const _StatusEmojiBar({
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
  });

  static const _soft = Color(0xFFFFE7E7);

  Widget _chip(String emoji, int n) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AdminColors.salmon.withValues(alpha:.55),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AdminColors.salmon,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$n',
              style: const TextStyle(
                color: AdminColors.salmon,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('⏳', pending),
          const SizedBox(width: 8),
          _chip('📅', confirmed),
          const SizedBox(width: 8),
          _chip('✅', completed),
          const SizedBox(width: 8),
          _chip('❌', cancelled),
        ],
      ),
    );
  }
}

Widget _pillMini(String emoji, int n) {
  const soft = Color(0xFFFFE7E7);
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 32),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminColors.salmon.withValues(alpha:.55),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AdminColors.salmon,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$n',
            style: const TextStyle(
              color: AdminColors.salmon,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

/// ===========================================================
/// ===================== USERS ===============================
/// ===========================================================
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});
  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _q = TextEditingController();

Future<List<Map<String, dynamic>>> _load() async {
  final api = ref.read(apiProvider);
  // On filtre explicitement les clients (role=USER)
  final rows = await api.adminListUsers(
    q: _q.text.trim(),
    role: 'USER',
    limit: 1000,
    offset: 0,
  );
  return rows.map<Map<String, dynamic>>((e) {
    return (e is Map)
        ? Map<String, dynamic>.from(e)
        : <String, dynamic>{};
  }).toList();
}


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminTheme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Clients')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _q,
                decoration: InputDecoration(
                  hintText: 'Rechercher nom, email, téléphone…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _load(),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erreur: ${snap.error}'));
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(child: Text('Aucun résultat'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final m = items[i];
                        final email = (m['email'] ?? '').toString();
                        final first = (m['firstName'] ?? '').toString();
                        final last = (m['lastName'] ?? '').toString();
                        final phone = (m['phone'] ?? '').toString();
                        final role = (m['role'] ?? '').toString();
                        final name = [
                          first,
                          last,
                        ].where((e) => e.trim().isNotEmpty).join(' ').trim();
                        final avatarSeed = (name.isEmpty ? email : name);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFE7E7),
                            child: Text(
                              _firstLetter(avatarSeed),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
                            ),
                          ),
                          title: Text(
                            name.isEmpty ? '(Sans nom)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              email,
                              if (phone.isNotEmpty) phone,
                              if (role.isNotEmpty) 'role=$role',
                            ].join(' • '),
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
}

/// ===========================================================
/// ================= PROS APPROUVÉS ==========================
/// ===========================================================
class AdminProsApprovedPage extends ConsumerStatefulWidget {
  const AdminProsApprovedPage({super.key});
  @override
  ConsumerState<AdminProsApprovedPage> createState() =>
      _AdminProsApprovedPageState();
}

class _AdminProsApprovedPageState extends ConsumerState<AdminProsApprovedPage> {
  final _q = TextEditingController();

  Future<List<dynamic>> _load() async {
    final api = ref.read(apiProvider);
    final rows = await api.listProviderApplications(
      status: 'approved',
      limit: 1000,
    );
    final needle = _q.text.trim().toLowerCase();
    if (needle.isEmpty) return rows;
    return rows.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final name = (m['displayName'] ?? '').toString().toLowerCase();
      final addr = (m['address'] ?? '').toString().toLowerCase();
      final u = Map<String, dynamic>.from((m['user'] ?? const {}) as Map);
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(needle) ||
          addr.contains(needle) ||
          email.contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminTheme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Pros approuvés')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _q,
                decoration: InputDecoration(
                  hintText: 'Rechercher pro…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _load(),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erreur: ${snap.error}'));
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(child: Text('Aucun pro approuvé'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = Map<String, dynamic>.from(items[i] as Map);
                        final name = (p['displayName'] ?? '').toString();
                        final addr = (p['address'] ?? '').toString();
                        final u = Map<String, dynamic>.from(
                          (p['user'] ?? const {}) as Map,
                        );
                        final email = (u['email'] ?? '').toString();
                        final lat = (p['lat'] as num?)?.toDouble();
                        final lng = (p['lng'] as num?)?.toDouble();

                        final avatarSeed = (name.isEmpty ? email : name);
                        return ListTile(
                          onTap: () => showProviderEditor(
                            context,
                            ref,
                            p,
                            mode: ProviderEditorMode.approved,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFE7E7),
                            child: Text(
                              _firstLetter(avatarSeed),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
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
                              if (lat != null && lng != null)
                                'lat=${lat.toStringAsFixed(4)} lng=${lng.toStringAsFixed(4)}',
                            ].join(' • '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
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
}

/// ===========================================================
/// ==================== CANDIDATURES =========================
/// ===========================================================
class AdminApplicationsPage extends ConsumerStatefulWidget {
  const AdminApplicationsPage({super.key});
  @override
  ConsumerState<AdminApplicationsPage> createState() =>
      _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends ConsumerState<AdminApplicationsPage> {
  String _tab = 'pending'; // 'pending' | 'rejected'
  Future<List<dynamic>> _load() =>
      ref.read(apiProvider).listProviderApplications(status: _tab, limit: 1000);

  @override
  Widget build(BuildContext context) {
    final chipStyle = Theme.of(context).chipTheme.copyWith(
      side: const BorderSide(color: Colors.transparent),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Theme(
      data: _adminTheme(context).copyWith(chipTheme: chipStyle),
      child: Scaffold(
        appBar: AppBar(title: const Text('Candidatures')),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AdminColors.salmon.withValues(alpha:0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    color: AdminColors.ink,
                    fillColor: AdminColors.salmon,
                    isSelected: [_tab == 'pending', _tab == 'rejected'],
                    onPressed: (i) =>
                        setState(() => _tab = i == 0 ? 'pending' : 'rejected'),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('En attente'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Rejetées'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _load(),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erreur: ${snap.error}'));
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _tab == 'pending'
                            ? 'Aucune candidature'
                            : 'Aucun rejet',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = Map<String, dynamic>.from(items[i] as Map);
                        final id = (p['id'] ?? '').toString();
                        final name = (p['displayName'] ?? '').toString();
                        final addr = (p['address'] ?? '').toString();
                        final u = Map<String, dynamic>.from(
                          (p['user'] ?? const {}) as Map,
                        );
                        final email = (u['email'] ?? '').toString();

                        final avatarSeed = (name.isEmpty ? email : name);
                        return ListTile(
                          onTap: () => showProviderEditor(
                            context,
                            ref,
                            p,
                            mode: _tab == 'pending'
                                ? ProviderEditorMode.pending
                                : ProviderEditorMode.rejected,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFE7E7),
                            child: Text(
                              _firstLetter(avatarSeed),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AdminColors.ink,
                              ),
                            ),
                          ),
                          title: Text(
                            name.isEmpty ? '(Sans nom)' : name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [email, if (addr.isNotEmpty) addr].join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_tab == 'pending') ...[
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(apiProvider)
                                        .rejectProvider(id);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Rejeté ❌')),
                                    );
                                    setState(() {});
                                  },
                                  child: const Text(
                                    'Rejeter',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton(
                                  onPressed: () async {
                                    await ref
                                        .read(apiProvider)
                                        .approveProvider(id);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Approuvé ✅'),
                                      ),
                                    );
                                    setState(() {});
                                  },
                                  child: const Text('Approuver'),
                                ),
                              ] else ...[
                                FilledButton(
                                  onPressed: () async {
                                    await ref
                                        .read(apiProvider)
                                        .approveProvider(id);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ré-approuvé ✅'),
                                      ),
                                    );
                                    setState(() {});
                                  },
                                  child: const Text('Ré-approuver'),
                                ),
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
}

/// ===========================================================
/// ===================== COMMISSIONS =========================
/// Générées(scope) = somme des `dueDa` sur l’historique (tous pros)
/// Collecté(scope) = somme des `collectedDa` (backend)
/// Net(scope)      = max(Générées - Collecté, 0)
/// Scope = "ALL" (toute période) ou "YYYY-MM" (mois donné)
/// ===========================================================
class AdminCommissionsPage extends ConsumerStatefulWidget {
  const AdminCommissionsPage({super.key});
  @override
  ConsumerState<AdminCommissionsPage> createState() =>
      _AdminCommissionsPageState();
}

class _AdminCommissionsPageState extends ConsumerState<AdminCommissionsPage> {
  int _reload = 0;

  // "ALL" = tout le temps ; sinon "YYYY-MM"
  late String _scope;
  late List<String> _months;

  @override
  void initState() {
    super.initState();
    _scope = 'ALL';
    final now = DateTime.now().toUtc();
    _months = List.generate(36, (i) {
      final d = DateTime.utc(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  Widget _metric(String label, int amount) {
    return Text(
      '$label: ${formatDa(amount)}',
      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha:.65)),
      overflow: TextOverflow.ellipsis,
    );
  }

  // ---- Agrégations (backend only) -----------------------------------------

  Future<Map<String, int>> _totalsForScope() async {
    final approved = await ref
        .read(apiProvider)
        .listProviderApplications(status: 'approved', limit: 1000, offset: 0);

    final futures = <Future<Map<String, int>>>[];
    for (final raw in approved) {
      final p = (raw is Map)
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final pid = (p['id'] ?? '').toString();
      if (pid.isEmpty) continue;
      futures.add(_sumProvider(pid));
    }

    int due = 0, coll = 0;
    final parts = await Future.wait(futures);
    for (final m in parts) {
      due += m['due'] ?? 0;
      coll += m['collected'] ?? 0;
    }
    final net = (due - coll) < 0 ? 0 : (due - coll);
    return {'due': due, 'collected': coll, 'net': net};
  }

  // AdminCommissionsPage::_sumProvider (backend only)
  Future<Map<String, int>> _sumProvider(String providerId) async {
    final hist = await ref
        .read(apiProvider)
        .adminHistoryMonthly(months: 120, providerId: providerId);

    int due = 0, coll = 0;
    if (_scope == 'ALL') {
      for (final e in hist) {
        final d = _asInt((e as Map)['dueDa']);
        final c = _asInt((e as Map)['collectedDa']);
        due += d;
        coll += (c > d ? d : c);
      }
    } else {
      final scope = _canonYm(_scope);
      final row = hist
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            m['month'] = _canonYm((m['month'] ?? '').toString());
            return m;
          })
          .firstWhere(
            (e) => (e['month'] ?? '').toString() == scope,
            orElse: () => const <String, dynamic>{},
          );
      final d = _asInt(row['dueDa']);
      final c = _asInt(row['collectedDa']);
      due = d;
      coll = (c > d ? d : c);
    }
    final net = (due - coll) < 0 ? 0 : (due - coll);
    return {'due': due, 'collected': coll, 'net': net};
  }

  Future<List<Map<String, dynamic>>> _rowsForScope() async {
    final approved = await ref
        .read(apiProvider)
        .listProviderApplications(status: 'approved', limit: 1000, offset: 0);
    final futures = <Future<Map<String, dynamic>>>[];

    for (final raw in approved) {
      final p = (raw is Map)
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final pid = (p['id'] ?? '').toString();
      if (pid.isEmpty) continue;
      futures.add(_rowProviderScope(p));
    }

    final rows = await Future.wait(futures);
    rows.sort((a, b) => (_asInt(b['dueDa'])).compareTo(_asInt(a['dueDa'])));
    return rows;
  }

  // AdminCommissionsPage::_rowProviderScope (backend only)
  Future<Map<String, dynamic>> _rowProviderScope(
      Map<String, dynamic> provider) async {
    final pid = (provider['id'] ?? '').toString();
    final hist = await ref
        .read(apiProvider)
        .adminHistoryMonthly(months: 120, providerId: pid);

    final canonHist = hist
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          m['month'] = _canonYm((m['month'] ?? '').toString());
          return m;
        })
        .toList();

    int due = 0, coll = 0, completed = 0;
    if (_scope == 'ALL') {
      for (final e in canonHist) {
        final d = _asInt(e['dueDa']);
        final c = _asInt(e['collectedDa']);
        due += d;
        coll += (c > d ? d : c);
        completed += _asInt(e['completed']);
      }
    } else {
      final scope = _canonYm(_scope);
      final row = canonHist.firstWhere(
        (e) => (e['month'] ?? '').toString() == scope,
        orElse: () => const <String, dynamic>{},
      );
      final d = _asInt(row['dueDa']);
      final c = _asInt(row['collectedDa']);
      due = d;
      coll = (c > d ? d : c);
      completed = _asInt(row['completed']);
    }
    final net = (due - coll) < 0 ? 0 : (due - coll);
    return {
      'provider': provider,
      'completed': completed,
      'dueDa': due,
      'collectedDa': coll,
      'netDa': net
    };
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _adminTheme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Commissions')),
        body: Column(
          children: [
            // Barre de filtre scope
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Text('Période', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _scope,
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem(value: 'ALL', child: Text('Tout le temps')),
                      ..._months.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (v) => setState(() {
                      _scope = v ?? 'ALL';
                      _reload++;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // Contenu
            Expanded(
              child: FutureBuilder<Map<String, int>>(
                key: ValueKey('tot-$_scope-$_reload'),
                future: _totalsForScope(),
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erreur: ${snap.error}'));
                  }
                  final s = snap.data ?? const {'due': 0, 'collected': 0, 'net': 0};
                  final net = s['net'] ?? 0;
                  final due = s['due'] ?? 0;
                  final coll = s['collected'] ?? 0;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      MoneyCardDa(title: 'À percevoir', amountDa: net, color: Colors.orange, icon: Icons.receipt_long),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: MoneyCardDa(title: 'Collecté', amountDa: coll, color: Colors.green, icon: Icons.task_alt)),
                        const SizedBox(width: 10),
                        Expanded(child: MoneyCardDa(title: 'Générées', amountDa: due, color: Colors.blueGrey, icon: Icons.summarize)),
                      ]),
                      const SizedBox(height: 18),
                      Text(
                        _scope == 'ALL' ? 'Détail par pro (tout le temps)' : 'Détail par pro — ${_scope}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        key: ValueKey('rows-$_scope-$_reload'),
                        future: _rowsForScope(),
                        builder: (ctx, s2) {
                          if (s2.connectionState != ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (s2.hasError) return Text('Erreur: ${s2.error}');
                          final rows = (s2.data ?? const []);
                          if (rows.isEmpty) return const Text('Aucun pro approuvé');

                          return Column(
                            children: rows.map((e) {
                              final p = Map<String, dynamic>.from(e['provider'] as Map);
                              final id = (p['id'] ?? '').toString();
                              final name = (p['displayName'] ?? '').toString();
                              final u = Map<String, dynamic>.from((p['user'] ?? const {}) as Map);
                              final email = (u['email'] ?? '').toString();

                              final completed = _asInt(e['completed']);
                              final dueDa = _asInt(e['dueDa']);
                              final collDa = _asInt(e['collectedDa']);
                              final netDa = _asInt(e['netDa']);
                              final titleText = name.isEmpty ? '(Sans nom)' : name;

                              return Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => AdminProviderHistoryPage(
                                              providerId: id,
                                              displayName: titleText,
                                              email: email,
                                            ),
                                          ),
                                        )
                                        .then((_) => setState(() => _reload++));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor: Color(0xFFFFE7E7),
                                          child: Icon(Icons.pets, color: AdminColors.ink),
                                        ),
                                        const SizedBox(width: 12),

                                        // Colonne gauche : titre + infos
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titleText,
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(email, overflow: TextOverflow.ellipsis),
                                              Text(
                                                '$completed RDV complétés',
                                                style: TextStyle(color: Colors.black.withValues(alpha:.65)),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Colonne droite : montants (empilés)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              formatDa(netDa),
                                              style: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 6),
                                            _metric('Générées', dueDa),
                                            const SizedBox(height: 2),
                                            _metric('Collecté', collDa),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================================================
/// ========== Historique par pro (saumon + emojis) ===========
/// ===========================================================
class AdminProviderHistoryPage extends ConsumerStatefulWidget {
  final String providerId;
  final String displayName;
  final String email;
  const AdminProviderHistoryPage({
    super.key,
    required this.providerId,
    required this.displayName,
    required this.email,
  });

  @override
  ConsumerState<AdminProviderHistoryPage> createState() =>
      _AdminProviderHistoryPageState();
}

class _AdminProviderHistoryPageState
    extends ConsumerState<AdminProviderHistoryPage> {
  late String _selectedMonth; // 'YYYY-MM'
  late List<String> _months;
  int _reload = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _months = List.generate(12, (i) {
      final d = DateTime.utc(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    _selectedMonth = _months.first;
  }

  Map<String, dynamic> _normalizeMonthRow(Map<String, dynamic> m) {
    final month = _canonYm((m['month'] ?? '').toString());
    final due = _asInt(m['dueDa']);
    int collected = _asInt(m['collectedDa']);
    if (collected > due) collected = due;
    final net = (due - collected) < 0 ? 0 : (due - collected);
    return {
      'month': month,
      'pending': _asInt(m['pending']),
      'confirmed': _asInt(m['confirmed']),
      'completed': _asInt(m['completed']),
      'cancelled': _asInt(m['cancelled']),
      'dueDa': due,
      'collectedDa': collected,
      'netDa': net,
    };
  }

  Future<Map<String, dynamic>> _summaryForMonthFromHistory(String month) async {
    final list = await ref
        .read(apiProvider)
        .adminHistoryMonthly(months: 24, providerId: widget.providerId);

    final byMonth = {
      for (final raw in list)
        _canonYm((raw['month'] ?? '').toString()):
            Map<String, dynamic>.from(raw as Map),
    };

    final ym = _canonYm(month);
    final m = byMonth[ym] ?? const <String, dynamic>{};
    return _normalizeMonthRow({'month': ym, ...m});
  }

  Future<List<Map<String, dynamic>>> _history() async {
    final list = await ref
        .read(apiProvider)
        .adminHistoryMonthly(months: 12, providerId: widget.providerId);
    return list.map<Map<String, dynamic>>((raw) {
      final m = (raw is Map)
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      m['month'] = _canonYm((m['month'] ?? '').toString());
      return _normalizeMonthRow(m);
    }).toList();
  }

  Future<void> _markCollected() async {
    setState(() => _busy = true);
    try {
      final ym = _canonYm(_selectedMonth);
      await ref
          .read(apiProvider)
          .adminCollectMonth(month: ym, providerId: widget.providerId);
      if (!mounted) return;
      setState(() => _reload++);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marqué comme collecté')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uncollect() async {
    setState(() => _busy = true);
    try {
      final ym = _canonYm(_selectedMonth);
      await ref
          .read(apiProvider)
          .adminUncollectMonth(month: ym, providerId: widget.providerId);
      if (!mounted) return;
      setState(() => _reload++);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Collecte annulée')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleName = widget.displayName.isEmpty
        ? '(Sans nom)'
        : widget.displayName;
    final avatarSeed = widget.displayName.isEmpty
        ? widget.email
        : widget.displayName;

    return Theme(
      data: _adminTheme(context),
      child: Scaffold(
        appBar: AppBar(title: Text('Historique — $titleName')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE7E7),
                  child: Text(
                    _firstLetter(avatarSeed),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AdminColors.ink,
                    ),
                  ),
                ),
                title: Text(
                  titleName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(widget.email),
              ),
            ),
            const SizedBox(height: 12),

            // Sélecteur mois
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFE7E7).withValues(alpha:.7),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Mois',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedMonth,
                    items: _months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedMonth = v ?? _selectedMonth),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Actions
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _markCollected,
                icon: const Icon(Icons.task_alt),
                label: const Text('Déjà collecté'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _uncollect,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(height: 12),

            // Résumé
            FutureBuilder<Map<String, dynamic>>(
              key: ValueKey('sum-${_selectedMonth}-$_reload'),
              future: _summaryForMonthFromHistory(_selectedMonth),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snap.hasError) return Text('Erreur: ${snap.error}');
                final s = snap.data ?? const {};
                final pending = _asInt(s['pending']);
                final confirmed = _asInt(s['confirmed']);
                final completed = _asInt(s['completed']);
                final cancelled = _asInt(s['cancelled']);
                final dueDa = _asInt(s['dueDa']);
                final collDa = _asInt(s['collectedDa']);
                final netDa = _asInt(s['netDa']);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusEmojiBar(
                      pending: pending,
                      confirmed: confirmed,
                      completed: completed,
                      cancelled: cancelled,
                    ),
                    const SizedBox(height: 12),
                    MoneyCardDa(
                      title: 'À percevoir',
                      amountDa: netDa,
                      color: Colors.orange,
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: MoneyCardDa(
                            title: 'Collecté',
                            amountDa: collDa,
                            color: Colors.green,
                            icon: Icons.task_alt,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MoneyCardDa(
                            title: 'Générées',
                            amountDa: dueDa,
                            color: Colors.blueGrey,
                            icon: Icons.summarize,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),

            // Historique
            const Text(
              'Historique mensuel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('hist-$_reload'),
              future: _history(),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) return Text('Erreur: ${snap.error}');
                final rows = snap.data ?? const [];
                if (rows.isEmpty) return const Text('Aucun historique');

                return Column(
                  children: rows.map((e) {
                    final month = (e['month'] ?? '').toString();
                    final pending = _asInt(e['pending']);
                    final confirmed = _asInt(e['confirmed']);
                    final completed = _asInt(e['completed']);
                    final cancelled = _asInt(e['cancelled']);
                    final dueDa = _asInt(e['dueDa']);
                    final collDa = _asInt(e['collectedDa']);
                    final netDa = _asInt(e['netDa']);

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      child: ListTile(
                        title: Text(
                          month,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _pillMini('⏳', pending),
                              const SizedBox(width: 6),
                              _pillMini('📅', confirmed),
                              const SizedBox(width: 6),
                              _pillMini('✅', completed),
                              const SizedBox(width: 6),
                              _pillMini('❌', cancelled),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatDa(netDa),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'collectés: ${formatDa(collDa)}',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha:.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => setState(() => _selectedMonth = month),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}