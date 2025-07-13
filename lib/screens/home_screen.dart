import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  String _searchQuery = '';

  // Filter state
  String? _selectedPriceFilter;
  int? _selectedRatingFilter;

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

      // Remove duplicates but keep "Tất cả" at the start
      final uniqueCats = ['Tất cả', ...{...cats}..remove('Tất cả')];

      if (mounted) {
        setState(() {
          _categories = uniqueCats;
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

      Query<Map<String, dynamic>> foodsQuery =
          FirebaseFirestore.instance.collection('foods');
      if (_selectedCategory != 'Tất cả') {
        foodsQuery = foodsQuery.where('category', isEqualTo: _selectedCategory);
      }

      var foodsSnapshot = await foodsQuery.get();

      if (mounted) {
        setState(() {
          _foods = foodsSnapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            bool matches = true;
            // Search filter
            if (_searchQuery.isNotEmpty) {
              matches &= (data['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            }
            // Price filter
            if (_selectedPriceFilter != null) {
              final price = (data['price'] ?? 0) is int ? (data['price'] ?? 0).toDouble() : (data['price'] ?? 0);
              switch (_selectedPriceFilter) {
                case "Dưới 50.000đ":
                  matches &= price < 50000;
                  break;
                case "50.000đ - 100.000đ":
                  matches &= price >= 50000 && price <= 100000;
                  break;
                case "100.000đ - 200.000đ":
                  matches &= price > 100000 && price <= 200000;
                  break;
                case "Trên 200.000đ":
                  matches &= price > 200000;
                  break;
              }
            }
            // Rating filter
            if (_selectedRatingFilter != null) {
              final rating = (data['rating'] ?? 0).toDouble();
              matches &= rating >= _selectedRatingFilter!;
            }
            return matches;
          }).toList();
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
    setState(() {
      _searchQuery = query;
    });
    _loadFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          "PXT Food Store",
          style: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon:
                            Icon(Icons.search, color: AppTheme.primaryColor),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterFoods('');
                                },
                              )
                            : null,
                        hintText: "Tìm kiếm món ăn...",
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      ),
                      onChanged: _filterFoods,
                      onSubmitted: _filterFoods,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => _buildFilterBottomSheet(),
                      );
                    },
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Featured Foods Carousel
          if (_featuredFoods.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Món nổi bật",
                style: AppTheme.subheadingStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.85,
                autoPlay: true,
                enlargeCenterPage: true,
                autoPlayInterval: Duration(seconds: 3),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                autoPlayCurve: Curves.easeInOut,
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
                            builder: (context) =>
                                ItemDetailsScreen(foodId: doc.id),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(data['imageUrl'] ?? ''),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) =>
                                  Icon(Icons.error),
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
                              padding: EdgeInsets.all(16.0),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${data['price'] ?? 0} VND',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(top: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      "Nổi bật",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () => _onCategorySelected(category),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Food List
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _foods.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy món ăn nào',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _foods.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = _foods[index];
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ItemDetailsScreen(foodId: doc.id),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      data['imageUrl'] ?? '',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
                                                  child: Icon(Icons.error,
                                                      color: Colors.grey)),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          '${data['price'] ?? 0} VND',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.star,
                                                size: 16, color: Colors.amber),
                                            SizedBox(width: 4),
                                            Text(
                                              '${(data['rating']?.toDouble() ?? 0.0).toStringAsFixed(1)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
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
    // Use temporary variables to hold filter selection in the modal
    String? tempSelectedPrice = _selectedPriceFilter;
    int? tempSelectedRating = _selectedRatingFilter;
    return StatefulBuilder(
      builder: (context, setModalState) {
        Widget buildFilterChip(String label, {Icon? icon, bool isPrice = false, bool isRating = false}) {
          bool selected = false;
          if (isPrice) selected = tempSelectedPrice == label;
          if (isRating) selected = tempSelectedRating?.toString() == label.replaceAll('+', '');

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  SizedBox(width: 4),
                ],
                Text(label),
              ],
            ),
            selected: selected,
            onSelected: (bool value) {
              setModalState(() {
                if (isPrice) {
                  tempSelectedPrice = value ? label : null;
                }
                if (isRating) {
                  tempSelectedRating = value ? int.parse(label.replaceAll('+', '')) : null;
                }
              });
            },
            backgroundColor: Colors.white,
            selectedColor: AppTheme.primaryColor.withOpacity(0.4),
            labelStyle: TextStyle(
              color: selected ? AppTheme.primaryColor : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: selected ? AppTheme.primaryColor : Colors.grey.shade300, width: selected ? 2 : 1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            showCheckmark: false,
          );
        }
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lọc theo tiêu chí",
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "Giá:",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  buildFilterChip("Dưới 50.000đ", isPrice: true),
                  buildFilterChip("50.000đ - 100.000đ", isPrice: true),
                  buildFilterChip("100.000đ - 200.000đ", isPrice: true),
                  buildFilterChip("Trên 200.000đ", isPrice: true),
                ],
              ),
              SizedBox(height: 16),
              Text(
                "Đánh giá:",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 3; i <= 5; i++)
                    buildFilterChip(
                      "$i+",
                      icon: Icon(Icons.star, size: 16, color: Colors.amber),
                      isRating: true,
                    ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPriceFilter = null;
                          _selectedRatingFilter = null;
                        });
                        Navigator.pop(context);
                        _loadFoods();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Đặt lại",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedPriceFilter = tempSelectedPrice;
                          _selectedRatingFilter = tempSelectedRating;
                        });
                        Navigator.pop(context);
                        _loadFoods();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: Text(
                        "Áp dụng",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
