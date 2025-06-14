import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/screens/order_details_screen.dart';
import 'package:provider/provider.dart';
import '../constant/theme_constants.dart';
import '../widgets/network_image.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String foodId;

  const ItemDetailsScreen({
    Key? key,
    required this.foodId,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int quantity = 1;
  double spiceLevel = 1;
  bool _isLoading = true;
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
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching food data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addToCart() {
    if (quantity > availableQuantity || availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Món ăn này đã hết hoặc vượt quá số lượng giới hạn'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    } else {
      Provider.of<CartProvider>(context, listen: false).addItem(
        widget.foodId,
        foodData!['name'],
        (foodData!['price'] as num).toDouble(),
        quantity,
        spiceLevel,
        foodData!['imageUrl'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm vào giỏ hàng'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
    }
  }

  void _navigateToOrderDetailsScreen() {
    final orderItems = [
      CartItem(
        productId: widget.foodId,
        name: foodData!['name'],
        quantity: quantity,
        price: (foodData!['price'] as num).toDouble(),
        spiceLevel: spiceLevel,
        imageUrl: foodData!['imageUrl'],
      )
    ];

    final totalPrice = orderItems[0].price * orderItems[0].quantity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderItems: orderItems,
          totalPrice: totalPrice,
        ),
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
                valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
              ),
            );
          }

          final food = snapshot.data!.data() as Map<String, dynamic>;
          bool isNonSpicy = food['category'] == 'Drinks' || food['category'] == 'Other';

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
                          topLeft: Radius.circular(ThemeConstants.borderRadiusXL),
                          topRight: Radius.circular(ThemeConstants.borderRadiusXL),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        color: ThemeConstants.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
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
                                            style: ThemeConstants.bodyLarge.copyWith(
                                              color: ThemeConstants.primaryColor,
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Không đủ số lượng món ăn có sẵn'),
                                              backgroundColor: ThemeConstants.errorColor,
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
                                inactiveTrackColor: ThemeConstants.primaryColor.withOpacity(0.2),
                                thumbColor: ThemeConstants.primaryColor,
                                overlayColor: ThemeConstants.primaryColor.withOpacity(0.1),
                                valueIndicatorColor: ThemeConstants.primaryColor,
                                valueIndicatorTextStyle: TextStyle(color: Colors.white),
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
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
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
              color: isFavorite ? ThemeConstants.errorColor : ThemeConstants.textSecondaryColor,
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
                      borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
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
