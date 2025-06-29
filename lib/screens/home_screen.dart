import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodie/admin/admin_screen.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/cart_screen.dart';
import 'package:foodie/screens/item_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({super.key, this.isAdmin = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  List<String> _categories = ['Tất cả'];
  List<QueryDocumentSnapshot> _foods = [];
  List<QueryDocumentSnapshot> _featuredFoods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFoods();
    _loadFeaturedFoods();
  }

  Future<void> _loadCategories() async {
    try {
      var categoriesSnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      List<String> cats = ['Tất cả'];
      cats.addAll(categoriesSnapshot.docs.map((doc) => doc['name'] as String));

      if (mounted) {
        setState(() {
          _categories = cats;
        });
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }
  Future<void> _loadFoods() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      Query<Map<String, dynamic>> foodsQuery = FirebaseFirestore.instance.collection('foods');
      if (_selectedCategory != 'Tất cả') {
        foodsQuery = foodsQuery.where('category', isEqualTo: _selectedCategory);
      }
      
      var foodsSnapshot = await foodsQuery.get();

      if (mounted) {
        setState(() {
          _foods = foodsSnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Error loading foods: $e");
    }
  }

  Future<void> _loadFeaturedFoods() async {
    try {
      var foodsSnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .where('featured', isEqualTo: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _featuredFoods = foodsSnapshot.docs;
        });
      }
    } catch (e) {
      debugPrint("Error loading featured foods: $e");
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _loadFoods();
    }
  }

  void _filterFoods(String query) {
    // Thực hiện logic lọc món ăn theo query
    _loadFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          "PXT Food Store",
          style: const TextStyle(
            fontFamily: 'Lobster',
            fontSize: 24,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Nút chuyển đến giao diện admin (chỉ hiển thị nếu người dùng là admin)
          if (widget.isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()),
                );
              },
              tooltip: "Vào giao diện quản trị",
            ),
          // Nút giỏ hàng với badge số lượng
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar & Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.primaryColor),
                        hintText: "Tìm kiếm món ăn...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: _filterFoods,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      // Hiển thị dialog filter nâng cao
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                        builder: (context) => _buildFilterBottomSheet(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Featured Foods Carousel
          if (_featuredFoods.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                "Món nổi bật",
                style: AppTheme.subheadingStyle,
              ),
            ),            CarouselSlider(
              options: CarouselOptions(
                height: 180,
                viewportFraction: 0.85,
                autoPlay: true,
                enlargeCenterPage: true,
                autoPlayInterval: Duration(seconds: 3),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
              ),
              items: _featuredFoods.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailsScreen(foodId: doc.id),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: NetworkImage(data['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${data['price']} VND',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Nổi bật",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
          ],

          // Food Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _onCategorySelected(category),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Food List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : _foods.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy món ăn nào',
                          style: AppTheme.bodyStyle,
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _foods.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = _foods[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(foodId: doc.id),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      data['imageUrl'] ?? '',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${data['price']} VND',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.star, size: 16, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text(
                                              '${(data['rating']?.toDouble() ?? 0.0).toStringAsFixed(1)}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Lọc theo tiêu chí",
            style: AppTheme.headingStyle,
          ),
          SizedBox(height: 20),

          // Filter options
          Text(
            "Giá:",
            style: AppTheme.subheadingStyle,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              FilterChip(
                label: Text("Dưới 50.000đ"),
                onSelected: (bool selected) {},
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text("50.000đ - 100.000đ"),
                onSelected: (bool selected) {},
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
            ],
          ),
          Row(
            children: [
              FilterChip(
                label: Text("100.000đ - 200.000đ"),
                onSelected: (bool selected) {},
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
              SizedBox(width: 8),
              FilterChip(
                label: Text("Trên 200.000đ"),
                onSelected: (bool selected) {},
                backgroundColor: Colors.grey[200],
                selectedColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
            ],
          ),

          SizedBox(height: 15),
          Text(
            "Đánh giá:",
            style: AppTheme.subheadingStyle,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              for (int i = 3; i <= 5; i++)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$i"),
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        Text("+"),
                      ],
                    ),
                    onSelected: (bool selected) {},
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                ),
            ],
          ),

          SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Đặt lại"),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Áp dụng filter
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text("Áp dụng"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
