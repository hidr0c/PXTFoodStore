import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = _auth.currentUser;
      setState(() {
        _user = currentUser;
      });

      if (currentUser != null) {
        // Check if user is admin from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        bool isAdmin = prefs.getBool('isAdmin') ?? false;

        // Get user data from Firestore        // No need to fetch user data if we're not using it
        if (mounted) {
          setState(() {
            _isAdmin = isAdmin;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.signOut();

      // Clear admin flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', false);

      if (mounted) {
        // Navigate to login screen and clear the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleAdminMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newAdminStatus = !_isAdmin;

      await prefs.setBool('isAdmin', newAdminStatus);

      if (mounted) {
        setState(() {
          _isAdmin = newAdminStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAdminStatus
                  ? 'Đã chuyển sang chế độ quản trị viên'
                  : 'Đã chuyển sang chế độ người dùng',
            ),
            backgroundColor: newAdminStatus ? AppTheme.secondaryColor : null,
          ),
        );

        // Reload the main navigator to reflect admin changes
        // This would normally be handled by a state management solution
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    // Navigate to edit profile screen
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng sửa thông tin đang được phát triển'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Tài khoản'),
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildNotLoggedIn()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildProfileActions(),
                      const SizedBox(height: 24),
                      _buildAdminSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/login_required.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa đăng nhập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đăng nhập để sử dụng đầy đủ tính năng',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                _user?.displayName?.isNotEmpty == true
                    ? _user!.displayName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user?.displayName ?? 'Người dùng',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user?.email ?? '',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Sửa thông tin'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActions() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildProfileActionItem(
            icon: Icons.receipt_long,
            title: 'Lịch sử đơn hàng',
            subtitle: 'Xem các đơn hàng đã đặt',
            onTap: () {
              // Navigator.pushNamed(context, '/orders');
            },
          ),
          const Divider(height: 1),
          _buildProfileActionItem(
            icon: Icons.location_on,
            title: 'Địa chỉ giao hàng',
            subtitle: 'Quản lý địa chỉ giao hàng của bạn',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildProfileActionItem(
            icon: Icons.payment,
            title: 'Phương thức thanh toán',
            subtitle: 'Quản lý phương thức thanh toán',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildProfileActionItem(
            icon: Icons.favorite,
            title: 'Món ăn yêu thích',
            subtitle: 'Xem các món ăn yêu thích của bạn',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildProfileActionItem(
            icon: Icons.settings,
            title: 'Cài đặt',
            subtitle: 'Thông báo, bảo mật và các cài đặt khác',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildProfileActionItem(
            icon: Icons.help,
            title: 'Trợ giúp',
            subtitle: 'Câu hỏi thường gặp và hỗ trợ',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAdminSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      color: _isAdmin
          ? AppTheme.secondaryColor.withValues(alpha: 26)
          : null, // 0.1 * 255 ≈ 26
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: _isAdmin ? AppTheme.secondaryColor : AppTheme.primaryColor,
            ),
            title: Text(
              _isAdmin ? 'Chế độ quản trị viên' : 'Chế độ người dùng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isAdmin ? AppTheme.secondaryColor : null,
              ),
            ),
            subtitle: Text(
              _isAdmin
                  ? 'Đang sử dụng tính năng quản trị viên'
                  : 'Chuyển sang chế độ quản trị viên',
            ),
            trailing: Switch(
              value: _isAdmin,
              activeColor: AppTheme.secondaryColor,
              onChanged: (value) => _toggleAdminMode(),
            ),
            onTap: _toggleAdminMode,
          ),
          if (_isAdmin) ...[
            const Divider(height: 1),
            _buildProfileActionItem(
              icon: Icons.dashboard,
              title: 'Quản lý sản phẩm',
              subtitle: 'Thêm, sửa, xóa sản phẩm',
              onTap: () {},
            ),
            const Divider(height: 1),
            _buildProfileActionItem(
              icon: Icons.receipt,
              title: 'Quản lý đơn hàng',
              subtitle: 'Xem và cập nhật trạng thái đơn hàng',
              onTap: () {},
            ),
            const Divider(height: 1),
            _buildProfileActionItem(
              icon: Icons.people,
              title: 'Quản lý người dùng',
              subtitle: 'Xem và quản lý tài khoản người dùng',
              onTap: () {},
            ),
            const Divider(height: 1),
            _buildProfileActionItem(
              icon: Icons.bar_chart,
              title: 'Thống kê',
              subtitle: 'Xem báo cáo và thống kê',
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}
