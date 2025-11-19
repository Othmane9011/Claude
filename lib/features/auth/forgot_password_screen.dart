import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String asRole;
  const ForgotPasswordScreen({super.key, required this.asRole});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _id = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF36C6C);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Réinitialisation mot de passe'),
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Réinitialiser le mot de passe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              "Pas de panique ! On s'occupe de tout. Veuillez entrer votre méthode de récupération (e-mail ou numéro de téléphone).",
              style: TextStyle(color: Colors.black.withOpacity(0.65)),
            ),
            const SizedBox(height: 16),
            Text('Adresse mail / numéro de téléphone',
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                isDense: true,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: coral, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  // TODO: appeler endpoint "request OTP" si dispo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP envoyé')),
                  );
                  context.push('/auth/otp?as=${widget.asRole}');
                },
                child: const Text('Confirmer'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
