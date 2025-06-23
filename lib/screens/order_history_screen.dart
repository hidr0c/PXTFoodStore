import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/theme_constants.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Color(0xFFFFB74D); // Orange
      case 'Confirmed':
        return Color(0xFF66BB6A); // Green
      case 'Delivered':
        return Color(0xFF42A5F5); // Blue
      case 'Cancelled':
        return Color(0xFFEF5350); // Red
      default:
        return Color(0xFF9E9E9E); // Grey
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
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending_outlined;
      case 'Confirmed':
        return Icons.check_circle_outline;
      case 'Delivered':
        return Icons.delivery_dining;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
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

      if (!mounted) return; // Ensure context is valid before using it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đơn hàng đã được hủy thành công'),
          backgroundColor: ThemeConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return; // Ensure context is valid before using it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi hủy đơn hàng'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: ThemeConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 64,
                color: ThemeConstants.textSecondaryColor,
              ),
              SizedBox(height: ThemeConstants.spacingMD),
              Text(
                'Bạn cần đăng nhập',
                style: ThemeConstants.headingMedium,
              ),
              SizedBox(height: ThemeConstants.spacingSM),
              Text(
                'Vui lòng đăng nhập để xem lịch sử đơn hàng',
                style: ThemeConstants.bodyLarge.copyWith(
                  color: ThemeConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: ThemeConstants.primaryGradient,
              ),
              padding: EdgeInsets.all(ThemeConstants.spacingLG),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: ThemeConstants.shadowSm,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: ThemeConstants.textPrimaryColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: ThemeConstants.spacingMD),
                  Expanded(
                    child: Text(
                      'Lịch sử đơn hàng',
                      style: ThemeConstants.headingMedium.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: user!.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ThemeConstants.primaryColor),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                          SizedBox(height: ThemeConstants.spacingMD),
                          Text(
                            'Chưa có đơn hàng nào',
                            style: ThemeConstants.headingMedium,
                          ),
                          SizedBox(height: ThemeConstants.spacingSM),
                          Text(
                            'Hãy đặt món ăn để xem lịch sử đơn hàng',
                            style: ThemeConstants.bodyLarge.copyWith(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.all(ThemeConstants.spacingMD),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final orderData = order.data() as Map<String, dynamic>;

                      final items = orderData['items'] as List<dynamic>? ?? [];
                      final timestamp =
                          (orderData['timestamp'] as Timestamp?)?.toDate();
                      final totalPrice = orderData['totalPrice'] as num? ?? 0;
                      final status =
                          orderData['status'] as String? ?? "Không xác định";
                      final note =
                          orderData['note'] as String? ?? "Không có ghi chú";
                      final statusText = _getStatusText(status);
                      final statusColor = _getStatusColor(status);
                      final statusIcon = _getStatusIcon(status);

                      return Container(
                        margin:
                            EdgeInsets.only(bottom: ThemeConstants.spacingMD),
                        decoration: BoxDecoration(
                          color: ThemeConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(
                              ThemeConstants.borderRadiusLG),
                          boxShadow: ThemeConstants.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(ThemeConstants.spacingMD),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: ThemeConstants.dividerColor,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Mã đơn: ${order.id}',
                                          style:
                                              ThemeConstants.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ThemeConstants.spacingSM,
                                          vertical: ThemeConstants.spacingXS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                              alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              ThemeConstants.borderRadiusMD),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              statusIcon,
                                              size: 16,
                                              color: statusColor,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: ThemeConstants.bodyMedium
                                                  .copyWith(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: ThemeConstants.spacingSM),
                                  Text(
                                    'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(timestamp ?? DateTime.now())}',
                                    style: ThemeConstants.bodyMedium.copyWith(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                  if (note.isNotEmpty &&
                                      note != "Không có ghi chú") ...[
                                    SizedBox(height: ThemeConstants.spacingSM),
                                    Text(
                                      'Ghi chú: $note',
                                      style: ThemeConstants.bodyMedium.copyWith(
                                        color:
                                            ThemeConstants.textSecondaryColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item =
                                    items[index] as Map<String, dynamic>;
                                final spiceLevel = item['spiceLevel'] ?? 0;

                                return Container(
                                  padding:
                                      EdgeInsets.all(ThemeConstants.spacingMD),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index < items.length - 1
                                            ? ThemeConstants.dividerColor
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['productName'] ??
                                                  'Không xác định',
                                              style: ThemeConstants.bodyLarge,
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '${item['quantity']}x',
                                                  style: ThemeConstants
                                                      .bodyMedium
                                                      .copyWith(
                                                    color: ThemeConstants
                                                        .textSecondaryColor,
                                                  ),
                                                ),
                                                if (spiceLevel > 0) ...[
                                                  SizedBox(
                                                      width: ThemeConstants
                                                          .spacingSM),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: ThemeConstants
                                                          .errorColor
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius: BorderRadius
                                                          .circular(ThemeConstants
                                                              .borderRadiusSM),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .local_fire_department,
                                                          size: 12,
                                                          color: ThemeConstants
                                                              .errorColor,
                                                        ),
                                                        SizedBox(width: 2),
                                                        Text(
                                                          '$spiceLevel',
                                                          style: ThemeConstants
                                                              .bodySmall
                                                              .copyWith(
                                                            color:
                                                                ThemeConstants
                                                                    .errorColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${(item['price'] * item['quantity']).toStringAsFixed(0)} VNĐ',
                                        style:
                                            ThemeConstants.bodyMedium.copyWith(
                                          color: ThemeConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              padding: EdgeInsets.all(ThemeConstants.spacingMD),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tổng cộng',
                                        style:
                                            ThemeConstants.bodyLarge.copyWith(
                                          color:
                                              ThemeConstants.textSecondaryColor,
                                        ),
                                      ),
                                      Text(
                                        '${totalPrice.toStringAsFixed(0)} VNĐ',
                                        style: ThemeConstants.headingMedium
                                            .copyWith(
                                          color: ThemeConstants.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (status == 'Pending') ...[
                                    SizedBox(height: ThemeConstants.spacingMD),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _cancelOrder(order.id, items),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ThemeConstants.errorColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: ThemeConstants.spacingMD,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                ThemeConstants.borderRadiusLG),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Hủy đơn hàng',
                                          style:
                                              ThemeConstants.bodyLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
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
}
