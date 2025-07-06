import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/widgets/rating_bar.dart';

class RatingReviewDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final String? imageUrl;
  final Function? onReviewAdded;
  final bool isAdmin;

  const RatingReviewDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.imageUrl,
    this.onReviewAdded,
    this.isAdmin = false,
  });

  @override
  State<RatingReviewDialog> createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  double _rating = 3.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null && !widget.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để đánh giá')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Reference to user document
      DocumentSnapshot? userDoc;
      String userName = 'Admin';
      String userAvatar = '';

      if (!widget.isAdmin && user != null) {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['fullName'] ?? 'Người dùng';
          userAvatar = userData['avatarUrl'] ?? '';
        }
      }

      // Add review to Firestore
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .add({
        'userId': widget.isAdmin ? 'admin' : user?.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAdmin': widget.isAdmin,
      });

      // Update average rating in food document
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviewsSnapshot.docs) {
          totalRating += doc['rating'] as double;
        }

        final averageRating = totalRating / reviewsSnapshot.docs.length;

        await FirebaseFirestore.instance
            .collection('foods')
            .doc(widget.productId)
            .update({
          'rating': averageRating,
          'totalRatings': reviewsSnapshot.docs.length,
        });
      }

      // Call callback if provided
      widget.onReviewAdded?.call();

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá của bạn đã được ghi nhận')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hiển thị badge cho admin nếu là admin
                if (widget.isAdmin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  widget.isAdmin
                      ? 'Đánh giá với tư cách Admin'
                      : 'Đánh giá món ăn',
                  style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.productName,
                  style:
                      AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                RatingBar(
                  rating: _rating,
                  size: 40,
                  allowRating: true,
                  onRatingChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                  alignment: MainAxisAlignment.center,
                  showText: false,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ ý kiến của bạn về món ăn này...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(Icons.rate_review,
                          color: AppTheme.primaryColor.withValues(alpha: 150)),
                    ),
                    maxLines: 4,
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập đánh giá';
                      }
                      if (value.trim().length < 5) {
                        return 'Đánh giá phải có ít nhất 5 ký tự';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Đang gửi...'),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text(
                                  'Gửi đánh giá',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
