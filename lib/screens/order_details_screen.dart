import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodie/screens/order_success_screen.dart';
import 'package:foodie/firestore_helper.dart';
import 'cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:foodie/widgets/rating_review_dialog.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final List<CartItem>? orderItems;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.orderItems,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currencyFormat = NumberFormat("#,##0 VND", "vi_VN");
  final Color primaryColor = Colors.orange[700] ?? const Color(0xFFE65100);
  final Color secondaryColor = Colors.green[600] ?? const Color(0xFF43A047);
  final Color scaffoldBgColor = Colors.grey[100] ?? const Color(0xFFF5F5F5);
  Map<String, dynamic>? _orderData;
  List<CartItem> _orderItems = [];
  bool _canCancel = false;
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get totalPrice {
    return widget.orderItems != null
        ? widget.orderItems!
            .fold(0, (total, item) => total + item.price * item.quantity)
        : 0;
  }

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.orderItems != null && widget.orderItems!.isNotEmpty) {
        _orderItems = widget.orderItems!;
      }

      final orderDoc =
          await _firestore.collection('orders').doc(widget.orderId).get();

      if (orderDoc.exists) {
        final data = orderDoc.data() as Map<String, dynamic>;

        // If orderItems is empty, try to load from Firestore
        if (_orderItems.isEmpty && data['items'] != null) {
          final items = data['items'] as List<dynamic>;
          _orderItems = items.map((item) {
            final itemData = item as Map<String, dynamic>;
            return CartItem(
              productId: itemData['productId'],
              name: itemData['name'],
              price: (itemData['price'] as num).toDouble(),
              quantity: itemData['quantity'],
              spiceLevel: (itemData['spiceLevel'] as num?)?.toDouble() ?? 0.0,
              imageUrl: itemData['imageUrl'],
            );
          }).toList();
        }

        // Check if order can be cancelled
        final orderStatus = data['status'] as String?;
        _canCancel = orderStatus == 'pending';

        setState(() {
          _orderData = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Không tìm thấy thông tin đơn hàng');
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_orderData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, hủy đơn'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('orders').doc(widget.orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _orderData = {
          ..._orderData!,
          'status': 'cancelled',
        };
        _canCancel = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn hàng đã được hủy')),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  void _showRatingDialog(String foodId, String foodName, String? imageUrl) {
    showDialog(
      context: context,
      builder: (context) => RatingReviewDialog(
        foodId: foodId,
        foodName: foodName,
        imageUrl: imageUrl,
      ),
    );
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
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _orderData == null
              ? const Center(child: Text('Không tìm thấy thông tin đơn hàng'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order status card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Trạng thái đơn hàng',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              _orderData!['status'] ??
                                                  'pending')
                                          .withValues(
                                              alpha: 51), // 0.2 * 255 = 51
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusString(
                                          _orderData!['status'] ?? 'pending'),
                                      style: TextStyle(
                                        color: _getStatusColor(
                                            _orderData!['status'] ?? 'pending'),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildStatusTimeline(),
                              if (_canCancel)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _cancelOrder,
                                      style: OutlinedButton.styleFrom(
                                        side:
                                            const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Hủy đơn hàng',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order info
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin đơn hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Mã đơn hàng:',
                                '#${widget.orderId.substring(0, 8).toUpperCase()}',
                              ),
                              _buildInfoRow(
                                'Ngày đặt:',
                                _orderData!['orderDate'] != null
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(
                                        (_orderData!['orderDate'] as Timestamp)
                                            .toDate())
                                    : 'N/A',
                              ),
                              _buildInfoRow(
                                'Phương thức thanh toán:',
                                _orderData!['paymentMethod'] ?? 'Tiền mặt',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer info
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin khách hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Tên:',
                                _orderData!['customerName'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                'Số điện thoại:',
                                _orderData!['phone'] ?? 'N/A',
                              ),
                              _buildInfoRow(
                                'Địa chỉ:',
                                _orderData!['address'] ?? 'N/A',
                              ),
                              if (_orderData!['note'] != null &&
                                  _orderData!['note'].toString().isNotEmpty)
                                _buildInfoRow(
                                  'Ghi chú:',
                                  _orderData!['note'],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order items
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sản phẩm đã đặt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_orderItems.length, (index) {
                                final item = _orderItems[index];
                                final canRate =
                                    _orderData!['status'] == 'delivered';

                                return Column(
                                  children: [
                                    if (index > 0) const Divider(height: 24),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: item.imageUrl != null
                                              ? Image.network(
                                                  item.imageUrl!,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                          Icons.image,
                                                          color: Colors.grey),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image,
                                                      color: Colors.grey),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${currencyFormat.format(item.price)} x ${item.quantity}'),
                                              const SizedBox(height: 8),
                                              if (canRate)
                                                SizedBox(
                                                  height: 30,
                                                  child: TextButton.icon(
                                                    onPressed: () =>
                                                        _showRatingDialog(
                                                      item.productId,
                                                      item.name,
                                                      item.imageUrl,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.star,
                                                      size: 16,
                                                    ),
                                                    label:
                                                        const Text('Đánh giá'),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          currencyFormat.format(
                                              item.price * item.quantity),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                              const Divider(height: 24),
                              _buildInfoRow(
                                'Tổng tiền hàng:',
                                currencyFormat
                                    .format(_orderData!['subtotal'] ?? 0),
                                valueStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildInfoRow(
                                'Phí vận chuyển:',
                                currencyFormat
                                    .format(_orderData!['shippingFee'] ?? 0),
                              ),
                              if (_orderData!['discount'] != null)
                                _buildInfoRow(
                                  'Giảm giá:',
                                  '- ${currencyFormat.format(_orderData!['discount'])}',
                                  valueStyle: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const Divider(),
                              _buildInfoRow(
                                'Tổng thanh toán:',
                                currencyFormat
                                    .format(_orderData!['totalAmount'] ?? 0),
                                valueStyle: TextStyle(
                                  color: primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Add "Process Order" button for new orders
                      if (widget.orderItems != null &&
                          widget.orderItems!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : _processOrder,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Xác nhận và thanh toán',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final status = _orderData!['status'] ?? 'pending';

    return Column(
      children: [
        _buildStatusTimelineItem(
          title: 'Đặt hàng thành công',
          date: _orderData!['orderDate'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format((_orderData!['orderDate'] as Timestamp).toDate())
              : null,
          isCompleted: true,
          isFirst: true,
        ),
        _buildStatusTimelineItem(
          title: 'Đang xử lý',
          date: _orderData!['processingDate'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format((_orderData!['processingDate'] as Timestamp).toDate())
              : null,
          isCompleted: status == 'processing' ||
              status == 'shipping' ||
              status == 'delivered',
        ),
        _buildStatusTimelineItem(
          title: 'Đang giao hàng',
          date: _orderData!['shippingDate'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format((_orderData!['shippingDate'] as Timestamp).toDate())
              : null,
          isCompleted: status == 'shipping' || status == 'delivered',
        ),
        _buildStatusTimelineItem(
          title: 'Giao hàng thành công',
          date: _orderData!['deliveredDate'] != null
              ? DateFormat('dd/MM/yyyy HH:mm')
                  .format((_orderData!['deliveredDate'] as Timestamp).toDate())
              : null,
          isCompleted: status == 'delivered',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildStatusTimelineItem({
    required String title,
    String? date,
    bool isCompleted = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? primaryColor : Colors.grey[300],
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? primaryColor : Colors.grey[300],
                    border: Border.all(
                      color: isCompleted ? primaryColor : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  if (date != null)
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Process the order method
  Future<void> _processOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final note =
          _noteController.text.isNotEmpty ? _noteController.text : null;

      await FirestoreHelper().saveOrderAndReduceStock(
          userId, widget.orderItems ?? [], totalPrice, note);

      // Update cart and navigate to success screen
      if (!mounted) return; // Ensure context is valid before using it
      context.read<CartProvider>().clearCart();

      if (!mounted) return; // Ensure context is valid before using it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OrderSuccessScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra khi xử lý đơn hàng: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
