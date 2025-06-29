import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/widgets/rating_bar.dart';
import 'package:intl/intl.dart';

class ReviewsSection extends StatefulWidget {
  final String productId;
  final int initialLimit;

  const ReviewsSection({
    super.key,
    required this.productId,
    this.initialLimit = 3,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  int _limit = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _limit = widget.initialLimit;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(_limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Đã xảy ra lỗi khi tải đánh giá'));
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đánh giá & Nhận xét',
                  style: AppTheme.subheadingStyle,
                ),
                TextButton(
                  onPressed: () {
                    _addReview(context);
                  },
                  child: Text(
                    'Viết đánh giá',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Lista các đánh giá
            ...reviews.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildReviewItem(data, doc.id);
            }).toList(),

            // Nút xem thêm
            if (reviews.length >= _limit) ...[
              SizedBox(height: 16),
              Center(
                child: _isLoading
                    ? CircularProgressIndicator(color: AppTheme.primaryColor)
                    : TextButton(
                        onPressed: _loadMore,
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.scaffoldBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: AppTheme.primaryColor),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: Text(
                          'Xem thêm đánh giá',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên đánh giá sản phẩm này',
              style: TextStyle(
                color: AppTheme.textLightColor,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _addReview(context);
              },
              child: Text('Viết đánh giá'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> data, String reviewId) {
    final userName = data['userName'] ?? 'Người dùng ẩn danh';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = data['comment'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Không rõ';
    final isCurrentUser =
        FirebaseAuth.instance.currentUser?.uid == data['userId'];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppTheme.textLightColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReview(context, data, reviewId);
                      } else if (value == 'delete') {
                        _deleteReview(reviewId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit,
                                size: 18, color: AppTheme.textSecondaryColor),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 12),
            RatingBar(
              rating: rating,
              size: 16,
              showText: false,
            ),
            if (comment.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                comment,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _limit += widget.initialLimit;
      _isLoading = false;
    });
  }

  void _addReview(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng đăng nhập để đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Kiểm tra xem người dùng đã có đánh giá cho sản phẩm này chưa
    FirebaseFirestore.instance
        .collection('foods')
        .doc(widget.productId)
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        // Người dùng đã có đánh giá, hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bạn đã đánh giá sản phẩm này rồi. Bạn có thể chỉnh sửa đánh giá cũ.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Hiển thị dialog đánh giá
        showDialog(
          context: context,
          builder: (context) => RatingDialog(
            productId: widget.productId,
            productName: 'sản phẩm này',
            onSubmit: (rating, comment) {
              _submitReview(rating, comment);
            },
          ),
        );
      }
    });
  }

  Future<void> _submitReview(double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Thêm đánh giá mới
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName':
            user.displayName ?? user.email?.split('@').first ?? 'Người dùng',
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật rating trung bình của sản phẩm
      await _updateAverageRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi đánh giá: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editReview(
      BuildContext context, Map<String, dynamic> reviewData, String reviewId) {
    final rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = reviewData['comment'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        double newRating = rating;
        TextEditingController commentController =
            TextEditingController(text: comment);

        return AlertDialog(
          title: Text('Chỉnh sửa đánh giá'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return RatingBar(
                      rating: newRating,
                      size: 32,
                      showText: false,
                      color: AppTheme.primaryColor,
                      alignment: MainAxisAlignment.center,
                      allowRating: true,
                      onRatingChanged: (value) {
                        setState(() {
                          newRating = value;
                        });
                      },
                    );
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhận xét của bạn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReview(reviewId, newRating, commentController.text);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateReview(
      String reviewId, double rating, String comment) async {
    try {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .doc(reviewId)
          .update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật rating trung bình của sản phẩm
      await _updateAverageRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đánh giá đã được cập nhật'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật đánh giá: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      // Hiển thị dialog xác nhận      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xóa đánh giá'),
          content: Text('Bạn có chắc chắn muốn xóa đánh giá này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Xóa đánh giá
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Cập nhật rating trung bình của sản phẩm
      await _updateAverageRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa đánh giá'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa đánh giá: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAverageRating() async {
    try {
      // Lấy tất cả đánh giá
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .get();

      final reviews = reviewsSnapshot.docs;

      if (reviews.isEmpty) {
        // Nếu không còn đánh giá nào, đặt rating về 0
        await FirebaseFirestore.instance
            .collection('foods')
            .doc(widget.productId)
            .update({
          'rating': 0,
          'reviewCount': 0,
        });
        return;
      }

      // Tính rating trung bình
      double totalRating = 0;
      for (var doc in reviews) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 0;
        totalRating += rating;
      }

      final averageRating = totalRating / reviews.length;

      // Cập nhật rating trung bình và số lượng đánh giá
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      debugPrint('Error updating average rating: ${e.toString()}');
    }
  }
}
