import 'package:flutter/material.dart';

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
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    String productId,
    String name,
    double price,
    int quantity,
    double spiceLevel,
    String imageUrl,
  ) {
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
  }

  void increaseItemQuantity(
      String productId, int maxQuantity, BuildContext context) {
    if (!_items.containsKey(productId)) return;

    final currentQuantity = _items[productId]!.quantity;
    if (currentQuantity < maxQuantity) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          quantity: existingItem.quantity + 1,
          price: existingItem.price,
          spiceLevel: existingItem.spiceLevel,
          imageUrl: existingItem.imageUrl,
        ),
      );
      notifyListeners();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đạt số lượng tối đa của món ăn này!')),
      );
    }
  }

  void decreaseItemQuantity(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          quantity: existingItem.quantity - 1,
          price: existingItem.price,
          spiceLevel: existingItem.spiceLevel,
          imageUrl: existingItem.imageUrl,
        ),
      );
    } else {
      removeItem(productId);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
