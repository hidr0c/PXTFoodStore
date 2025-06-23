import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constant/theme_constants.dart';
import '../widgets/category_selector.dart';
import '../widgets/food_card.dart';
import 'bottom_appbar_menu.dart';
import 'customer_support_screen.dart';
import 'floating_button.dart';
import 'item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, this.isAdmin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "Chicken";
  String _searchKeyword = "";
  final List<String> favoriteItems = [];

  final List<Map<String, String>> categories = [
    {"name": "Chicken", "image": "assets/images/1.jpg"},
    {"name": "Burger", "image": "assets/images/2.jpg"},
    {"name": "Drinks", "image": "assets/images/3.jpg"},
    {"name": "Other", "image": "assets/images/4.jpg"},
    {"name": "Pizza", "image": "assets/images/5.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: ThemeConstants.primaryGradient,
                ),
                padding: EdgeInsets.only(
                  top: ThemeConstants.spacingLG,
                  bottom: ThemeConstants.spacingLG,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: ThemeConstants.spacingMD),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CategorySelector(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(ThemeConstants.spacingMD),
              sliver: _buildFoodList(),
            ),
          ],
        ),
      ),
      floatingActionButton: const FloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBarMenu(),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ThemeConstants.spacingMD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3P Food',
                    style: ThemeConstants.headingLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Lobster',
                    ),
                  ),
                  SizedBox(height: ThemeConstants.spacingXS),
                  Text(
                    'Vị ngon trên từng ngón tay!',
                    style: ThemeConstants.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: ThemeConstants.shadowSm,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.message_outlined,
                    color: ThemeConstants.primaryColor,
                  ),
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
            ],
          ),
        ),
        SizedBox(height: ThemeConstants.spacingMD),
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
          ),
          items: [
            'assets/images/1.jpg',
            'assets/images/2.jpg',
            'assets/images/3.jpg',
          ].map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ThemeConstants.spacingMD),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
          boxShadow: ThemeConstants.shadowSm,
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Tìm kiếm món ăn...",
            hintStyle: ThemeConstants.bodyMedium,
            prefixIcon: Icon(
              Icons.search,
              color: ThemeConstants.textSecondaryColor,
            ),
            suffixIcon: Icon(
              Icons.filter_list,
              color: ThemeConstants.textSecondaryColor,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: ThemeConstants.spacingMD,
              vertical: ThemeConstants.spacingSM,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchKeyword = value.toLowerCase();
            });
          },
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .where('category', isEqualTo: selectedCategory)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "Không có món ăn nào trong danh mục này.",
                style: ThemeConstants.bodyLarge,
              ),
            ),
          );
        }

        List<DocumentSnapshot> foodItems = snapshot.data!.docs;
        List<DocumentSnapshot> filteredFoodItems = foodItems.where((food) {
          String name = food['name'].toString().toLowerCase();
          return name.contains(_searchKeyword);
        }).toList();

        if (filteredFoodItems.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "Không tìm thấy món ăn nào.",
                style: ThemeConstants.bodyLarge,
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            mainAxisSpacing: ThemeConstants.spacingSM,
            crossAxisSpacing: ThemeConstants.spacingSM,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              var food = filteredFoodItems[index];
              bool isFavorite = favoriteItems.contains(food['name']);

              return FoodCard(
                imageUrl: food['imageUrl'],
                name: food['name'],
                price: (food['price'] as num).toDouble(),
                category: food['category'],
                isFavorite: isFavorite,
                onFavoriteToggle: () {
                  setState(() {
                    if (isFavorite) {
                      favoriteItems.remove(food['name']);
                    } else {
                      favoriteItems.add(food['name']);
                    }
                  });
                },
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
              );
            },
            childCount: filteredFoodItems.length,
          ),
        );
      },
    );
  }
}
