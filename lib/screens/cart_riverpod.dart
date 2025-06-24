import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class CartItem {
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;
  double spiceLevel;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.spiceLevel,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'spiceLevel': spiceLevel,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      spiceLevel: (json['spiceLevel'] as num).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }
}

class CartState {
  final Map<String, CartItem> items;
  final bool isLoading;

  CartState({required this.items, this.isLoading = false});

  double get totalAmount =>
      items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  int get totalQuantity =>
      items.values.fold(0, (sum, item) => sum + item.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: {}));

  void addItem(String productId, String name, double price, int quantity,
      double spiceLevel,
      [String? imageUrl]) {
    final items = {...state.items};
    if (items.containsKey(productId)) {
      items.update(
        productId,
        (existingItem) => CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          quantity: existingItem.quantity + quantity,
          price: existingItem.price,
          spiceLevel: spiceLevel,
          imageUrl: existingItem.imageUrl ?? imageUrl,
        ),
      );
    } else {
      items[productId] = CartItem(
        productId: productId,
        name: name,
        quantity: quantity,
        price: price,
        spiceLevel: spiceLevel,
        imageUrl: imageUrl,
      );
    }
    state = CartState(items: items);
  }

  void removeItem(String productId) {
    final items = {...state.items};
    items.remove(productId);
    state = CartState(items: items);
  }

  void clearCart() {
    state = CartState(items: {});
  }

  void updateQuantity(String productId, int newQuantity) {
    final items = {...state.items};
    if (newQuantity <= 0) {
      items.remove(productId);
    } else {
      items.update(
        productId,
        (existingItem) => CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          quantity: newQuantity,
          price: existingItem.price,
          spiceLevel: existingItem.spiceLevel,
          imageUrl: existingItem.imageUrl,
        ),
      );
    }
    state = CartState(items: items);
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
