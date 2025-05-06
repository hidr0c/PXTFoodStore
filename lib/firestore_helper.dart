import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie/screens/cart_provider.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOrderAndReduceStock(String userId, List<CartItem> orderItems,
      double totalAmount, String? note) async {
    final orderData = {
      'userId': userId,
      'items': orderItems
          .map((item) => {
                'productId': item.productId,
                'productName': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'spiceLevel': item.spiceLevel,
              })
          .toList(),
      'totalPrice': totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
      'note': note,
    };

    final orderRef = await _firestore.collection('orders').add(orderData);

    for (var item in orderItems) {
      await _reduceProductQuantity(item.productId, item.quantity);
    }
  }

  Future<void> _reduceProductQuantity(String productId, int quantity) async {
    final productDoc = _firestore.collection('foods').doc(productId);
    final snapshot = await productDoc.get();

    if (!snapshot.exists) {
      throw Exception('Product does not exist!');
    }

    final currentQuantity = snapshot.data()?['quantity'] as int;
    if (currentQuantity < quantity) {
      throw Exception('Not enough quantity available!');
    }

    await productDoc.update({
      'quantity': FieldValue.increment(-quantity),
    });
  }
}
