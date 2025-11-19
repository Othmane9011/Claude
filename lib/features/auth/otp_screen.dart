import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends StatefulWidget {
  final String asRole;
  const OtpScreen({super.key, required this.asRole});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _c = List.generate(4, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFF36C6C);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Confirmation'),
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Confirmez votre adresse mail / n° de téléphone',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('Un OTP vous a été envoyé', style: TextStyle(color: Colors.black.withOpacity(0.6))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) {
                return SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _c[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 3) FocusScope.of(context).nextFocus();
                    },
                  ),
                );
              }),
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
                  // TODO: vérifier OTP côté backend si endpoints dispos
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP vérifié')),
                  );
                  context.go('/auth/login?as=${widget.asRole}');
                },
                child: const Text('Vérifier'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
