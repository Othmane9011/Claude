// lib/features/petshop/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Commission fixe par commande (en DA)
const int kPetshopCommissionDa = 50;

/// Item du panier
class CartItem {
  final String productId;
  final String providerId;
  final String providerName;
  final String title;
  final int priceDa;
  final int quantity;
  final String? imageUrl;
  final int stock; // Pour validation

  const CartItem({
    required this.productId,
    required this.providerId,
    required this.providerName,
    required this.title,
    required this.priceDa,
    required this.quantity,
    this.imageUrl,
    required this.stock,
  });

  CartItem copyWith({
    String? productId,
    String? providerId,
    String? providerName,
    String? title,
    int? priceDa,
    int? quantity,
    String? imageUrl,
    int? stock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      title: title ?? this.title,
      priceDa: priceDa ?? this.priceDa,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
    );
  }

  int get totalDa => priceDa * quantity;
}

/// État du panier
class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  /// Nombre total d'articles
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Sous-total (prix des produits)
  int get subtotalDa => items.fold(0, (sum, item) => sum + item.totalDa);

  /// Commission (fixe par boutique)
  int get commissionDa {
    // Une commission par boutique différente
    final shops = items.map((i) => i.providerId).toSet();
    return shops.length * kPetshopCommissionDa;
  }

  /// Total à payer
  int get totalDa => subtotalDa + commissionDa;

  /// Grouper par boutique
  Map<String, List<CartItem>> get itemsByProvider {
    final result = <String, List<CartItem>>{};
    for (final item in items) {
      result.putIfAbsent(item.providerId, () => []).add(item);
    }
    return result;
  }

  /// Vérifier si le panier est vide
  bool get isEmpty => items.isEmpty;

  /// Nombre de boutiques différentes
  int get providerCount => items.map((i) => i.providerId).toSet().length;

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

/// Notifier pour gérer le panier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Ajouter un produit au panier
  void addItem({
    required String productId,
    required String providerId,
    required String providerName,
    required String title,
    required int priceDa,
    required int stock,
    String? imageUrl,
    int quantity = 1,
  }) {
    final existingIndex = state.items.indexWhere((i) => i.productId == productId);

    if (existingIndex >= 0) {
      // Mettre à jour la quantité
      final existing = state.items[existingIndex];
      final newQty = existing.quantity + quantity;

      // Ne pas dépasser le stock
      if (newQty > stock) return;

      final updatedItems = [...state.items];
      updatedItems[existingIndex] = existing.copyWith(quantity: newQty);
      state = state.copyWith(items: updatedItems);
    } else {
      // Ajouter nouveau
      state = state.copyWith(items: [
        ...state.items,
        CartItem(
          productId: productId,
          providerId: providerId,
          providerName: providerName,
          title: title,
          priceDa: priceDa,
          quantity: quantity,
          imageUrl: imageUrl,
          stock: stock,
        ),
      ]);
    }
  }

  /// Retirer un produit du panier
  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  /// Mettre à jour la quantité
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;

    final item = state.items[index];
    // Ne pas dépasser le stock
    final newQty = quantity > item.stock ? item.stock : quantity;

    final updatedItems = [...state.items];
    updatedItems[index] = item.copyWith(quantity: newQty);
    state = state.copyWith(items: updatedItems);
  }

  /// Incrémenter la quantité
  void incrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (i) => i.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    if (item.quantity < item.stock) {
      updateQuantity(productId, item.quantity + 1);
    }
  }

  /// Décrémenter la quantité
  void decrementQuantity(String productId) {
    final item = state.items.firstWhere(
      (i) => i.productId == productId,
      orElse: () => throw Exception('Item not found'),
    );
    updateQuantity(productId, item.quantity - 1);
  }

  /// Vider le panier
  void clear() {
    state = const CartState();
  }

  /// Vider les produits d'une boutique spécifique
  void clearProvider(String providerId) {
    state = state.copyWith(
      items: state.items.where((i) => i.providerId != providerId).toList(),
    );
  }

  /// Obtenir la quantité d'un produit
  int getQuantity(String productId) {
    final item = state.items.where((i) => i.productId == productId).firstOrNull;
    return item?.quantity ?? 0;
  }

  /// Vérifier si un produit est dans le panier
  bool hasItem(String productId) {
    return state.items.any((i) => i.productId == productId);
  }

  /// Convertir pour l'API
  List<Map<String, dynamic>> toApiItems(String providerId) {
    return state.items
        .where((i) => i.providerId == providerId)
        .map((i) => {
              'productId': i.productId,
              'quantity': i.quantity,
            })
        .toList();
  }
}

/// Provider global du panier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

/// Provider pour le nombre d'items (pour les badges)
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

/// Provider pour vérifier si le panier est vide
final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});
