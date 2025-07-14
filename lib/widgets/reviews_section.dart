// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/widgets/rating_bar.dart';
import 'package:foodie/widgets/rating_review_dialog.dart';
import 'package:intl/intl.dart';

class ReviewsSection extends StatefulWidget {
  final String productId;
  final String productName;
  final String? imageUrl;
  final bool isAdmin;

  const ReviewsSection({
    super.key,
    required this.productId,
    required this.productName,
    this.imageUrl,
    this.isAdmin = false,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  int _limit = 5;
  bool _isLoading = false;

  void _loadMore() {
    setState(() {
      _isLoading = true;
      _limit += 5;
    });

    // Wait a bit to simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _addReview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RatingReviewDialog(
        productId: widget.productId,
        productName: widget.productName,
        imageUrl: widget.imageUrl,
        isAdmin: widget.isAdmin,
        onReviewAdded: () {
          // Refresh the UI after review is added
          setState(() {});
        },
      ),
    );
  }

  void _editReview(
      BuildContext context, Map<String, dynamic> reviewData, String reviewId) {
    // Pre-fill the dialog with existing review data
    showDialog(
      context: context,
      builder: (context) => RatingReviewDialog(
        productId: widget.productId,
        productName: widget.productName,
        imageUrl: widget.imageUrl,
        isAdmin: reviewData['isAdmin'] ?? false,
        onReviewAdded: () {
          // Refresh the UI after review is edited
          setState(() {});
        },
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete the review
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Update average rating
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('foods')
          .doc(widget.productId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('foods')
            .doc(widget.productId)
            .update({
          'rating': 0.0,
          'totalRatings': 0,
        });
      } else {
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

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đánh giá'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              child: Column(
            children: [
              const SizedBox(height: 20),
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 10),
              const Text(
                'Đang tải đánh giá...',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ));
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã xảy ra lỗi khi tải đánh giá',
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ],
            ),
          );
        }
        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner hiển thị số lượng đánh giá
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${reviews.length} đánh giá từ khách hàng',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // Phần tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đánh giá & Nhận xét',
                  style: AppTheme.subheadingStyle,
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _addReview(context);
                  },
                  icon: Icon(
                    Icons.rate_review,
                    size: 16, // Giảm kích thước icon
                    color: AppTheme.primaryColor,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1), // Border mỏng hơn
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4), // Padding nhỏ hơn
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(6), // Border radius nhỏ hơn
                    ),
                  ),
                  label: Text(
                    'Viết đánh giá',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500), // Font size nhỏ hơn
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Lista các đánh giá
            ...reviews.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildReviewItem(data, doc.id);
            }),

            // Nút xem thêm
            if (reviews.length >= _limit) ...[
              const SizedBox(height: 16),
              Center(
                child: _isLoading
                    ? CircularProgressIndicator(color: AppTheme.primaryColor)
                    : TextButton(
                        onPressed: _loadMore,
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.scaffoldBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Giảm border radius
                            side: BorderSide(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 180),
                                width: 0.8), // Border mỏng và nhạt hơn
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6), // Giảm padding
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize
                              .min, // Để button chỉ rộng theo nội dung
                          children: [
                            Text(
                              'Xem thêm đánh giá',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13, // Giảm kích thước font
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: AppTheme.primaryColor)
                          ],
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
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12), // Giảm border radius
        border: Border.all(
            color: Colors.grey.shade200, width: 0.8), // Border mỏng hơn
        // Bỏ boxShadow để giảm bóng đổ
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Colors.amber.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên đánh giá món ăn này',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Viết đánh giá đầu tiên',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                _addReview(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> data, String reviewId) {
    final userName = data['userName'] ?? 'Người dùng ẩn danh';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = data['review'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Không rõ';
    final isCurrentUser =
        FirebaseAuth.instance.currentUser?.uid == data['userId'];
    final isAdmin = data['isAdmin'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10), // Giảm margin thêm
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Giảm border radius
      ),
      elevation: 0.5, // Giảm elevation để shadow nhạt hơn
      child: Padding(
        padding:
            const EdgeInsets.all(12), // Giảm padding để tiết kiệm không gian
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Đảm bảo alignment đúng
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Đảm bảo alignment đúng
                    children: [
                      CircleAvatar(
                        radius: 16, // Giảm kích thước avatar
                        backgroundColor: isAdmin
                            ? Colors.blue.shade700
                            : AppTheme.primaryColor,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12), // Giảm kích thước chữ
                        ),
                      ),
                      const SizedBox(width: 8), // Giảm khoảng cách
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  // Sử dụng Flexible thay vì Expanded để linh hoạt hơn
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14, // Giảm kích thước font
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin)
                                  Container(
                                    margin: const EdgeInsets.only(
                                        left: 4), // Giảm margin
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1), // Giảm padding
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      borderRadius: BorderRadius.circular(
                                          3), // Giảm border radius
                                    ),
                                    child: const Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 8, // Giảm kích thước font
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: AppTheme.textLightColor,
                                fontSize: 10, // Giảm kích thước font
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser || widget.isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18), // Giảm kích thước icon
                    padding: EdgeInsets.zero, // Giảm padding
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editReview(context, data, reviewId);
                      } else if (value == 'delete') {
                        _deleteReview(reviewId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (isCurrentUser)
                        PopupMenuItem(
                          value: 'edit',
                          height: 36, // Giảm height của item
                          child: Row(
                            mainAxisSize: MainAxisSize
                                .min, // Để row chỉ rộng theo nội dung
                            children: const [
                              Icon(Icons.edit,
                                  size: 16,
                                  color: AppTheme
                                      .textSecondaryColor), // Giảm kích thước icon
                              SizedBox(width: 8),
                              Text('Sửa',
                                  style: TextStyle(
                                      fontSize: 13)), // Giảm kích thước font
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        height: 36, // Giảm height của item
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min, // Để row chỉ rộng theo nội dung
                          children: const [
                            Icon(Icons.delete,
                                size: 16,
                                color: Colors.red), // Giảm kích thước icon
                            SizedBox(width: 8),
                            Text('Xóa',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13)), // Giảm kích thước font
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8), // Giảm khoảng cách
            RatingBar(
              rating: rating,
              size: 14, // Giảm kích thước
              showText: false,
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 6), // Giảm khoảng cách
              Text(
                comment,
                style: const TextStyle(fontSize: 13), // Giảm kích thước font
                maxLines: null, // Cho phép đoạn văn bản xuống dòng tự nhiên
                overflow: TextOverflow.visible, // Không ẩn văn bản bị tràn
              ),
            ],
          ],
        ),
      ),
    );
  }
}
