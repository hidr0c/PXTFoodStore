import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/screens/order_details_screen.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import '../constant/app_color.dart';
import 'cart_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String foodId;

  const ItemDetailsScreen({
    super.key,
    required this.foodId,
  });

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int quantity = 1;
  double spiceLevel = 1;
  bool _isLoading = true;
  DocumentSnapshot? foodData;
  int availableQuantity = 0;

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
    }
  }

  void _addToCart() {
    if (quantity > availableQuantity || availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Món ăn này đã hết hoặc vượt quá số lượng giới hạn')),
      );
    } else {
      // Thêm vào giỏ hàng
      Provider.of<CartProvider>(context, listen: false).addItem(
        widget.foodId,
        foodData!['name'],
        (foodData!['price'] as num).toDouble(),
        quantity,
        spiceLevel,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm vào giỏ hàng')),
      );
    }
  }

  void _navigateToCartScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(),
      ),
    );
  }

  void _navigateToOrderDetailsScreen() {
    final orderItems = [
      CartItem(
        productId: widget.foodId,
        name: foodData!['name'],
        quantity: quantity,
        price: (foodData!['price'] as num).toDouble(),
        spiceLevel: spiceLevel,
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
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (foodData == null || !foodData!.exists) {
      return Scaffold(
        body: Center(child: Text('Món ăn không tồn tại')),
      );
    }

    var food = foodData!.data() as Map<String, dynamic>;
    // double price = (food['price'] as num).toDouble();
    bool isNonSpicy =
        food['category'] == 'Drinks' || food['category'] == 'Other';

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(5.0),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.365,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(food['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Text(
                    food['name'],
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColor.itemListStarColor,
                      ),
                      Text(" 4.8 - 14 mins"),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Text(
                    food['description'],
                    style: TextStyle(
                      color: AppColor.itemDetailsTextColor,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Text(
                    "Số lượng",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        if (quantity > 1) setState(() => quantity--);
                      }),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        if (quantity < availableQuantity) {
                          setState(() => quantity++);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                Text('Không đủ số lượng món ăn có sẵn')),
                          );
                        }
                      }),
                    ],
                  ),
                  if (!isNonSpicy) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      "Mức độ cay",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
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
                      activeColor: AppColor.primaryColor,
                      inactiveColor: Colors.grey.shade400,
                    ),
                  ],
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.17,
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _addToCart();
                      _navigateToCartScreen();
                    },
                    child: Container(
                      height: 70,
                      width: MediaQuery.of(context).size.width * 0.30,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColor.primaryColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_cart,
                          color: AppColor.priceButtonTextColor,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToOrderDetailsScreen,
                    child: Container(
                      height: 70,
                      width: MediaQuery.of(context).size.width * 0.530,
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColor.orderButtonTextColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          "ĐẶT HÀNG NGAY",
                          style: TextStyle(
                            color: AppColor.priceButtonTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColor.primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}
