import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final double spiceLevel;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.spiceLevel = 0,
    this.imageUrl,
  });

  // Convert CartItem to JSON
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

  // Create CartItem from JSON
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

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  int get totalQuantity {
    int quantity = 0;
    _items.forEach((key, cartItem) {
      quantity += cartItem.quantity;
    });
    return quantity;
  }

  double get totalAmount {
    double total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Load cart from SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');

      if (cartJson != null) {
        final cartMap = json.decode(cartJson) as Map<String, dynamic>;
        _items.clear();

        cartMap.forEach((key, value) {
          _items[key] = CartItem.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      notifyListeners();
    }
  }

  // Save cart to SharedPreferences
  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartMap = <String, dynamic>{};

      _items.forEach((key, cartItem) {
        cartMap[key] = cartItem.toJson();
      });

      await prefs.setString('cart', json.encode(cartMap));
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    required int quantity,
    required double spiceLevel,
    String? imageUrl,
  }) {
    if (_items.containsKey(productId)) {
      // Update quantity if already in cart
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + quantity,
          spiceLevel: spiceLevel,
          imageUrl: existingCartItem.imageUrl ?? imageUrl,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        productId,
        () => CartItem(
          productId: productId,
          name: name,
          price: price,
          quantity: quantity,
          spiceLevel: spiceLevel,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
    saveCart(); // Auto-save after adding
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: quantity,
          spiceLevel: existingCartItem.spiceLevel,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
      notifyListeners();
      saveCart();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    saveCart();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
    saveCart();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  // Get cart summary for checkout
  Map<String, dynamic> getCartSummary() {
    return {
      'items': _items.values.map((item) => item.toJson()).toList(),
      'totalItems': itemCount,
      'totalAmount': totalAmount,
    };
  }
}
