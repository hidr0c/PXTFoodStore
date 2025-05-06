import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/screens/feedback_view_screen.dart';
import 'package:foodie/utils/currency_formatter.dart';

import '../constant/app_color.dart';
import 'bottom_appbar_menu.dart';
import 'customer_support_screen.dart';
import 'floating_button.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "Chicken";
  String _searchKeyword = "";
  final List<String> favoriteItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColor.primaryColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.05,
                bottom: 20,
                left: 8,
                right: 8,
              ),
              child: Column(
                children: [
                  _homeHeader(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _searchSection(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _categorySlider(),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  _itemList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBarMenu(),
    );
  }

  Widget _homeHeader() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3P Food',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontFamily: 'Lobster',
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vị ngon trên từng ngón tay!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.message_outlined,
                        color: AppColor.primaryColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerSupportScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: "Tìm kiếm",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            _searchKeyword = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _categorySliderItem(String imagePath, String categoryName) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = categoryName;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          width: 50,
          height: 50,
          decoration: ShapeDecoration(
            color: selectedCategory == categoryName
                ? AppColor.primaryColor
                : Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                width: 35,
                height: 35,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categorySlider() {
    List<Map<String, String>> categories = [
      {"name": "Chicken", "image": "assets/images/1.jpg"},
      {"name": "Burger", "image": "assets/images/2.jpg"},
      {"name": "Drinks", "image": "assets/images/3.jpg"},
      {"name": "Other", "image": "assets/images/4.jpg"},
      {"name": "Pizza", "image": "assets/images/5.jpg"},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.1,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Center(
        child: Wrap(
          spacing: 10,
          alignment: WrapAlignment.center,
          children: categories.map((category) {
            return _categorySliderItem(category["image"]!, category["name"]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _itemList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .where('category', isEqualTo: selectedCategory)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Không có món ăn nào trong danh mục này."),
          );
        }

        List<DocumentSnapshot> foodItems = snapshot.data!.docs;

        List<DocumentSnapshot> filteredFoodItems = foodItems.where((food) {
          String name = food['name'].toString().toLowerCase();
          return name.contains(_searchKeyword);
        }).toList();

        if (filteredFoodItems.isEmpty) {
          return const Center(
            child: Text("Không tìm thấy món ăn nào."),
          );
        }

        return Column(
          children: List.generate(filteredFoodItems.length, (index) {
            var food = filteredFoodItems[index];
            bool isFavorite = favoriteItems.contains(food['name']);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailsScreen(
                      foodId: food.id,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        food['imageUrl'] ?? "",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported,
                          size: 80,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            food['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          CurrencyFormatter.format(food['price']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isFavorite) {
                                    favoriteItems.remove(food['name']);
                                  } else {
                                    favoriteItems.add(food['name']);
                                  }
                                });
                              },
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.13,
                              height: MediaQuery.of(context).size.height * 0.05,
                              decoration: ShapeDecoration(
                                color: AppColor.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.white),
                                onPressed: () {
                                  String foodId = food.id;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FeedbackViewScreen(foodId: foodId),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
