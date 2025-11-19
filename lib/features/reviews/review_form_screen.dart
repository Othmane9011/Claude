import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';


class ReviewFormScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const ReviewFormScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  int rating = 5; String? comment; String? msg;
  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Laisser un avis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children:[
          DropdownButton<int>(
            value: rating,
            items: List.generate(5, (i)=>DropdownMenuItem(value: i+1, child: Text('${i+1} ⭐'))),
            onChanged: (v)=>setState(()=> rating = v ?? 5),
          ),
          TextField(decoration: const InputDecoration(labelText: 'Commentaire'), onChanged: (v)=> comment=v),
          const SizedBox(height: 12),
          FilledButton(onPressed: () async {
            try {
              await api.createReview(bookingId: widget.bookingId, rating: rating, comment: comment);
              setState(()=> msg='Merci pour votre avis ✅');
            } catch(e){ setState(()=> msg='Erreur: $e'); }
          }, child: const Text('Envoyer')),
          if (msg!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(msg!)),
        ]),
      ),
    );
  }
}
