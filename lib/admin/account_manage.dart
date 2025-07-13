import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountManageScreen extends StatefulWidget {
  const AccountManageScreen({super.key});

  @override
  State<AccountManageScreen> createState() => _AccountManageScreenState();
}

class _AccountManageScreenState extends State<AccountManageScreen> {
  Stream<QuerySnapshot> _getUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách người dùng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Không có người dùng nào."),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserItem(user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    String? email = data.containsKey('email') ? data['email'] as String? : null;
    final currentUser = FirebaseAuth.instance.currentUser;
    if ((email == null || email.isEmpty) && currentUser != null && currentUser.uid == user.id) {
      email = currentUser.email;
    }
    String? fullName = data.containsKey('fullName') ? data['fullName'] as String? : null;
    return GestureDetector(
      onTap: () {
        _showUserDetails(user);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName ?? 'Chưa có họ tên',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Email: "+ (email ?? 'Không có email'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    String? email = data.containsKey('email') ? data['email'] as String? : null;
    final currentUser = FirebaseAuth.instance.currentUser;
    if ((email == null || email.isEmpty) && currentUser != null && currentUser.uid == user.id) {
      email = currentUser.email;
    }
    String? fullName = data.containsKey('fullName') ? data['fullName'] as String? : null;
    String? phone = data.containsKey('phone') ? data['phone'] as String? : null;
    String? address = data.containsKey('address') ? data['address'] as String? : null;
    String? status = data.containsKey('status') ? data['status'] as String? : null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(fullName ?? 'Chi tiết người dùng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Email: "+ (email ?? 'Không có email')),
              const SizedBox(height: 8),
              Text("Số điện thoại: "+ (phone ?? 'Không có số điện thoại')),
              const SizedBox(height: 8),
              Text("Địa chỉ: "+ (address ?? 'Không có địa chỉ')),
              const SizedBox(height: 8),
              Text("Trạng thái: "+ (status ?? 'Không rõ')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
