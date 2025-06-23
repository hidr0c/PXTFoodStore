import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/cart_provider.dart';

class AddToCartButton extends StatefulWidget {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double spiceLevel;
  final String? imageUrl;
  final VoidCallback? onAdded;
  const AddToCartButton({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.spiceLevel,
    this.imageUrl,
    this.onAdded,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToCart() async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(
      widget.productId,
      widget.productName,
      widget.price,
      widget.quantity,
      widget.spiceLevel,
      widget.imageUrl,
    );

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isAdding = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${widget.productName} vào giỏ hàng'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final isInCart = cart.isInCart(widget.productId);
        final currentQuantity = cart.getQuantity(widget.productId);

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isAdding ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInCart ? Colors.green : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInCart ? Icons.check : Icons.add_shopping_cart,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isInCart
                                  ? 'Trong giỏ ($currentQuantity)'
                                  : 'Thêm vào giỏ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
