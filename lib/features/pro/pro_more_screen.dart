import 'package:flutter/material.dart';

class ProMoreScreen extends StatelessWidget {
  const ProMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // 👈 pas "const"
      appBar: AppBar(title: const Text('Plus')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Avis, Patients, Boutique, Stats… bientôt ici.'),
      ),
    );
  }
}
