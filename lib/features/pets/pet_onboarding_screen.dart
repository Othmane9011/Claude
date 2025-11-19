import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

class PetOnboardingScreen extends ConsumerStatefulWidget {
  const PetOnboardingScreen({super.key});

  @override
  ConsumerState<PetOnboardingScreen> createState() => _PetOnboardingScreenState();
}

class _PetOnboardingScreenState extends ConsumerState<PetOnboardingScreen> {
  // Champs de base
  final _name = TextEditingController();
  String _gender = 'UNKNOWN'; // 'MALE' | 'FEMALE' | 'UNKNOWN'
  int? _ageYears;             // affichage uniquement
  double? _weightKg;

  // Infos supplémentaires (dans le panneau)
  final _color = TextEditingController();
  final _city = TextEditingController();     // remplace "Pays"
  final _breed = TextEditingController();    // Race
  String? _animalType;                       // remplace "Numéro ID"
  DateTime? _neuteredAt;                     // Date de stérilisation

  // Image locale pour l’aperçu
  File? _photoFile;

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _city.dispose();
    _breed.dispose();
    super.dispose();
  }

  // -------- Pickers & helpers
  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _photoFile = File(x.path));
  }

  Future<void> _pickAge() async {
    final initial = (_ageYears ?? 0).clamp(0, 30);
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final ctl = FixedExtentScrollController(initialItem: initial);
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Âge de l’animal', style: TextStyle(fontWeight: FontWeight.w700)),
              const Divider(height: 16),
              Expanded(
                child: CupertinoPicker(
                  scrollController: ctl,
                  itemExtent: 36,
                  children: List.generate(31, (i) => Center(child: Text('$i ${i <= 1 ? "an" : "ans"}'))),
                  onSelectedItemChanged: (_) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const Spacer(),
                    FilledButton(onPressed: () => Navigator.pop(context, ctl.selectedItem), child: const Text('OK')),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) setState(() => _ageYears = result);
  }

  Future<void> _pickGender() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Mâle'),    onTap: () => Navigator.pop(context, 'MALE')),
            ListTile(title: const Text('Femelle'), onTap: () => Navigator.pop(context, 'FEMALE')),
            ListTile(title: const Text('Inconnu'), onTap: () => Navigator.pop(context, 'UNKNOWN')),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (v != null) setState(() => _gender = v);
  }

  Future<void> _pickAnimalType() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final presets = ['Chien', 'Chat', 'NAC', 'Oiseau', 'Reptile', 'Autre…'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in presets) ListTile(title: Text(p), onTap: () => Navigator.pop(context, p)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (type == null) return;

    if (type == 'Autre…') {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Type d’animal'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'ex: Furet, Tortue…'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
          ],
        ),
      );
      if (ok == true && ctrl.text.trim().isNotEmpty) {
        setState(() => _animalType = ctrl.text.trim());
      }
    } else {
      setState(() => _animalType = type);
    }
  }

  Future<void> _pickNeuteredAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
      initialDate: _neuteredAt ?? now,
    );
    if (picked != null) setState(() => _neuteredAt = picked);
  }

  // -------- Submit
  Future<void> _confirm() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donnez un nom à votre animal')));
      return;
    }

    // Prisma attend un DateTime ISO-8601 complet → on force minuit UTC
    String? neuteredIso;
    if (_neuteredAt != null) {
      final d = DateTime(_neuteredAt!.year, _neuteredAt!.month, _neuteredAt!.day)
          .toUtc()
          .toIso8601String(); // ex: 2025-08-13T00:00:00.000Z
      neuteredIso = d;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);

      // Upload optionnel de la photo (ne bloque pas si erreur)
      String? photoUrl;
      if (_photoFile != null) {
        try {
          photoUrl = await api.uploadLocalFile(_photoFile!);
        } catch (_) {
          // on ignore l'erreur d'upload pour ne pas bloquer l'enregistrement
        }
      }

      await api.createPet(
        name: _name.text.trim(),
        gender: _gender,
        weightKg: _weightKg,
        color: _color.text.trim().isEmpty ? null : _color.text.trim(),
        country: _city.text.trim().isEmpty ? null : _city.text.trim(), // "Ville" mappée vers country
        idNumber: _animalType,                                        // "Type d’animal" mappé vers idNumber
        breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        neuteredAtIso: neuteredIso,
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible d’enregistrer: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF36C6C);
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu
            Positioned.fill(
              child: Column(
                children: [
                  // Bandeau image
                  SizedBox(
                    height: 260,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: _photoFile != null
                              ? Image.file(_photoFile!, fit: BoxFit.cover)
                              : Image.asset('assets/images/dog_preview.png', fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: TextButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Ignorer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 8)],
                              ),
                              child: const Icon(Icons.edit, size: 22, color: Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Formulaire + panneau
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140), // marge en bas pour le bouton
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _textField(label: 'Nom de votre animal', controller: _name),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _chipBox(
                                label: 'Âge',
                                value: _ageYears == null ? '—' : '$_ageYears ${_ageYears == 1 ? "an" : "ans"}',
                                onTap: _pickAge,
                              ),
                              const SizedBox(width: 10),
                              _chipBox(
                                label: 'Genre',
                                value: _gender == 'MALE'
                                    ? 'Mâle'
                                    : _gender == 'FEMALE'
                                        ? 'Femelle'
                                        : '—',
                                onTap: _pickGender,
                              ),
                              const SizedBox(width: 10),
                              _chipBox(
                                label: 'Poids',
                                value: _weightKg == null ? '-- kg' : '${_weightKg!.toStringAsFixed(1)} kg',
                                onTap: () async {
                                  final ctrl = TextEditingController(text: _weightKg?.toString() ?? '');
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Poids (kg)'),
                                      content: TextField(
                                        controller: ctrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(hintText: 'ex. 4.2'),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                                    setState(() => _weightKg = v);
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          Text(
                            'Informations supplémentaires',
                            style: TextStyle(
                              color: coral,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // -------- Panneau comme avant (avec la date incluse)
                          _infoPanel(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bouton Confirmer
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + pad.bottom,
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: coral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  child: Text(_saving ? '...' : 'Confirmer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- Widgets utilitaires

  Widget _textField({required String label, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: '',
      ).copyWith(hintText: label),
    );
  }

  Widget _chipBox({required String label, required String value, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9A4A4)),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.black.withOpacity(.45), fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPanel() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE9A4A4)),
    );

    Widget divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF5C3C3));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE9A4A4))),
        color: Colors.white,
      ),
      child: Column(
        children: [
          _infoTile(
            icon: Icons.palette_outlined,
            title: 'Couleur',
            hint: 'Couleur de votre animal',
            controller: _color,
            border: border,
          ),
          divider(),
          _infoTile(
            icon: Icons.location_city_outlined,
            title: 'Ville',
            hint: 'Votre ville',
            controller: _city,
            border: border,
          ),
          divider(),
          // Type d’animal (sélecteur)
          ListTile(
            leading: const Icon(Icons.pets_outlined),
            title: const Text('Type d’animal'),
            subtitle: Text(
              _animalType ?? 'Choisir…',
              style: TextStyle(
                color: _animalType == null ? Colors.black45 : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _pickAnimalType,
          ),
          divider(),
          _infoTile(
            icon: Icons.badge_outlined,
            title: 'Race',
            hint: 'Race de votre animal',
            controller: _breed,
            border: border,
          ),
          divider(),
          // Date de stérilisation (dans le panneau)
          ListTile(
            leading: const Icon(Icons.content_cut),
            title: const Text('Date de stérilisation'),
            subtitle: Text(
              _neuteredAt == null ? '----/--/--' : DateFormat('yyyy/MM/dd').format(_neuteredAt!),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: _pickNeuteredAt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
    required OutlineInputBorder border,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '',
          isDense: true,
          border: InputBorder.none,
        ).copyWith(hintText: hint),
      ),
    );
  }
}
