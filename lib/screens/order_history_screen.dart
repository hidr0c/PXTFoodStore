import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_color.dart';
import 'package:foodie/utils/currency_formatter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

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

  Future<void> _cancelOrder(String orderId, List<dynamic> items) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Cancelled'});

      for (var item in items) {
        final productId = item['productId'];
        final quantityToReturn = item['quantity'];

        final foodRef =
        FirebaseFirestore.instance.collection('foods').doc(productId);
        await foodRef.update({
          'quantity': FieldValue.increment(quantityToReturn),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn hàng đã được hủy thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi hủy đơn hàng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(
        child: Text("Bạn cần đăng nhập để xem lịch sử đơn hàng."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đơn hàng'),
        backgroundColor: AppColor.primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('Bạn chưa có đơn hàng nào.'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;

              final items = orderData['items'] as List<dynamic>? ?? [];
              final timestamp =
              (orderData['timestamp'] as Timestamp?)?.toDate();
              final totalPrice = orderData['totalPrice'] as num? ?? 0;
              final status = orderData['status'] as String? ?? "Không xác định";
              final note = orderData['note'] as String? ?? "Không có ghi chú";
              final statusText = _getStatusText(status);
              final backgroundColor = _getBackgroundColor(status);

              return Card(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Mã đơn hàng: ${order.id}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (status == 'Pending') ...[
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      _cancelOrder(order.id, items),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                  ),
                                  child: Text(
                                    'Hủy đơn',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Ngày đặt hàng: ${timestamp?.day}/${timestamp?.month}/${timestamp?.year}',
                        style: TextStyle(color: Colors.black87),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tổng tiền: ${CurrencyFormatter.format(totalPrice)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Divider(
                        color: Colors.black26,
                        height: 20,
                        thickness: 1,
                      ),
                      Text(
                        'Ghi chú: $note',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Chi tiết sản phẩm:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      ...items.map((item) {
                        final itemData = item as Map<String, dynamic>? ?? {};
                        final spiceLevel = itemData['spiceLevel'] ?? 0;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      itemData['productName'] ?? 'Không xác định',
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                    if (spiceLevel > 0) ...[
                                      SizedBox(width: 8),
                                      Text(
                                        'Cay: $spiceLevel',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                'SL: ${itemData['quantity'] ?? 0}',
                                style: TextStyle(color: Colors.black87),
                              ),
                              SizedBox(width: 10),
                              Text(
                                CurrencyFormatter.format(itemData['price'] ?? 0),
                                style: TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
