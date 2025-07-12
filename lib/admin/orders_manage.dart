import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie/constant/app_color.dart';
import 'package:foodie/admin/order_detail_screen.dart';

class OrdersManageScreen extends StatefulWidget {
  const OrdersManageScreen({super.key});

  @override
  State<OrdersManageScreen> createState() => _OrdersManageScreenState();
}

class _OrdersManageScreenState extends State<OrdersManageScreen> {
  Color _getBackgroundColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.yellow.shade100;
      case 'Confirmed':
        return Colors.green.shade100;
      case 'Delivered':
        return Colors.blue.shade100;
      case 'Cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Đang duyệt';
      case 'Confirmed':
        return 'Đã duyệt';
      case 'Delivered':
        return 'Đã giao';
      case 'Cancelled':
        return 'Hủy đơn';
      default:
        return 'Không xác định';
    }
  }

  Future<void> _updateOrderStatus(
      String orderId, String newStatus, List<dynamic> items) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (newStatus == 'Cancelled') {
        for (var item in items) {
          final productId = item['productId'];
          final quantityToReturn = item['quantity'];

          final foodRef =
              FirebaseFirestore.instance.collection('foods').doc(productId);
          await foodRef.update({
            'quantity': FieldValue.increment(quantityToReturn),
          });
        }
      }

      if (!mounted) return; // Ensure context is valid before using it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đơn hàng đã được cập nhật thành $newStatus')),
      );
    } catch (e) {
      if (!mounted) return; // Ensure context is valid before using it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi cập nhật đơn hàng')),
      );
    }
  }

  Future<String> _getCustomerName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data()!['fullName'] ?? 'Unknown';
    } else {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        backgroundColor: AppColor.primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Không có đơn hàng nào.'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;

              final items = orderData['items'] as List<dynamic>? ?? [];
              final timestamp =
                  (orderData['orderDate'] as Timestamp?)?.toDate();
              final totalPrice = orderData['totalAmount'] as num? ?? 0;
              final status = orderData['status'] as String? ?? "Không xác định";
              final statusText = _getStatusText(status);
              final backgroundColor = _getBackgroundColor(status);
              final userId = orderData['userId'] as String? ?? '';

              return FutureBuilder<String>(
                future: _getCustomerName(userId),
                builder: (context, snapshot) {
                  final customerName = snapshot.data ?? 'Unknown';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminOrderDetailScreen(
                            orderId: order.id,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.black.withOpacity(0.1), width: 1),
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mã đơn hàng: ${order.id}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        'Khách hàng: $customerName',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Ngày đặt hàng: ${timestamp?.day}/${timestamp?.month}/${timestamp?.year}',
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Tổng tiền: đ$totalPrice',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (status == 'Pending') ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(
                                              order.id, 'Confirmed', items),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                          child: const Text(
                                            'Duyệt đơn',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(
                                              order.id, 'Cancelled', items),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                          child: const Text(
                                            'Hủy đơn',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ] else if (status == 'Confirmed') ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(
                                              order.id, 'Delivered', items),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                          ),
                                          child: const Text(
                                            'Giao hàng',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const Divider(
                              color: Colors.black26,
                              height: 20,
                              thickness: 1,
                            ),
                            const Text(
                              'Chi tiết sản phẩm:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ...items.map((item) {
                              final itemData =
                                  item as Map<String, dynamic>? ?? {};
                              final spiceLevel = itemData['spiceLevel'] ?? 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            itemData['productName'] ??
                                                'Không xác định',
                                            style: const TextStyle(
                                                color: Colors.black87),
                                          ),
                                          if (spiceLevel > 0) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'Cay: $spiceLevel',
                                              style: const TextStyle(
                                                  color: Colors.red,
                                                  fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'SL: ${itemData['quantity'] ?? 0}',
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'đ${itemData['price'] ?? 0}',
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
