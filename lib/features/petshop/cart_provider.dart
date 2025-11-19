// lib/features/petshop/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Item dans le panier
class CartItem {
  final String productId;
  final String providerId;
  final String title;
  final int priceDa; // Prix avec commission incluse
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.providerId,
    required this.title,
    required this.priceDa,
    required this.quantity,
    this.imageUrl,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      providerId: providerId,
      title: title,
      priceDa: priceDa,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }
}

/// État du panier
class CartState {
  final List<CartItem> items;
  final String? providerId; // Un panier ne peut contenir que des produits d'un seul shop

  const CartState({this.items = const [], this.providerId});

  int get totalDa => items.fold(0, (sum, item) => sum + (item.priceDa * item.quantity));
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItem>? items, String? providerId}) {
    return CartState(
      items: items ?? this.items,
      providerId: providerId ?? this.providerId,
    );
  }
}

/// Notifier pour gérer le panier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem item) {
    // Si le panier contient des items d'un autre provider, on le vide d'abord
    if (state.providerId != null && state.providerId != item.providerId) {
      state = CartState(items: [item], providerId: item.providerId);
      return;
    }

    // Chercher si le produit existe déjà
    final existing = state.items.indexWhere((i) => i.productId == item.productId);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + item.quantity,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, item],
        providerId: item.providerId,
      );
    }
  }

  void removeItem(String productId) {
    final updated = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(
      items: updated,
      providerId: updated.isEmpty ? null : state.providerId,
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.productId == productId) {
        return i.copyWith(quantity: quantity);
      }
      return i;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void clear() {
    state = const CartState();
  }
}

/// Provider global du panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
