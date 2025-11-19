import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

/// ——— Modèle intervalle (interne)
class _AvInterval {
  TimeOfDay start;
  TimeOfDay end;
  _AvInterval(this.start, this.end);
}

class ProAvailabilityScreen extends ConsumerStatefulWidget {
  const ProAvailabilityScreen({super.key});
  @override
  ConsumerState<ProAvailabilityScreen> createState() => _ProAvailabilityScreenState();
}

class _ProAvailabilityScreenState extends ConsumerState<ProAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _selectedDay = 0; // 0..6 (Lun..Dim)

  // État Hebdo
  bool _loadingWeekly = true;
  bool _savingWeekly = false;

  // État Time-off
  bool _addingOff = false;
  bool _loadingOffs = true;
  final List<Map<String, dynamic>> _timeOffs = [];

  // Hebdo (rempli depuis l’API au démarrage)
  final Map<int, List<_AvInterval>> _weekly = {
    0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: [],
  };

  // Indisponibilités (form)
  DateTimeRange? _offDateRange;
  TimeOfDay _offStart = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _offEnd   = const TimeOfDay(hour: 23, minute: 59);
  final _offNote = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchAndFillWeekly();
    _loadTimeOffs();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _offNote.dispose();
    super.dispose();
  }

  // ===== Helpers =====

  String _weekdayLabel(int i) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[i];
  }

  int _toMin(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _fromMin(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) onPicked(t);
  }

  Future<void> _pickOffDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _offDateRange ?? DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 1)),
      ),
    );
    if (range != null) setState(() => _offDateRange = range);
  }

  // Ne normalise qu’à l’enregistrement (tri + fusion des chevauchements)
  void _normalizeDay(int day) {
    final list = List<_AvInterval>.from(_weekly[day]!);
    list.sort((a, b) => _toMin(a.start).compareTo(_toMin(b.start)));

    final merged = <_AvInterval>[];
    for (final it in list) {
      final curStart = _toMin(it.start);
      final curEnd   = _toMin(it.end);
      if (curEnd <= curStart) continue;

      if (merged.isEmpty) {
        merged.add(_AvInterval(it.start, it.end));
      } else {
        final last = merged.last;
        final lastEnd = _toMin(last.end);
        if (curStart <= lastEnd) {
          // fusion
          final endMax = (curEnd > lastEnd) ? it.end : last.end;
          merged[merged.length - 1] = _AvInterval(last.start, endMax);
        } else {
          merged.add(_AvInterval(it.start, it.end));
        }
      }
    }
    _weekly[day] = merged;
  }

  // ===== API binding =====

  Future<void> _fetchAndFillWeekly() async {
    setState(() => _loadingWeekly = true);
    try {
      final api = ref.read(apiProvider);
      final res = await api.myWeekly(); // GET /providers/me/availability
      final entries = (res['entries'] as List?) ?? const [];

      for (var d = 0; d < 7; d++) {
        _weekly[d] = [];
      }

      for (final e in entries) {
        if (e is! Map) continue;
        final wd = (e['weekday'] is int) ? (e['weekday'] as int) : int.tryParse('${e['weekday']}') ?? 0;
        final s  = (e['startMin'] is int) ? e['startMin'] as int : int.tryParse('${e['startMin']}') ?? -1;
        final en = (e['endMin']   is int) ? e['endMin']   as int : int.tryParse('${e['endMin']}')   ?? -1;
        if (wd < 1 || wd > 7 || s < 0 || en <= s) continue;
        final dayIndex = (wd - 1) % 7;
        _weekly[dayIndex]!.add(_AvInterval(_fromMin(s), _fromMin(en)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement des disponibilités: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingWeekly = false);
    }
  }

  Future<void> _saveWeekly() async {
    // Normalise tout avant d’envoyer
    for (var d = 0; d < 7; d++) {
      _normalizeDay(d);
    }

    setState(() => _savingWeekly = true);
    try {
      final payload = <Map<String, dynamic>>[];
      _weekly.forEach((day0, list) {
        final weekday = ((day0) % 7) + 1; // 0..6 -> 1..7
        for (final it in list) {
          final s = _toMin(it.start);
          final e = _toMin(it.end);
          if (e > s) payload.add({'weekday': weekday, 'startMin': s, 'endMin': e});
        }
      });

      // IMPORTANT: n’envoie que les minutes brutes
      await ref.read(apiProvider).setWeekly(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilités enregistrées ✅')),
      );
      _fetchAndFillWeekly();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingWeekly = false);
    }
  }

  Future<void> _clearWeekly() async {
    setState(() => _savingWeekly = true);
    try {
      await ref.read(apiProvider).setWeekly(<Map<String, dynamic>>[]);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Disponibilités vidées ✅')));
      for (final k in _weekly.keys) {
        _weekly[k] = [];
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _savingWeekly = false);
    }
  }

  // ------- Time-offs: load + add + delete -------

  Future<void> _loadTimeOffs() async {
    setState(() => _loadingOffs = true);
    try {
      final items = await ref.read(apiProvider).myTimeOffs(); // [{id, startsAt, endsAt, reason}, ...]
      _timeOffs
        ..clear()
        ..addAll(items);
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement indisponibilités: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingOffs = false);
    }
  }

  Future<void> _deleteTimeOff(String id) async {
    try {
      await ref.read(apiProvider).deleteMyTimeOff(id);
      await _loadTimeOffs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indisponibilité supprimée ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible: $e')),
      );
    }
  }

  Future<void> _addTimeOff() async {
    if (_offDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une plage de dates')),
      );
      return;
    }
    final sMin = _toMin(_offStart);
    final eMin = _toMin(_offEnd);
    if (eMin <= sMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heure de fin doit être après le début')),
      );
      return;
    }

    setState(() => _addingOff = true);
    try {
      // ⚠️ AUCUNE conversion de fuseau : on envoie exactement ce qui est saisi (UTC "figé")
      final s = _offDateRange!.start;
      final e = _offDateRange!.end;

      final startUtc = DateTime.utc(s.year, s.month, s.day, _offStart.hour, _offStart.minute);
      final endUtc   = DateTime.utc(e.year, e.month, e.day, _offEnd.hour, _offEnd.minute);

      await ref.read(apiProvider).addTimeOff(
        startsAtIso: startUtc.toIso8601String(),
        endsAtIso: endUtc.toIso8601String(),
        reason: _offNote.text.trim().isEmpty ? null : _offNote.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Indisponibilité ajoutée ✅')));

      setState(() {
        _offDateRange = null;
        _offStart = const TimeOfDay(hour: 0, minute: 0);
        _offEnd = const TimeOfDay(hour: 23, minute: 59);
        _offNote.clear();
      });

      await _loadTimeOffs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingOff = false);
    }
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.black.withOpacity(.65);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilités'),
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Hebdomadaire'), Tab(text: 'Indisponibilités')],
        ),
        actions: [
          if (_loadingWeekly && _loadingOffs)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              tooltip: 'Recharger',
              onPressed: () {
                _fetchAndFillWeekly();
                _loadTimeOffs();
              },
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // === TAB 1 : Hebdomadaire ===
          Column(
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = i == _selectedDay;
                    final count = _weekly[i]!.length;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_weekdayLabel(i)),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$count'),
                            )
                          ]
                        ],
                      ),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedDay = i),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loadingWeekly
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        children: [
                          // Presets rapides (normalisés après ajout)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('9–12'),
                                onPressed: () {
                                  _weekly[_selectedDay]!.add(_AvInterval(
                                    const TimeOfDay(hour: 9, minute: 0),
                                    const TimeOfDay(hour: 12, minute: 0),
                                  ));
                                  _normalizeDay(_selectedDay);
                                  setState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('14–18'),
                                onPressed: () {
                                  _weekly[_selectedDay]!.add(_AvInterval(
                                    const TimeOfDay(hour: 14, minute: 0),
                                    const TimeOfDay(hour: 18, minute: 0),
                                  ));
                                  _normalizeDay(_selectedDay);
                                  setState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('Journée 9–18'),
                                onPressed: () {
                                  _weekly[_selectedDay] = [
                                    _AvInterval(const TimeOfDay(hour: 9, minute: 0),
                                        const TimeOfDay(hour: 18, minute: 0)),
                                  ];
                                  setState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('Fermé'),
                                onPressed: () {
                                  _weekly[_selectedDay] = [];
                                  setState(() {});
                                },
                              ),
                              ActionChip(
                                label: const Text('Copier sur tous'),
                                onPressed: () {
                                  final copy = _weekly[_selectedDay]!
                                      .map((e) => _AvInterval(e.start, e.end))
                                      .toList();
                                  setState(() {
                                    for (var d = 0; d < 7; d++) {
                                      if (d == _selectedDay) continue;
                                      _weekly[d] = copy
                                          .map((e) => _AvInterval(e.start, e.end))
                                          .toList();
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reproduit sur tous les jours')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Créneaux du ${_weekdayLabel(_selectedDay)}', style: TextStyle(color: subtle)),
                          const SizedBox(height: 8),
                          _IntervalsEditor(
                            intervals: _weekly[_selectedDay]!,
                            onChanged: () => setState(() {}),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // === TAB 2 : Indisponibilités ===
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Plage de dates', style: TextStyle(color: subtle)),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: _pickOffDateRange,
                child: Text(
                  _offDateRange == null
                      ? 'Choisir...'
                      : '${DateFormat('EEE d MMM', 'fr_FR').format(_offDateRange!.start)}  →  '
                        '${DateFormat('EEE d MMM', 'fr_FR').format(_offDateRange!.end)}',
                ),
              ),
              const SizedBox(height: 14),
              Text('Heures', style: TextStyle(color: subtle)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(
                        initial: _offStart,
                        onPicked: (t) => setState(() => _offStart = t),
                      ),
                      child: Text(_offStart.format(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(
                        initial: _offEnd,
                        onPicked: (t) => setState(() => _offEnd = t),
                      ),
                      child: Text(_offEnd.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Motif (optionnel)', style: TextStyle(color: subtle)),
              const SizedBox(height: 6),
              TextField(
                controller: _offNote,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Congés, déplacement, formation…',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addingOff ? null : _addTimeOff,
                icon: const Icon(Icons.block),
                label: Text(_addingOff ? '...' : 'Ajouter l’indisponibilité'),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Historique des indisponibilités',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (_loadingOffs)
                const Center(child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_timeOffs.isEmpty)
                Text('Aucune indisponibilité', style: TextStyle(color: subtle))
              else
                Column(
                  children: _timeOffs.map((m) {
                    final id   = (m['id'] ?? '').toString();
                    final sIso = (m['startsAt'] ?? m['start'] ?? '').toString();
                    final eIso = (m['endsAt']   ?? m['end']   ?? '').toString();
                    final note = (m['reason'] ?? '').toString();

                    DateTime? s, e;
                    try { s = DateTime.parse(sIso).toUtc(); } catch (_) {}
                    try { e = DateTime.parse(eIso).toUtc(); } catch (_) {}

                    String fmtDate(DateTime d) => DateFormat('EEE d MMM y', 'fr_FR').format(d);
                    String fmtTime(DateTime d) => DateFormat('HH:mm', 'fr_FR').format(d);

                    String label;
                    if (s != null && e != null) {
                      final sameDay = s.year==e.year && s.month==e.month && s.day==e.day;
                      label = sameDay
                          ? '${fmtDate(s)}  •  ${fmtTime(s)} → ${fmtTime(e)}'
                          : '${fmtDate(s)} ${fmtTime(s)}  →  ${fmtDate(e)} ${fmtTime(e)}';
                    } else {
                      label = (sIso.isNotEmpty && eIso.isNotEmpty)
                          ? '$sIso → $eIso' : (sIso.isNotEmpty ? sIso : eIso);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(note, style: TextStyle(color: Colors.black.withOpacity(.7))),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Supprimer',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer cette indisponibilité ?'),
                                  content: const Text('Cette action est irréversible.'),
                                  actions: [
                                    TextButton(onPressed: ()=> Navigator.pop(ctx, false), child: const Text('Annuler')),
                                    FilledButton(onPressed: ()=> Navigator.pop(ctx, true), child: const Text('Supprimer')),
                                  ],
                                ),
                              );
                              if (ok == true) _deleteTimeOff(id);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: (_savingWeekly || _loadingWeekly) ? null : _saveWeekly,
                  child: Text(_savingWeekly ? '...' : 'Enregistrer'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: (_savingWeekly || _loadingWeekly) ? null : _clearWeekly,
                child: const Text('Tout vider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ——— Widgets

class _IntervalsEditor extends StatelessWidget {
  final List<_AvInterval> intervals;
  final VoidCallback onChanged;

  const _IntervalsEditor({
    required this.intervals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < intervals.length; i++)
          _OneIntervalRow(
            key: ObjectKey(intervals[i]), // << clé STABLE par objet
            start: intervals[i].start,
            end: intervals[i].end,
            onStart: (t) { intervals[i].start = t; onChanged(); },
            onEnd:   (t) { intervals[i].end   = t; onChanged(); },
            onDelete: () { intervals.removeAt(i); onChanged(); },
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () {
              intervals.add(
                _AvInterval(
                  const TimeOfDay(hour: 9, minute: 0),
                  const TimeOfDay(hour: 12, minute: 0),
                ),
              );
              onChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un créneau'),
          ),
        ),
      ],
    );
  }
}

class _OneIntervalRow extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<TimeOfDay> onStart;
  final ValueChanged<TimeOfDay> onEnd;
  final VoidCallback onDelete;

  const _OneIntervalRow({
    super.key,
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
    required this.onDelete,
  });

  Future<void> _pick(BuildContext context, TimeOfDay init, ValueChanged<TimeOfDay> cb) async {
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null) cb(t);
  }

  @override
  Widget build(BuildContext context) {
    final invalid = (end.hour * 60 + end.minute) <= (start.hour * 60 + start.minute);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pick(context, start, onStart),
              child: Text('Début  •  ${start.format(context)}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _pick(context, end, onEnd),
              child: Text('Fin  •  ${end.format(context)}'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          if (invalid)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.error_outline, color: Colors.red),
            ),
        ],
      ),
    );
  }
}
