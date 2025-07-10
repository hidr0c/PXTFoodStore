// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/cart_provider.dart';
import 'package:foodie/screens/cart_screen.dart';
import 'package:foodie/screens/order_history_screen.dart';
import 'package:foodie/screens/home_screen.dart';
import 'package:foodie/screens/user_profile_screen.dart';
import 'package:foodie/admin/admin_screen.dart';

class MainNavigator extends StatefulWidget {
  // Parameter for admin status
  final bool isAdmin;

  const MainNavigator({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          widget.isAdmin ? AdminScreen() : HomeScreen(),
          OrderHistoryScreen(),
          CartScreen(),
          UserProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 4,
                color: AppTheme.primaryColor,
              ),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            tabs: [
              _buildTabItem(
                icon: Icons.home_outlined,
                label: widget.isAdmin ? 'Admin' : 'Trang chủ',
              ),
              _buildTabItem(
                icon: Icons.receipt_long_outlined,
                label: 'Đơn hàng',
              ),
              _buildTabItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Giỏ hàng',
                badge: context.watch<CartProvider>().itemCount,
              ),
              _buildTabItem(
                icon: Icons.person_outlined,
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    int badge = 0,
  }) {
    return Tab(
      height: 70,
      iconMargin: EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 26),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
