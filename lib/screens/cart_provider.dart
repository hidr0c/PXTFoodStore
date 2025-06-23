import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, CartItem> _items = {};
  bool _isLoading = false;

  Map<String, CartItem> get items => {..._items};

  bool get isLoading => _isLoading;

  int get itemCount {
    return _items.length;
  }

  int get totalQuantity {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Load cart from SharedPreferences
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

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
      _isLoading = false;
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

  void addItem(
    String productId,
    String name,
    double price,
    int quantity,
    double spiceLevel, [
    String? imageUrl,
  ]) {
    if (_items.containsKey(productId)) {
      _items.update(
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
      _items.putIfAbsent(
        productId,
        () => CartItem(
          productId: productId,
          name: name,
          quantity: quantity,
          price: price,
          spiceLevel: spiceLevel,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
    saveCart(); // Auto-save after adding
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    _items.update(
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
    notifyListeners();
    saveCart();
  }

  void increaseItemQuantity(
      String productId, int maxQuantity, BuildContext context) {
    if (!_items.containsKey(productId)) return;

    final currentQuantity = _items[productId]!.quantity;
    if (currentQuantity < maxQuantity) {
      updateQuantity(productId, currentQuantity + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đạt số lượng tối đa của món ăn này!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void decreaseItemQuantity(String productId) {
    if (!_items.containsKey(productId)) return;

    final currentQuantity = _items[productId]!.quantity;
    updateQuantity(productId, currentQuantity - 1);
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    saveCart();
  }

  void clearCart() {
    _items.clear();
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
      'totalItems': totalQuantity,
      'totalAmount': totalAmount,
      'itemCount': itemCount,
    };
  }
}
