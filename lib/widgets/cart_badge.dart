import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/cart_provider.dart';

class CartBadge extends StatelessWidget {
  final Widget child;
  final Color? color;
  const CartBadge({
    super.key,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            this.child,
            if (cart.totalQuantity > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color ?? Colors.red,
                    borderRadius:
                        BorderRadius.circular(8), // Giảm border radius
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.1), // Giảm opacity
                        blurRadius: 2, // Giảm độ mờ
                        offset: const Offset(0, 1), // Giảm offset
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18, // Nhỏ hơn một chút
                    minHeight: 18, // Nhỏ hơn một chút
                  ),
                  child: Text(
                    cart.totalQuantity > 99
                        ? '99+'
                        : cart.totalQuantity.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
