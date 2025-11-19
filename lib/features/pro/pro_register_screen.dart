
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session_controller.dart';
import '../../core/api.dart';

const _coral = Color(0xFFF36C6C);

/* ========================= Helpers front ========================= */

bool _isValidHttpUrl(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  return RegExp(r'^(https?://)', caseSensitive: false).hasMatch(t);
}

/* ========================= Écran catégories ========================= */

class ProRegisterScreen extends ConsumerWidget {
  const ProRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Créer un compte professionnel'),
      ),
      body: _buildProCategoriesPage(context),
    );
  }

  Widget _buildProCategoriesPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Choisissez votre catégorie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _CategoryCard(
                  color: _coral,
                  icon: Icons.local_hospital_outlined,
                  label: 'Vétérinaire',
                  onTap: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _VetWizard3Steps()),
                    );
                    if (ok == true && context.mounted) context.go('/pro/application/submitted');
                  },
                ),
                _CategoryCard(
                  color: Colors.black87,
                  icon: Icons.pets_outlined,
                  label: 'Garderie',
                  onTap: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _DaycareWizard3Steps()),
                    );
                    if (ok == true && context.mounted) context.go('/pro/application/submitted');
                  },
                ),
                _CategoryCard(
                  color: Colors.black54,
                  icon: Icons.storefront_outlined,
                  label: 'Animalerie',
                  onTap: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _PetshopWizard3Steps()),
                    );
                    if (ok == true && context.mounted) context.go('/pro/application/submitted');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CategoryCard({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _DotsIndicator({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: active ? Colors.black87 : Colors.black26, shape: BoxShape.circle),
        );
      }),
    );
  }
}

/* ========================= Wizard VÉTÉRINAIRE ========================= */

class _VetWizard3Steps extends ConsumerStatefulWidget {
  const _VetWizard3Steps();
  @override
  ConsumerState<_VetWizard3Steps> createState() => _VetWizard3StepsState();
}

class _VetWizard3StepsState extends ConsumerState<_VetWizard3Steps> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _mapsUrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  bool _registered = false;

  String? _errFirst, _errLast, _errEmail, _errPass, _errPhone, _errAddress, _errMapsUrl;

  bool _isValidEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());
  bool _isValidPassword(String s) => s.length >= 8 && s.contains(RegExp(r'[A-Z]')) && s.contains(RegExp(r'[a-z]'));
  bool _isValidPhone(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9+]'), '');
    return d.length >= 8 && d.length <= 16;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    setState(() {
      if (step == 0) {
        _errFirst = _firstName.text.trim().isEmpty ? 'Prénom requis' : null;
        _errLast = _lastName.text.trim().isEmpty ? 'Nom requis' : null;
      } else if (step == 1) {
        _errEmail = _isValidEmail(_email.text) ? null : 'Email invalide';
        _errPass = _isValidPassword(_pass.text) ? null : 'Mot de passe trop faible';
        _errPhone = _phone.text.trim().isEmpty ? 'Téléphone requis' : (_isValidPhone(_phone.text) ? null : 'Téléphone invalide');
      } else {
        _errAddress = _address.text.trim().isEmpty ? 'Adresse requise' : null;
        final mapsOk = _isValidHttpUrl(_mapsUrl.text);
        _errMapsUrl = mapsOk
            ? null
            : (_mapsUrl.text.trim().isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)');
      }
    });
    if (step == 0) return _errFirst == null && _errLast == null;
    if (step == 1) return _errEmail == null && _errPass == null && _errPhone == null;
    return _errAddress == null && _errMapsUrl == null;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;

    if (_step == 1 && !_registered) {
      setState(() => _loading = true);
      try {
        final ok = await ref.read(sessionProvider.notifier).register(_email.text.trim(), _pass.text);
        if (!mounted) return;
        if (!ok) {
          final err = (ref.read(sessionProvider).error ?? '').toLowerCase();
          if (err.contains('409') || err.contains('already in use') || err.contains('email')) {
            setState(() => _errEmail = 'Email déjà utilisé');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cet email est déjà utilisé.')));
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.read(sessionProvider).error ?? 'Inscription impossible')),
          );
          return;
        }
        _registered = true;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  Future<void> _submitFinal() async {
    if (!_validateStep(2)) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(apiProvider);
      await api.ensureAuth();

      try {
        await api.updateMe(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? '');
        if (status == 409 || msg.toLowerCase().contains('phone')) {
          setState(() {
            _errPhone = 'Téléphone déjà utilisé';
            _step = 1;
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce numéro est déjà utilisé.')));
          return;
        }
        rethrow;
      }

      final display = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
      final displayName = display.isEmpty ? _email.text.split('@').first : display;

      final finalMaps = _mapsUrl.text.trim();
      if (finalMaps.isEmpty || !_isValidHttpUrl(finalMaps)) {
        setState(() {
          _errMapsUrl = finalMaps.isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)';
          _step = 2;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errMapsUrl!)));
        return;
      }

      await api.upsertMyProvider(
        displayName: displayName,
        address: _address.text.trim(),
        specialties: {
          'kind': 'vet',
          'visible': true,
          'mapsUrl': finalMaps,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? 'Erreur');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: null,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _buildStep())),
            const SizedBox(height: 8),
            _DotsIndicator(current: _step, total: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(onPressed: _loading ? null : () => setState(() => _step -= 1), child: const Text('Précédent')),
                const Spacer(),
                FilledButton(onPressed: _loading ? null : (_step < 2 ? _next : _submitFinal), child: Text(_step < 2 ? 'Suivant' : 'Soumettre')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) {
      return _centeredForm([
        _label('Prénom'),
        _input(_firstName, errorText: _errFirst),
        const SizedBox(height: 12),
        _label('Nom'),
        _input(_lastName, errorText: _errLast),
      ], key: const ValueKey('vet0'));
    }

    if (_step == 1) {
      return _centeredForm([
        _label('Adresse email'),
        _input(_email, keyboard: TextInputType.emailAddress, errorText: _errEmail),
        const SizedBox(height: 12),
        _label('Mot de passe'),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            isDense: true,
            errorText: _errPass,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility)),
            helperText: 'Min. 8 caractères avec une MAJUSCULE et une minuscule',
          ),
        ),
        const SizedBox(height: 12),
        _label('Téléphone'),
        _input(_phone, keyboard: TextInputType.phone, errorText: _errPhone),
      ], key: const ValueKey('vet1'));
    }

    return _centeredForm([
      _label('Adresse du vétérinaire'),
      _input(_address, errorText: _errAddress),
      const SizedBox(height: 12),
      _label('Lien Google Maps (obligatoire)'),
      TextField(
        controller: _mapsUrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          isDense: true,
          errorText: _errMapsUrl,
          hintText: 'https://maps.google.com/...',
        ),
      ),
    ], key: const ValueKey('vet2'));
  }

  Widget _centeredForm(List<Widget> children, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const SizedBox(height: 8), ...children]),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13)));

  Widget _input(
    TextEditingController c, {
    bool obscure = false,
    TextInputType? keyboard,
    String? errorText,
    String? hintText,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
        errorText: errorText,
        hintText: hintText,
      ),
    );
  }
}

/* ========================= Wizard GARDERIE ========================= */

class _DaycareWizard3Steps extends ConsumerStatefulWidget {
  const _DaycareWizard3Steps();
  @override
  ConsumerState<_DaycareWizard3Steps> createState() => _DaycareWizard3StepsState();
}

class _DaycareWizard3StepsState extends ConsumerState<_DaycareWizard3Steps> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();

  final _shopName = TextEditingController();
  final _address = TextEditingController();
  final _mapsUrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  bool _registered = false;

  String? _errFirst, _errLast, _errEmail, _errPass, _errPhone, _errShop, _errAddress, _errMapsUrl;

  bool _isValidEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());
  bool _isValidPassword(String s) => s.length >= 8 && s.contains(RegExp(r'[A-Z]')) && s.contains(RegExp(r'[a-z]'));
  bool _isValidPhone(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9+]'), '');
    return d.length >= 8 && d.length <= 16;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    _shopName.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    setState(() {
      if (step == 0) {
        _errFirst = _firstName.text.trim().isEmpty ? 'Prénom requis' : null;
        _errLast = _lastName.text.trim().isEmpty ? 'Nom requis' : null;
      } else if (step == 1) {
        _errEmail = _isValidEmail(_email.text) ? null : 'Email invalide';
        _errPass = _isValidPassword(_pass.text) ? null : 'Mot de passe trop faible';
        _errPhone = _phone.text.trim().isEmpty ? 'Téléphone requis' : (_isValidPhone(_phone.text) ? null : 'Téléphone invalide');
      } else {
        _errShop = _shopName.text.trim().isEmpty ? 'Nom de la boutique requis' : null;
        _errAddress = _address.text.trim().isEmpty ? 'Adresse requise' : null;
        final mapsOk = _isValidHttpUrl(_mapsUrl.text);
        _errMapsUrl = mapsOk
            ? null
            : (_mapsUrl.text.trim().isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)');
      }
    });
    if (step == 0) return _errFirst == null && _errLast == null;
    if (step == 1) return _errEmail == null && _errPass == null && _errPhone == null;
    return _errShop == null && _errAddress == null && _errMapsUrl == null;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;

    if (_step == 1 && !_registered) {
      setState(() => _loading = true);
      try {
        final ok = await ref.read(sessionProvider.notifier).register(_email.text.trim(), _pass.text);
        if (!mounted) return;
        if (!ok) {
          final err = (ref.read(sessionProvider).error ?? '').toLowerCase();
          if (err.contains('409') || err.contains('already in use') || err.contains('email')) {
            setState(() => _errEmail = 'Email déjà utilisé');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cet email est déjà utilisé.')));
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.read(sessionProvider).error ?? 'Inscription impossible')),
          );
          return;
        }
        _registered = true;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  Future<void> _submitFinal() async {
    if (!_validateStep(2)) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(apiProvider);
      await api.ensureAuth();

      try {
        await api.updateMe(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? '');
        if (status == 409 || msg.toLowerCase().contains('phone')) {
          setState(() {
            _errPhone = 'Téléphone déjà utilisé';
            _step = 1;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce numéro est déjà utilisé.')));
          }
          return;
        }
        rethrow;
      }

      final display = _shopName.text.trim().isEmpty ? _email.text.split('@').first : _shopName.text.trim();

      final finalMaps = _mapsUrl.text.trim();
      if (finalMaps.isEmpty || !_isValidHttpUrl(finalMaps)) {
        setState(() {
          _errMapsUrl = finalMaps.isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)';
          _step = 2;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errMapsUrl!)));
        return;
      }

      await api.upsertMyProvider(
        displayName: display,
        address: _address.text.trim(),
        specialties: {
          'kind': 'daycare',
          'visible': true,
          'mapsUrl': finalMaps,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? 'Erreur');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Inscription Garderie'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _buildStep())),
            const SizedBox(height: 8),
            _DotsIndicator(current: _step, total: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(onPressed: _loading ? null : () => setState(() => _step -= 1), child: const Text('Précédent')),
                const Spacer(),
                FilledButton(onPressed: _loading ? null : (_step < 2 ? _next : _submitFinal), child: Text(_step < 2 ? 'Suivant' : 'Soumettre')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) {
      return _centeredForm([
        _label('Prénom'),
        _input(_firstName, errorText: _errFirst),
        const SizedBox(height: 12),
        _label('Nom'),
        _input(_lastName, errorText: _errLast),
      ], key: const ValueKey('day0'));
    }

    if (_step == 1) {
      return _centeredForm([
        _label('Adresse email'),
        _input(_email, keyboard: TextInputType.emailAddress, errorText: _errEmail),
        const SizedBox(height: 12),
        _label('Mot de passe'),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            isDense: true,
            errorText: _errPass,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility)),
            helperText: 'Min. 8 caractères avec une MAJUSCULE et une minuscule',
          ),
        ),
        const SizedBox(height: 12),
        _label('Téléphone'),
        _input(_phone, keyboard: TextInputType.phone, errorText: _errPhone),
      ], key: const ValueKey('day1'));
    }

    return _centeredForm([
      _label('Nom de la boutique'),
      _input(_shopName, errorText: _errShop),
      const SizedBox(height: 12),
      _label('Adresse de la boutique'),
      _input(_address, errorText: _errAddress),
      const SizedBox(height: 12),
      _label('Lien Google Maps (obligatoire)'),
      TextField(
        controller: _mapsUrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          isDense: true,
          errorText: _errMapsUrl,
          hintText: 'https://maps.google.com/...',
        ),
      ),
    ], key: const ValueKey('day2'));
  }

  Widget _centeredForm(List<Widget> children, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const SizedBox(height: 8), ...children]),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13)));

  Widget _input(
    TextEditingController c, {
    bool obscure = false,
    TextInputType? keyboard,
    String? errorText,
    String? hintText,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
        errorText: errorText,
        hintText: hintText,
      ),
    );
  }
}

/* ========================= Wizard ANIMALERIE ========================= */

class _PetshopWizard3Steps extends ConsumerStatefulWidget {
  const _PetshopWizard3Steps();
  @override
  ConsumerState<_PetshopWizard3Steps> createState() => _PetshopWizard3StepsState();
}

class _PetshopWizard3StepsState extends ConsumerState<_PetshopWizard3Steps> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();

  final _shopName = TextEditingController();
  final _address = TextEditingController();
  final _mapsUrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  bool _registered = false;

  String? _errFirst, _errLast, _errEmail, _errPass, _errPhone, _errShop, _errAddress, _errMapsUrl;

  bool _isValidEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());
  bool _isValidPassword(String s) => s.length >= 8 && s.contains(RegExp(r'[A-Z]')) && s.contains(RegExp(r'[a-z]'));
  bool _isValidPhone(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9+]'), '');
    return d.length >= 8 && d.length <= 16;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    _shopName.dispose();
    _address.dispose();
    _mapsUrl.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    setState(() {
      if (step == 0) {
        _errFirst = _firstName.text.trim().isEmpty ? 'Prénom requis' : null;
        _errLast = _lastName.text.trim().isEmpty ? 'Nom requis' : null;
      } else if (step == 1) {
        _errEmail = _isValidEmail(_email.text) ? null : 'Email invalide';
        _errPass = _isValidPassword(_pass.text) ? null : 'Mot de passe trop faible';
        _errPhone = _phone.text.trim().isEmpty ? 'Téléphone requis' : (_isValidPhone(_phone.text) ? null : 'Téléphone invalide');
      } else {
        _errShop = _shopName.text.trim().isEmpty ? 'Nom de la boutique requis' : null;
        _errAddress = _address.text.trim().isEmpty ? 'Adresse requise' : null;
        final mapsOk = _isValidHttpUrl(_mapsUrl.text);
        _errMapsUrl = mapsOk
            ? null
            : (_mapsUrl.text.trim().isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)');
      }
    });
    if (step == 0) return _errFirst == null && _errLast == null;
    if (step == 1) return _errEmail == null && _errPass == null && _errPhone == null;
    return _errShop == null && _errAddress == null && _errMapsUrl == null;
  }

  Future<void> _next() async {
    if (!_validateStep(_step)) return;

    if (_step == 1 && !_registered) {
      setState(() => _loading = true);
      try {
        final ok = await ref.read(sessionProvider.notifier).register(_email.text.trim(), _pass.text);
        if (!mounted) return;
        if (!ok) {
          final err = (ref.read(sessionProvider).error ?? '').toLowerCase();
          if (err.contains('409') || err.contains('already in use') || err.contains('email')) {
            setState(() => _errEmail = 'Email déjà utilisé');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cet email est déjà utilisé.')));
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ref.read(sessionProvider).error ?? 'Inscription impossible')),
          );
          return;
        }
        _registered = true;
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    setState(() => _step = (_step + 1).clamp(0, 2));
  }

  Future<void> _submitFinal() async {
    if (!_validateStep(2)) return;
    setState(() => _loading = true);

    try {
      final api = ref.read(apiProvider);
      await api.ensureAuth();

      try {
        await api.updateMe(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? '');
        if (status == 409 || msg.toLowerCase().contains('phone')) {
          setState(() {
            _errPhone = 'Téléphone déjà utilisé';
            _step = 1;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce numéro est déjà utilisé.')));
          }
          return;
        }
        rethrow;
      }

      final display = _shopName.text.trim().isEmpty ? _email.text.split('@').first : _shopName.text.trim();

      final finalMaps = _mapsUrl.text.trim();
      if (finalMaps.isEmpty || !_isValidHttpUrl(finalMaps)) {
        setState(() {
          _errMapsUrl = finalMaps.isEmpty ? 'Lien Google Maps requis' : 'URL invalide (http/https)';
          _step = 2;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errMapsUrl!)));
        return;
      }

      await api.upsertMyProvider(
        displayName: display,
        address: _address.text.trim(),
        specialties: {
          'kind': 'petshop',
          'visible': true,
          'mapsUrl': finalMaps,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map) ? (e.response?.data['message']?.toString() ?? '') : (e.message ?? 'Erreur');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Inscription Animalerie'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _buildStep())),
            const SizedBox(height: 8),
            _DotsIndicator(current: _step, total: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(onPressed: _loading ? null : () => setState(() => _step -= 1), child: const Text('Précédent')),
                const Spacer(),
                FilledButton(onPressed: _loading ? null : (_step < 2 ? _next : _submitFinal), child: Text(_step < 2 ? 'Suivant' : 'Soumettre')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) {
      return _centeredForm([
        _label('Prénom'),
        _input(_firstName, errorText: _errFirst),
        const SizedBox(height: 12),
        _label('Nom'),
        _input(_lastName, errorText: _errLast),
      ], key: const ValueKey('pet0'));
    }

    if (_step == 1) {
      return _centeredForm([
        _label('Adresse email'),
        _input(_email, keyboard: TextInputType.emailAddress, errorText: _errEmail),
        const SizedBox(height: 12),
        _label('Mot de passe'),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          decoration: InputDecoration(
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            isDense: true,
            errorText: _errPass,
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility)),
            helperText: 'Min. 8 caractères avec une MAJUSCULE et une minuscule',
          ),
        ),
        const SizedBox(height: 12),
        _label('Téléphone'),
        _input(_phone, keyboard: TextInputType.phone, errorText: _errPhone),
      ], key: const ValueKey('pet1'));
    }

    return _centeredForm([
      _label('Nom de la boutique'),
      _input(_shopName, errorText: _errShop),
      const SizedBox(height: 12),
      _label('Adresse de la boutique'),
      _input(_address, errorText: _errAddress),
      const SizedBox(height: 12),
      _label('Lien Google Maps (obligatoire)'),
      TextField(
        controller: _mapsUrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          isDense: true,
          errorText: _errMapsUrl,
          hintText: 'https://maps.google.com/...',
        ),
      ),
    ], key: const ValueKey('pet2'));
  }

  Widget _centeredForm(List<Widget> children, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const SizedBox(height: 8), ...children]),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13)));

  Widget _input(
    TextEditingController c, {
    bool obscure = false,
    TextInputType? keyboard,
    String? errorText,
    String? hintText,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        isDense: true,
        errorText: errorText,
        hintText: hintText,
      ),
    );
  }
}
