import 'package:flutter/material.dart';

class BoardingScreen extends StatelessWidget {
  const BoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garderie')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dites-nous ce que vous voulez, on s’occupe du reste !',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black.withOpacity(.85))),
          const SizedBox(height: 12),

          _field(Icons.place, 'Proche de votre emplacement'),
          const SizedBox(height: 10),
          _field(Icons.date_range, 'Choisissez la durée du séjour'),
          const SizedBox(height: 10),
          _field(Icons.pets, 'Nombre d’animaux'),
          const SizedBox(height: 10),
          _field(Icons.filter_alt_outlined, 'Type'),

          const SizedBox(height: 20),
          FilledButton(onPressed: (){}, child: const Text('Continuer')),
          const SizedBox(height: 30),

          Text('Établissements (exemple)', style: TextStyle(fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(.85))),
          const SizedBox(height: 10),
          _boardingItem('Garderie chat pilo', 'Tarif pour 1 nuit : 500 DA'),
          const SizedBox(height: 10),
          _boardingItem('Garderie Animotel', 'Tarif pour 1 nuit : 550 DA'),
        ],
      ),
    );
  }

  Widget _field(IconData icon, String hint) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  Widget _boardingItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: Colors.black12, borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage('assets/images/dog_preview.png'), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          )),
          const SizedBox(width: 8),
          FilledButton(onPressed: (){}, child: const Text('Réserver')),
        ],
      ),
    );
  }
}
