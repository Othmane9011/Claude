import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';

class EditProviderScreen extends ConsumerStatefulWidget {
  const EditProviderScreen({super.key});
  @override
  ConsumerState<EditProviderScreen> createState() => _EditProviderScreenState();
}

class _EditProviderScreenState extends ConsumerState<EditProviderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayName = TextEditingController();
  final _bio         = TextEditingController();
  final _address     = TextEditingController();
  final _mapsUrl     = TextEditingController();

  String? _msg;
  bool _saving = false;

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil pro (simple)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'Nom d’affichage'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bio,
                decoration: const InputDecoration(labelText: 'Bio'),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mapsUrl,
                decoration: const InputDecoration(
                  labelText: 'Lien Google Maps',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _saving = true);
                        try {
                          await api.upsertMyProvider(
                            displayName: _displayName.text.trim(),
                            bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
                            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
                            // 👉 pas de lat/lng ici
                            specialties: {
                              'kind': 'vet',
                              'visible': true,
                              if (_mapsUrl.text.trim().isNotEmpty)
                                'mapsUrl': _mapsUrl.text.trim(),
                            },
                            // 👉 pas de forceReparse ici non plus
                          );
                          setState(() => _msg = 'Sauvegardé ✅');
                        } catch (e) {
                          setState(() => _msg = 'Erreur: $e');
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(_saving ? '...' : 'Enregistrer'),
              ),
              if (_msg != null) ...[
                const SizedBox(height: 8),
                Text(_msg!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
