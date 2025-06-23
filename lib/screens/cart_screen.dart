import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';
import 'order_details_screen.dart';
import 'package:foodie/constant/theme_constants.dart';
import 'package:foodie/widgets/network_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<int> _fetchMaxQuantity(String productId) async {
    final doc = await FirebaseFirestore.instance
        .collection('foods')
        .doc(productId)
        .get();
    if (doc.exists) {
      return doc['quantity'] ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: ThemeConstants.primaryGradient,
              ),
              padding: EdgeInsets.all(ThemeConstants.spacingLG),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: ThemeConstants.shadowSm,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: ThemeConstants.textPrimaryColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: ThemeConstants.spacingMD),
                  Text(
                    'Giỏ hàng',
                    style: ThemeConstants.headingLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  if (cart.items.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: ThemeConstants.shadowSm,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: ThemeConstants.errorColor,
                          size: 20,
                        ),
                        onPressed: () {
                          cart.clearCart();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: cart.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                          SizedBox(height: ThemeConstants.spacingMD),
                          Text(
                            'Giỏ hàng trống',
                            style: ThemeConstants.headingMedium,
                          ),
                          SizedBox(height: ThemeConstants.spacingSM),
                          Text(
                            'Hãy thêm món ăn vào giỏ hàng',
                            style: ThemeConstants.bodyLarge.copyWith(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(ThemeConstants.spacingMD),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final cartItem = cart.items.values.toList()[index];
                        final productId = cart.items.keys.toList()[index];

                        return FutureBuilder<int>(
                          future: _fetchMaxQuantity(productId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      ThemeConstants.primaryColor),
                                ),
                              );
                            }

                            final maxQuantity = snapshot.data ?? 0;

                            return Container(
                              margin: EdgeInsets.only(
                                  bottom: ThemeConstants.spacingMD),
                              decoration: BoxDecoration(
                                color: ThemeConstants.surfaceColor,
                                borderRadius: BorderRadius.circular(
                                    ThemeConstants.borderRadiusLG),
                                boxShadow: ThemeConstants.shadowSm,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          ThemeConstants.borderRadiusLG),
                                      bottomLeft: Radius.circular(
                                          ThemeConstants.borderRadiusLG),
                                    ),
                                    child: NetworkImageWithFallback(
                                      imageUrl: cartItem.imageUrl ??
                                          'assets/images/placeholder.jpg',
                                      width: 100,
                                      height: 100,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                          ThemeConstants.spacingMD),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  cartItem.name,
                                                  style: ThemeConstants
                                                      .bodyLarge
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  size: 20,
                                                  color: ThemeConstants
                                                      .textSecondaryColor,
                                                ),
                                                onPressed: () {
                                                  cart.removeItem(productId);
                                                },
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: ThemeConstants.spacingXS),
                                          Text(
                                            '${cartItem.price.toStringAsFixed(0)} VNĐ',
                                            style: ThemeConstants.bodyMedium
                                                .copyWith(
                                              color:
                                                  ThemeConstants.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                              height: ThemeConstants.spacingSM),
                                          Row(
                                            children: [
                                              _buildQuantityButton(
                                                icon: Icons.remove,
                                                onPressed: cartItem.quantity > 1
                                                    ? () {
                                                        cart.decreaseItemQuantity(
                                                            productId);
                                                      }
                                                    : null,
                                              ),
                                              Container(
                                                width: 40,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  cartItem.quantity.toString(),
                                                  style:
                                                      ThemeConstants.bodyLarge,
                                                ),
                                              ),
                                              _buildQuantityButton(
                                                icon: Icons.add,
                                                onPressed: cartItem.quantity <
                                                        maxQuantity
                                                    ? () {
                                                        cart.increaseItemQuantity(
                                                          productId,
                                                          maxQuantity,
                                                          context,
                                                        );
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.all(ThemeConstants.spacingMD),
              decoration: BoxDecoration(
                color: ThemeConstants.surfaceColor,
                boxShadow: ThemeConstants.shadowLg,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng cộng',
                          style: ThemeConstants.bodyLarge.copyWith(
                            color: ThemeConstants.textSecondaryColor,
                          ),
                        ),
                        Text(
                          '${cart.totalAmount.toStringAsFixed(0)} VNĐ',
                          style: ThemeConstants.headingMedium.copyWith(
                            color: ThemeConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ThemeConstants.spacingMD),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: cart.items.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      orderItems: cart.items.values.toList(),
                                      totalPrice: cart.totalAmount,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: ThemeConstants.spacingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                ThemeConstants.borderRadiusLG),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Thanh toán',
                          style: ThemeConstants.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.surfaceColor,
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 18,
          color: onPressed == null
              ? ThemeConstants.textSecondaryColor
              : ThemeConstants.textPrimaryColor,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.all(ThemeConstants.spacingXS),
        constraints: BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }
}
