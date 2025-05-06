import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:foodie/screens/order_success_screen.dart';
import 'package:foodie/firestore_helper.dart';
import 'cart_provider.dart';
import 'package:foodie/utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailsScreen extends StatefulWidget {
  final List<CartItem> orderItems;
  final double? totalPrice;

  const OrderDetailsScreen({
    super.key,
    required this.orderItems,
    this.totalPrice,
  });

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController(); // Controller cho ghi chú
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isLoading = false;

  final String _clientId = "AaAVVFksDIhN2uzEZq7t7x3HDxvApsBGH17NT3WnEVTLxoIpx8ci5JjRoYXhBTkNSF7g2IQvBTE0Dwre";
  final String _secretKey = "EFcmdZ21pOId8N0KMVg2FG8dP_3edTUeZQz_TgSL5aPsGK-Ez8lKZQ7OqYaZifzT56v5s_2B3P3X4FI7";
  final String _paypalUrl = "https://api.sandbox.paypal.com"; // Use sandbox for testing

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
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Món hàng của bạn:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 10),
              Divider(),
              ListView.builder(
                itemCount: widget.orderItems.length,
                itemBuilder: (context, index) {
                  final cartItem = widget.orderItems[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(cartItem.name),
                      subtitle: Text('Số lượng: ${cartItem.quantity}'),
                      trailing: Text(CurrencyFormatter.format(cartItem.price * cartItem.quantity)),
                    ),
                  );
                },
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
              SizedBox(height: 20),
              Divider(),
              Text(
                'Tổng cộng: ${CurrencyFormatter.format(totalPrice)}', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              SizedBox(height: 20),

              // Thêm trường ghi chú
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'Ghi chú (tối đa 165 ký tự)'),
                maxLength: 165,
              ),

              // Thông tin thẻ Visa
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(labelText: 'Số thẻ Visa'),
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
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(labelText: 'Ngày hết hạn (MM/YYYY)'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập ngày hết hạn';
                  }
                  final isValidFormat = RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{4}$').hasMatch(value);
                  if (!isValidFormat) {
                    return 'Định dạng không hợp lệ, hãy nhập MM/YYYY';
                  }
                  if (!isExpiryDateValid(value)) {
                    return 'Thẻ đã hết hạn.Vui lòng nhập lại';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(labelText: 'Mã CVV'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã CVV';
                  }
                  if (value.length != 3) {
                    return 'Mã CVV phải có 3 chữ số';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCardPayment,
                  child: Text('THANH TOÁN QUA THẺ VISA'),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _payWithPayPal,
                child: Text('THANH TOÁN QUA PAYPAL'),
              ),
            ],
          ),
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
      MaterialPageRoute(builder: (context) => OrderSuccessScreen(orderedProductIds: [], orderedQuantities: [],)),
    );
  }

}
