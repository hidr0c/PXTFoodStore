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
        SnackBar(
          content:
              const Text('Món ăn này đã hết hoặc vượt quá số lượng giới hạn'),
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
            onPressed: () => _navigateToCartScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('foods')
            .doc(widget.foodId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
              ),
            );
          }

          final food = snapshot.data!.data() as Map<String, dynamic>;
          bool isNonSpicy =
              food['category'] == 'Drinks' || food['category'] == 'Other';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(food),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ThemeConstants.surfaceColor,
                        borderRadius: BorderRadius.only(
                          topLeft:
                              Radius.circular(ThemeConstants.borderRadiusXL),
                          topRight:
                              Radius.circular(ThemeConstants.borderRadiusXL),
                        ),
                        boxShadow: ThemeConstants.shadowLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(ThemeConstants.spacingLG),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        food['name'],
                                        style: ThemeConstants.headingLarge,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ThemeConstants.spacingSM,
                                        vertical: ThemeConstants.spacingXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ThemeConstants.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            ThemeConstants.borderRadiusLG),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: ThemeConstants.primaryColor,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '4.8',
                                            style: ThemeConstants.bodyLarge
                                                .copyWith(
                                              color:
                                                  ThemeConstants.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ThemeConstants.spacingSM),
                                Text(
                                  '${(food['price'] as num).toStringAsFixed(0)} VNĐ',
                                  style: ThemeConstants.headingMedium.copyWith(
                                    color: ThemeConstants.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: ThemeConstants.spacingMD),
                                Text(
                                  'Mô tả',
                                  style: ThemeConstants.headingSmall,
                                ),
                                SizedBox(height: ThemeConstants.spacingSM),
                                Text(
                                  food['description'] ?? 'Không có mô tả',
                                  style: ThemeConstants.bodyLarge.copyWith(
                                    color: ThemeConstants.textSecondaryColor,
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: ThemeConstants.spacingLG),
                                Text(
                                  'Số lượng',
                                  style: ThemeConstants.headingSmall,
                                ),
                                SizedBox(height: ThemeConstants.spacingSM),
                                Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setState(() => quantity--);
                                        }
                                      },
                                    ),
                                    Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        quantity.toString(),
                                        style: ThemeConstants.headingSmall,
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      icon: Icons.add,
                                      onPressed: () {
                                        if (quantity < availableQuantity) {
                                          setState(() => quantity++);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Không đủ số lượng món ăn có sẵn'),
                                              backgroundColor:
                                                  ThemeConstants.errorColor,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ThemeConstants.spacingLG),
                          if (!isNonSpicy) ...[
                            Text(
                              "Mức độ cay",
                              style: ThemeConstants.headingSmall,
                            ),
                            SizedBox(height: ThemeConstants.spacingSM),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: ThemeConstants.primaryColor,
                                inactiveTrackColor: ThemeConstants.primaryColor
                                    .withValues(alpha: 0.2),
                                thumbColor: ThemeConstants.primaryColor,
                                overlayColor: ThemeConstants.primaryColor
                                    .withValues(alpha: 0.1),
                                valueIndicatorColor:
                                    ThemeConstants.primaryColor,
                                valueIndicatorTextStyle:
                                    TextStyle(color: Colors.white),
                              ),
                              child: Slider(
                                value: spiceLevel,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: "$spiceLevel",
                                onChanged: (double newValue) {
                                  setState(() {
                                    spiceLevel = newValue;
                                  });
                                },
                              ),
                            ),
                          ],
                          SizedBox(height: ThemeConstants.spacingLG),

                          // Rating and Review Section
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: ThemeConstants.spacingLG),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade50, // Giảm độ đậm
                                        Colors.white
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        10), // Giảm border radius
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: 5), // Giảm opacity
                                        blurRadius: 4, // Giảm blur
                                        offset: Offset(0, 1), // Giảm offset
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(12), // Giảm padding
                                  margin: EdgeInsets.symmetric(
                                      vertical: 6), // Giảm margin
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            color: Colors.orange.shade700,
                                            size: 20, // Giảm kích thước icon
                                          ),
                                          SizedBox(
                                              width: 6), // Giảm khoảng cách
                                          Flexible(
                                            // Để tránh overflow trong các thiết bị nhỏ
                                            child: Text(
                                              "Đánh giá và nhận xét",
                                              style: ThemeConstants.headingSmall
                                                  .copyWith(
                                                color: ThemeConstants
                                                    .textPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    14, // Giảm kích thước font
                                              ),
                                              overflow: TextOverflow
                                                  .ellipsis, // Xử lý overflow
                                            ),
                                          ),
                                        ],
                                      ),
                                      OutlinedButton.icon(
                                        icon: Icon(
                                          Icons.rate_review_rounded,
                                          color: ThemeConstants.primaryColor,
                                          size: 16, // Giảm kích thước icon
                                        ),
                                        label: Text(
                                          'Viết đánh giá',
                                          style: TextStyle(
                                            color: ThemeConstants.primaryColor,
                                            fontWeight:
                                                FontWeight.w500, // Giảm độ đậm
                                            fontSize: 12,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              ThemeConstants.primaryColor,
                                          side: BorderSide(
                                              color:
                                                  ThemeConstants.primaryColor,
                                              width: 1), // Border mỏng
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6), // Giảm padding
                                          elevation: 0, // Không shadow
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                8), // Giảm border radius
                                          ),
                                        ),
                                        onPressed: () {
                                          // Check if user is admin
                                          final isAdmin = FirebaseAuth.instance
                                                  .currentUser?.email ==
                                              'admin@foodstore.com';

                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                RatingReviewDialog(
                                              productId: widget.foodId,
                                              productName: food['name'],
                                              isAdmin: isAdmin,
                                              onReviewAdded: () {
                                                // Refresh the screen
                                                setState(() {});
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ThemeConstants.spacingSM),
                                ReviewsSection(
                                  productId: widget.foodId,
                                  productName: food['name'],
                                  imageUrl: food['imageUrl'],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ThemeConstants.spacingXL * 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              _buildBottomBar(food),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> food) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWithFallback(
              imageUrl: food['imageUrl'],
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(ThemeConstants.spacingSM),
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
      actions: [
        Container(
          margin: EdgeInsets.all(ThemeConstants.spacingSM),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: ThemeConstants.shadowSm,
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? ThemeConstants.errorColor
                  : ThemeConstants.textSecondaryColor,
              size: 20,
            ),
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
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
          size: 20,
          color: ThemeConstants.textPrimaryColor,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> food) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(ThemeConstants.spacingMD),
        decoration: BoxDecoration(
          color: ThemeConstants.surfaceColor,
          boxShadow: ThemeConstants.shadowLg,
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tổng cộng',
                      style: ThemeConstants.bodyMedium.copyWith(
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '${((food['price'] as num) * quantity).toStringAsFixed(0)} VNĐ',
                      style: ThemeConstants.headingMedium.copyWith(
                        color: ThemeConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ThemeConstants.spacingMD),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ThemeConstants.spacingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ThemeConstants.borderRadiusLG),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Thêm vào giỏ',
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
    );
  }
}
