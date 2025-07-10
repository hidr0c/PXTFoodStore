// ignore_for_file: prefer_const_literals_to_create_immutables, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/screens/auth/login_screen.dart';
import 'package:foodie/screens/order_details_screen.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final currencyFormat = NumberFormat("#,##0 VND", "vi_VN");
  String? _selectedStatus;
  final List<String> _statusFilters = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang xử lý',
    'Đang giao hàng',
    'Đã giao hàng',
    'Đã hủy',
  ];

  Stream<QuerySnapshot> _getOrdersStream(String? status) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      // Return empty stream if not logged in
      return const Stream<QuerySnapshot>.empty();
    }

    Query query = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true);

    // Apply status filter if selected
    if (status != null && status != 'Tất cả') {
      String firestoreStatus;
      switch (status) {
        case 'Chờ xác nhận':
          firestoreStatus = 'pending';
          break;
        case 'Đang xử lý':
          firestoreStatus = 'processing';
          break;
        case 'Đang giao hàng':
          firestoreStatus = 'shipping';
          break;
        case 'Đã giao hàng':
          firestoreStatus = 'delivered';
          break;
        case 'Đã hủy':
          firestoreStatus = 'cancelled';
          break;
        default:
          firestoreStatus = 'pending';
      }

      query = query.where('status', isEqualTo: firestoreStatus);
    }

    return query.snapshots();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'processing':
        return const Color(0xFF2196F3); // Blue
      case 'shipping':
        return const Color(0xFF9C27B0); // Purple
      case 'delivered':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFFE53935); // Red
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: _auth.currentUser == null
          ? _buildNotLoggedIn()
          : Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getOrdersStream(_selectedStatus),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Lỗi: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/no_orders.png',
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.receipt_long,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có đơn hàng nào',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Đơn hàng của bạn sẽ hiển thị ở đây',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final order = doc.data() as Map<String, dynamic>;
                          final String orderId = doc.id;
                          final String status =
                              order['status'] as String? ?? 'pending';
                          final Timestamp orderDate =
                              order['orderDate'] as Timestamp? ??
                                  Timestamp.fromDate(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      orderId: orderId,
                                      orderItems: [],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Đơn hàng #${orderId.substring(0, 8).toUpperCase()}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            _getStatusString(status),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(orderDate.toDate())}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Số lượng: ${(order['items'] as List<dynamic>).length} món',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Tổng: ${currencyFormat.format(order['totalAmount'] ?? 0)}',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    _buildOrderActions(status, orderId),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final isSelected = _selectedStatus == status ||
              (_selectedStatus == null && status == 'Tất cả');

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = status == 'Tất cả' ? null : status;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                status,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderActions(String status, String orderId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == 'delivered')
          TextButton.icon(
            onPressed: () {
              // Re-order functionality
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Đặt lại'),
          ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(
                  orderId: orderId,
                  orderItems: [],
                ),
              ),
            );
          },
          icon: const Icon(Icons.visibility),
          label: const Text('Chi tiết'),
        ),
      ],
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
            'Đăng nhập để xem đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn cần đăng nhập để xem lịch sử đơn hàng',
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
}
