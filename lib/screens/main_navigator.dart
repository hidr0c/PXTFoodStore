// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/cart_provider.dart';
import 'package:foodie/screens/cart_screen.dart';
import 'package:foodie/screens/order_history_screen.dart';
import 'package:foodie/screens/profile_screen.dart';
import 'package:foodie/admin/admin_screen.dart';
import 'package:foodie/screens/home_screen.dart';

class MainNavigator extends StatefulWidget {
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
        setState(() {
          // Update UI when tab changes
        });
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
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          widget.isAdmin
              ? const AdminScreen()
              : const HomeScreen(), // Use proper screen based on admin status
          const OrderHistoryScreen(),
          const CartScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26), // 0.1 * 255 ≈ 26
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3,
                color: AppTheme.primaryColor,
              ),
              insets: const EdgeInsets.symmetric(horizontal: 20),
            ),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey[600],
            tabs: [
              _buildTabItem(
                icon: Icons.home,
                label: widget.isAdmin ? 'Admin' : 'Trang chủ',
              ),
              _buildTabItem(
                icon: Icons.receipt_long,
                label: 'Đơn hàng',
              ),
              _buildTabItem(
                icon: Icons.shopping_cart,
                label: 'Giỏ hàng',
                badge: context.watch<CartProvider>().itemCount,
              ),
              _buildTabItem(
                icon: Icons.person,
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
      height: 64,
      iconMargin: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon),
              if (badge > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
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
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
