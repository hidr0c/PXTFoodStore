// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:foodie/admin/food_manage.dart';
import 'package:foodie/admin/orders_manage.dart';
import 'package:foodie/admin/account_manage.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  int _totalOrders = 0;
  int _totalUsers = 0;
  int _totalProducts = 0;
  double _totalRevenue = 0.0;
  bool _isLoading = true;
  final currencyFormat = NumberFormat("#,##0 VND", "vi_VN");
  int _currentIndex = 0;
  late TabController _tabController;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.restaurant_menu, 'label': 'Món ăn'},
    {'icon': Icons.receipt_long, 'label': 'Đơn hàng'},
    {'icon': Icons.people, 'label': 'Tài khoản'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _navItems.length, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy tổng số đơn hàng
      var ordersSnapshot =
          await FirebaseFirestore.instance.collection('orders').get();
      var totalOrders = ordersSnapshot.docs.length;

      // Lấy tổng số người dùng
      var usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      var totalUsers = usersSnapshot.docs.length;

      // Lấy tổng số sản phẩm
      var productsSnapshot =
          await FirebaseFirestore.instance.collection('foods').get();
      var totalProducts = productsSnapshot.docs.length;

      // Tính tổng doanh thu
      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        var data = doc.data();
        if (data['status'] == 'delivered' && data['totalAmount'] != null) {
          totalRevenue += (data['totalAmount'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _totalOrders = totalOrders;
          _totalUsers = totalUsers;
          _totalProducts = totalProducts;
          _totalRevenue = totalRevenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thống kê: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Admin Dashboard'
              : _navItems[_currentIndex]['label'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          // Nút chuyển sang giao diện người dùng
          IconButton(
            icon: Icon(Icons.storefront, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen(isAdmin: true)),
              );
            },
            tooltip: 'Chuyển sang giao diện người dùng',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(), // Prevent swiping between tabs
        children: [
          // Dashboard Tab
          _isLoading
              ? Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor))
              : _buildDashboardTab(),

          // Món ăn Tab
          FoodManageScreen(),

          // Đơn hàng Tab
          OrdersManageScreen(),

          // Tài khoản Tab
          AccountManageScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.15), width: 1.0),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppTheme.primaryColor,
                width: 3.0,
              ),
            ),
          ),
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: _navItems.map((item) {
            return Tab(
              icon: Icon(item['icon']),
              text: item['label'],
              iconMargin: EdgeInsets.only(bottom: 4),
            );
          }).toList(),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Xin chào, Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Tổng quan hoạt động kinh doanh',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                  onPressed: _loadStatistics,
                  tooltip: 'Làm mới dữ liệu',
                ),
              ],
            ),

            SizedBox(height: 24),

            // Animated statistics cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.shopping_cart,
                  title: 'Đơn hàng',
                  value: _totalOrders.toString(),
                  color: Color(0xFF4CAF50),
                ),
                _buildStatCard(
                  icon: Icons.people,
                  title: 'Người dùng',
                  value: _totalUsers.toString(),
                  color: Color(0xFF2196F3),
                ),
                _buildStatCard(
                  icon: Icons.fastfood,
                  title: 'Món ăn',
                  value: _totalProducts.toString(),
                  color: Color(0xFFFF9800),
                ),
                _buildStatCard(
                  icon: Icons.attach_money,
                  title: 'Doanh thu',
                  value: currencyFormat.format(_totalRevenue),
                  color: Color(0xFFE91E63),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Section title with animation
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF9C27B0)],
                ).createShader(bounds);
              },
              child: Text(
                'Đơn hàng mới nhất',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 16),

            // Đơn hàng mới nhất
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('orderDate', descending: true)
                  .limit(5)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi khi tải đơn hàng'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('Không có đơn hàng nào'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: Colors.black.withOpacity(0.15), width: 1),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(8),
                        title: Text(
                          '${data['customerName'] ?? 'Không có tên'}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text('${data['phone'] ?? 'Không có SĐT'}'),
                            Text(data['orderDate'] != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(
                                    (data['orderDate'] as Timestamp).toDate())
                                : 'Không có ngày'),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                    data['status'] ?? 'pending'),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusString(data['status'] ?? 'pending'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${currencyFormat.format(data['totalAmount'] ?? 0)} VND',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        onTap: () {
                          // Chi tiết đơn hàng
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Color(0xFFFF9800); // Orange
      case 'processing':
        return Color(0xFF2196F3); // Blue
      case 'shipping':
        return Color(0xFF9C27B0); // Purple
      case 'delivered':
        return Color(0xFF4CAF50); // Green
      case 'cancelled':
        return Color(0xFFE53935); // Red
      default:
        return AppTheme.textLightColor;
    }
  }

  String _getStatusString(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }
}
