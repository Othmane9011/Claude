import 'package:flutter/material.dart';

class ProAppointmentsScreen extends StatelessWidget {
  const ProAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendez-vous')),
      body: const Center(
        child: Text('Liste / filtres / actions sur les RDV — à venir.'),
      ),
    );
  }
}
