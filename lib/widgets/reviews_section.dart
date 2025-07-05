import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:foodie/widgets/rating_review_dialog.dart';
import 'package:intl/intl.dart';

class ReviewsSection extends StatefulWidget {
  final String foodId;
  final String foodName;
  final String? imageUrl;

  const ReviewsSection({
    super.key,
    required this.foodId,
    required this.foodName,
    this.imageUrl,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => RatingReviewDialog(
        foodId: widget.foodId,
        foodName: widget.foodName,
        imageUrl: widget.imageUrl,
      ),
    ).then((_) {
      setState(() {}); // Refresh the UI after dialog is closed
    });
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      return; // Loading state is now managed by the StreamBuilder
    }

    try {
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update average rating for the food
      final allReviews = await _firestore
          .collection('reviews')
          .where('foodId', isEqualTo: widget.foodId)
          .get();

      if (allReviews.docs.isEmpty) {
        await _firestore.collection('foods').doc(widget.foodId).update({
          'rating': 0,
          'reviewCount': 0,
        });
      } else {
        double totalRating = 0;
        for (var doc in allReviews.docs) {
          totalRating += (doc.data()['rating'] as num).toDouble();
        }

        double avgRating = totalRating / allReviews.docs.length;

        await _firestore.collection('foods').doc(widget.foodId).update({
          'rating': avgRating,
          'reviewCount': allReviews.docs.length,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa đánh giá')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          // Refresh the state when done
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              currentUser != null
                  ? ElevatedButton(
                      onPressed: _showRatingDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Viết đánh giá'),
                    )
                  : TextButton(
                      onPressed: () {
                        // Navigate to login
                      },
                      child: const Text('Đăng nhập để đánh giá'),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('reviews')
              .where('foodId', isEqualTo: widget.foodId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lỗi: ${snapshot.error}'),
                ),
              );
            }

            final reviews = snapshot.data?.docs ?? [];

            if (reviews.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chưa có đánh giá nào. Hãy là người đầu tiên đánh giá!',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index].data() as Map<String, dynamic>;
                final reviewId = reviews[index].id;
                final createdAt = review['createdAt'] as Timestamp?;
                final isCurrentUserReview =
                    currentUser != null && review['userId'] == currentUser.uid;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
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
                                      backgroundColor: Colors.primaries[
                                          review['userName'].toString().length %
                                              Colors.primaries.length],
                                      child: Text(
                                        review['userName']
                                            .toString()[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['userName'] ?? 'Người dùng',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (createdAt != null)
                                            Text(
                                              DateFormat('dd/MM/yyyy HH:mm')
                                                  .format(createdAt.toDate()),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrentUserReview)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () => _deleteReview(reviewId),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < (review['rating'] as num).toDouble()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['review'] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
