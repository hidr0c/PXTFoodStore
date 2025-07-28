// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constant/theme_constants.dart';
import '../widgets/network_image.dart';
import '../widgets/reviews_section.dart';
import '../widgets/rating_review_dialog.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String foodId;

  const ItemDetailsScreen({
    super.key,
    required this.foodId,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int quantity = 1;
  double spiceLevel = 1;
  DocumentSnapshot? foodData;
  int availableQuantity = 0;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchFoodData();
  }

  Future<void> _fetchFoodData() async {
    try {
      DocumentSnapshot foodSnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.foodId)
          .get();
      setState(() {
        foodData = foodSnapshot;
        availableQuantity = foodSnapshot['quantity'];
      });
    } catch (e) {
      debugPrint('Error fetching food data: $e');
    }
  }

  void _addToCart() {
    if (quantity > availableQuantity || availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Món ăn này đã hết hoặc vượt quá số lượng giới hạn'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.addItem(
        productId: widget.foodId,
        name: foodData!['name'],
        price: (foodData!['price'] as num).toDouble(),
        quantity: quantity,
        spiceLevel: spiceLevel,
        imageUrl: foodData!['imageUrl'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm $quantity ${foodData!['name']} vào giỏ hàng'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Xem giỏ hàng',
            textColor: Colors.white,
            onPressed: _navigateToCartScreen,
          ),
        ),
      );
    }
  }

  void _navigateToCartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartScreen(),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: ThemeConstants.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
          ),
        ),
        child: Icon(icon, size: 20, color: ThemeConstants.textPrimaryColor),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(Map<String, dynamic> food) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: NetworkImageWithFallback(
          imageUrl: food['imageUrl'],
          fit: BoxFit.cover,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            setState(() {
              isFavorite = !isFavorite;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.foodId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: ThemeConstants.backgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
              ),
            ),
          );
        }
        final food = snapshot.data!.data() as Map<String, dynamic>;
        final isNonSpicy =
            food['category'] == 'Drinks' || food['category'] == 'Other';
        return Scaffold(
          backgroundColor: ThemeConstants.backgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(food),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: ThemeConstants.surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ThemeConstants.borderRadiusXL),
                      topRight: Radius.circular(ThemeConstants.borderRadiusXL),
                    ),
                    boxShadow: ThemeConstants.shadowLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(ThemeConstants.spacingLG),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food['name'],
                              style: ThemeConstants.headingMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                                height: ThemeConstants
                                    .spacingMD), // Increased spacing
                            Text(
                              '${(food['price'] as num).toStringAsFixed(0)} VNĐ',
                              style: ThemeConstants.bodyLarge.copyWith(
                                color: ThemeConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: ThemeConstants.spacingMD),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Số lượng',
                                  style: ThemeConstants.bodyMedium,
                                ),
                                Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setState(() {
                                            quantity--;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(
                                        width: ThemeConstants.spacingSM),
                                    Text(
                                      '$quantity',
                                      style: ThemeConstants.bodyLarge,
                                    ),
                                    const SizedBox(
                                        width: ThemeConstants.spacingSM),
                                    _buildQuantityButton(
                                      icon: Icons.add,
                                      onPressed: () {
                                        if (quantity < availableQuantity) {
                                          setState(() {
                                            quantity++;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isNonSpicy) ...[
                              const SizedBox(height: ThemeConstants.spacingMD),
                              Text(
                                'Độ cay',
                                style: ThemeConstants.bodyMedium,
                              ),
                              Slider(
                                value: spiceLevel,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: spiceLevel.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    spiceLevel = value;
                                  });
                                },
                                activeColor: ThemeConstants.primaryColor,
                              ),
                            ],
                            const SizedBox(
                                height: ThemeConstants
                                    .spacingLG), // Increased spacing
                            ElevatedButton(
                              onPressed: _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeConstants.primaryColor,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      ThemeConstants.borderRadiusMD),
                                ),
                              ),
                              child: const Text(
                                'Thêm vào giỏ hàng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ReviewsSection(
                        productId: widget.foodId,
                        productName: food['name'],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(
                ThemeConstants.spacingLG), // Increased padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .start, // Changed to start for better alignment
              children: [
                Expanded(
                  child: Text(
                    'Tổng: ${(food['price'] * quantity).toStringAsFixed(0)} VNĐ',
                    style: ThemeConstants.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
