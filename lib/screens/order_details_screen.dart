import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:foodie/screens/order_success_screen.dart';
import 'package:foodie/firestore_helper.dart';
import 'package:foodie/constant/theme_constants.dart';
import 'cart_provider.dart';
import 'package:foodie/utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsScreen extends StatefulWidget {
  final List<CartItem> orderItems;
  final double? totalPrice;

  const OrderDetailsScreen({
    Key? key,
    required this.orderItems,
    this.totalPrice,
  }) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isLoading = false;

  final String _clientId = "AaAVVFksDIhN2uzEZq7t7x3HDxvApsBGH17NT3WnEVTLxoIpx8ci5JjRoYXhBTkNSF7g2IQvBTE0Dwre";
  final String _secretKey = "EFcmdZ21pOId8N0KMVg2FG8dP_3edTUeZQz_TgSL5aPsGK-Ez8lKZQ7OqYaZifzT56v5s_2B3P3X4FI7";
  final String _paypalUrl = "https://api.sandbox.paypal.com";

  @override
  void dispose() {
    _noteController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  double get totalPrice {
    return widget.totalPrice ?? widget.orderItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'Chi tiết đơn hàng',
                    style: ThemeConstants.headingLarge.copyWith(
                      color: Colors.white,
                      fontSize: 24, // Reduced from 32 to 24
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(ThemeConstants.spacingMD),
                  children: [
                    Text(
                      'Món hàng của bạn',
                      style: ThemeConstants.headingMedium,
                    ),
                    SizedBox(height: ThemeConstants.spacingSM),
                    ListView.builder(
                      itemCount: widget.orderItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = widget.orderItems[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: ThemeConstants.spacingSM),
                          decoration: BoxDecoration(
                            color: ThemeConstants.surfaceColor,
                            borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
                            boxShadow: ThemeConstants.shadowSm,
                          ),
                          child: ListTile(
                            title: Text(
                              cartItem.name,
                              style: ThemeConstants.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Số lượng: ${cartItem.quantity}',
                              style: ThemeConstants.bodyMedium,
                            ),
                            trailing: Text(
                              '${(cartItem.price * cartItem.quantity).toStringAsFixed(0)} VNĐ',
                              style: ThemeConstants.bodyLarge.copyWith(
                                color: ThemeConstants.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                    ),
                    SizedBox(height: ThemeConstants.spacingMD),
                    Container(
                      padding: EdgeInsets.all(ThemeConstants.spacingMD),
                      decoration: BoxDecoration(
                        color: ThemeConstants.surfaceColor,
                        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
                        boxShadow: ThemeConstants.shadowSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng cộng',
                            style: ThemeConstants.bodyLarge.copyWith(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                          Text(
                            '${totalPrice.toStringAsFixed(0)} VNĐ',
                            style: ThemeConstants.headingMedium.copyWith(
                              color: ThemeConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ThemeConstants.spacingLG),
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Nhập ghi chú cho đơn hàng (tối đa 165 ký tự)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
                        ),
                        filled: true,
                        fillColor: ThemeConstants.surfaceColor,
                      ),
                      maxLength: 165,
                      maxLines: 3,
                    ),
                    SizedBox(height: ThemeConstants.spacingMD),
                    TextFormField(
                      controller: _cardNumberController,
                      decoration: InputDecoration(
                        labelText: 'Số thẻ Visa',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
                        ),
                        filled: true,
                        fillColor: ThemeConstants.surfaceColor,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số thẻ';
                        }
                        if (value.length != 16) {
                          return 'Số thẻ phải có 16 chữ số';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: ThemeConstants.spacingMD),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _expiryDateController,
                            decoration: InputDecoration(
                              labelText: 'Ngày hết hạn',
                              hintText: 'MM/YYYY',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
                              ),
                              filled: true,
                              fillColor: ThemeConstants.surfaceColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập ngày hết hạn';
                              }
                              final isValidFormat = RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{4}$').hasMatch(value);
                              if (!isValidFormat) {
                                return 'Định dạng không hợp lệ';
                              }
                              if (!isExpiryDateValid(value)) {
                                return 'Thẻ đã hết hạn';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: ThemeConstants.spacingMD),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMD),
                              ),
                              filled: true,
                              fillColor: ThemeConstants.surfaceColor,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nhập CVV';
                              }
                              if (value.length != 3) {
                                return 'CVV không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ThemeConstants.spacingXL),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleCardPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: ThemeConstants.spacingMD,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Thanh toán qua thẻ Visa',
                            style: ThemeConstants.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ThemeConstants.spacingMD),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _payWithPayPal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: ThemeConstants.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: ThemeConstants.spacingMD,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
                              side: BorderSide(
                                color: ThemeConstants.primaryColor,
                                width: 2,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Thanh toán qua PayPal',
                            style: ThemeConstants.bodyLarge.copyWith(
                              color: ThemeConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: ThemeConstants.spacingMD),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isExpiryDateValid(String expiryDate) {
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;

    // Lấy năm và tháng hiện tại
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Kiểm tra xem ngày hết hạn có hợp lệ không
    return (year > currentYear) || (year == currentYear && month >= currentMonth);
  }

  Future<void> _handleCardPayment() async {
    if (!_formKey.currentState!.validate()) {
      return; // Dừng nếu có lỗi
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API thanh toán qua thẻ Visa ở đây
      await _processOrder(); // Xử lý đơn hàng nếu thanh toán thành công
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _payWithPayPal() async {
    final note = _noteController.text.length > 165 ? _noteController.text.substring(0, 165) : _noteController.text;
    final sanitizedNote = note.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '').trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getAccessToken();

      final paymentResponse = await _createPayPalPayment(token, sanitizedNote);

      if (paymentResponse != null && paymentResponse['state'] == 'created') {
        // Assume payment is successful
        await _processOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Thanh toán qua PayPal thất bại")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra khi thanh toán qua PayPal: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAccessToken() async {
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$_clientId:$_secretKey'))}';

    final response = await http.post(
      Uri.parse('$_paypalUrl/v1/oauth2/token'),
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['access_token'];
    } else {
      throw Exception('Không thể lấy token truy cập');
    }
  }

  Future<Map<String, dynamic>?> _createPayPalPayment(String accessToken, String note) async {
    final response = await http.post(
      Uri.parse('$_paypalUrl/v1/payments/payment'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'intent': 'sale',
        'payer': {'payment_method': 'paypal'},
        'transactions': [
          {
            'amount': {
              'total': totalPrice.toStringAsFixed(2),
              'currency': 'USD',
            },
            'description': note,
          },
        ],
        'redirect_urls': {
          'return_url': 'http://return.url',
          'cancel_url': 'http://cancel.url',
        },
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không thể tạo thanh toán PayPal');
    }
  }

  Future<void> _processOrder() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final note = _noteController.text.isNotEmpty ? _noteController.text : null;

    await FirestoreHelper().saveOrderAndReduceStock(userId, widget.orderItems, totalPrice, note);

    // Thực hiện thêm logic để cập nhật giỏ hàng và điều hướng đến OrderSuccessScreen
    context.read<CartProvider>().clearCart();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderSuccessScreen(),
      ),
    );
  }

}
