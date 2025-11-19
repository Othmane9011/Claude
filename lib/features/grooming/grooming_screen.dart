import 'package:flutter/material.dart';

class GroomingScreen extends StatelessWidget {
  const GroomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(String title) {
      return Container(
        height: 140, margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)],
          image: const DecorationImage(
            image: AssetImage('assets/images/dog_preview.png'),
            fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: Center(child: Text(title, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Toilettage')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/images/dog_preview.png')),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bienvenue, Ikram', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Quel service pour votre compagnon aujourd’hui ?',
                  style: TextStyle(color: Colors.black.withOpacity(.6), fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 16),
          card('Soin du pelage'),
          card('Bain & Nettoyage'),
          card('Soins des griffes'),
        ],
      ),
    );
  }
}
