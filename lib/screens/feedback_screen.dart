import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodie/constant/app_color.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _selectedRating = 0.0;

  Stream<QuerySnapshot> _getFoodItems() {
    return FirebaseFirestore.instance.collection('foods').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Đánh giá món ăn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primaryColor,
                AppColor.primaryColor.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFoodItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColor.primaryColor),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Hiện chưa có món ăn nào.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          Map<String, List<DocumentSnapshot>> categorizedFoods = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String category = data['category'] ?? 'Khác';
            categorizedFoods[category] = categorizedFoods[category] ?? [];
            categorizedFoods[category]!.add(doc);
          }

          return ListView(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            children: categorizedFoods.entries.map((entry) {
              String category = entry.key;
              List<DocumentSnapshot> foods = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Replace with a suitable color
                      ),
                    ),
                  ),
                  ...foods.map((food) => _buildFeedbackItem(food)),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackItem(DocumentSnapshot food) {
    final data = food.data() as Map<String, dynamic>;
    final averageRating = data['rating']?.toDouble() ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        shadowColor: Colors.grey.shade200,
        child: ListTile(
          contentPadding: EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              data['imageUrl'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error, color: Colors.grey),
            ),
          ),
          title: Text(
            data['name'] ?? 'Không có tên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${data['price'] ?? 0} VNĐ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.feedback, color: AppColor.primaryColor),
            onPressed: () {
              _showFeedbackDialog(food.id);
            },
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(String foodId) {
    _selectedRating = 0.0;
    _feedbackController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Để lại Phản Hồi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đánh giá:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _selectedRating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Phản hồi:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        hintText: "Nhập phản hồi của bạn",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value!.isEmpty && _selectedRating == 0.0) {
                          return 'Vui lòng cung cấp phản hồi hoặc đánh giá sao';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: Text('Hủy', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _submitFeedback(
                      foodId, _feedbackController.text, _selectedRating);
                  _feedbackController.clear();
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Gửi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFeedback(
      String foodId, String feedback, double rating) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'Người dùng ẩn danh';
      final feedbackCollection = FirebaseFirestore.instance
          .collection('foods')
          .doc(foodId)
          .collection('feedback');

      await feedbackCollection.add({
        'userId': userId,
        'feedback': feedback,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update average rating in the food document
      final foodDoc =
          FirebaseFirestore.instance.collection('foods').doc(foodId);
      final feedbackSnapshot = await feedbackCollection.get();
      double avgRating = 0.0;
      if (feedbackSnapshot.docs.isNotEmpty) {
        double totalRating = feedbackSnapshot.docs.fold(0.0, (sum, doc) {
          return sum + (doc['rating']?.toDouble() ?? 0.0);
        });
        avgRating = totalRating / feedbackSnapshot.docs.length;
      }

      await foodDoc.update({'rating': avgRating});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phản hồi đã được gửi thành công')),
      );

      debugPrint('Phản hồi cho món $foodId: $feedback, Đánh giá: $rating');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: Không thể gửi phản hồi - $e')),
      );
      debugPrint('Lỗi khi gửi phản hồi: $e');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
