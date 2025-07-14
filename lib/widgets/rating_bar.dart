import 'package:flutter/material.dart';
import 'package:foodie/constant/app_theme.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final bool showText;
  final int totalRatings;
  final Color color;
  final MainAxisAlignment alignment;
  final bool allowRating;
  final Function(double)? onRatingChanged;

  const RatingBar({
    super.key,
    required this.rating,
    this.size = 20,
    this.showText = true,
    this.totalRatings = 0,
    this.color = Colors.amber,
    this.alignment = MainAxisAlignment.start,
    this.allowRating = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để tạo giao diện linh hoạt
    final screenSize = MediaQuery.of(context).size;

    // Điều chỉnh kích thước theo kích thước màn hình
    final adaptiveSize = screenSize.width < 360 ? size * 0.9 : size;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        // Star rating
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isHalf = rating > index && rating < starValue;
              final isFull = rating >= starValue;

              return GestureDetector(
                onTap: allowRating
                    ? () => onRatingChanged?.call(starValue.toDouble())
                    : null,
                child: Icon(
                  isFull
                      ? Icons.star
                      : isHalf
                          ? Icons.star_half
                          : Icons.star_outline,
                  size: adaptiveSize, // Sử dụng kích thước thích ứng
                  color: color,
                ),
              );
            }),
          ),
        ),

        // Rating text
        if (showText) ...[
          SizedBox(width: 4), // Giảm khoảng cách
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: adaptiveSize * 0.8, // Sử dụng kích thước thích ứng
              fontWeight: FontWeight.w500, // Giảm độ đậm của font
              color: AppTheme.textPrimaryColor,
            ),
          ),

          // Total ratings count (if provided)
          if (totalRatings > 0) ...[
            SizedBox(width: 2), // Giảm khoảng cách
            Text(
              '($totalRatings)',
              style: TextStyle(
                fontSize: adaptiveSize * 0.7, // Sử dụng kích thước thích ứng
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class RatingDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final Function(double, String) onSubmit;

  const RatingDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.onSubmit,
  });
  @override
  RatingDialogState createState() => RatingDialogState();
}

class RatingDialogState extends State<RatingDialog> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đánh giá ${widget.productName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar(
            rating: _rating,
            size: 32,
            showText: false,
            color: AppTheme.primaryColor,
            alignment: MainAxisAlignment.center,
            allowRating: true,
            onRatingChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
          SizedBox(height: 16),
          Text(
            _ratingText(),
            style: TextStyle(
              fontSize: 16,
              color: _ratingColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhận xét của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _rating == 0
              ? null
              : () {
                  widget.onSubmit(_rating, _commentController.text);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: Text('Gửi đánh giá'),
        ),
      ],
    );
  }

  String _ratingText() {
    if (_rating == 0) return 'Chọn số sao';
    if (_rating <= 1) return 'Rất tệ';
    if (_rating <= 2) return 'Không hài lòng';
    if (_rating <= 3) return 'Bình thường';
    if (_rating <= 4) return 'Hài lòng';
    return 'Tuyệt vời';
  }

  Color _ratingColor() {
    if (_rating == 0) return AppTheme.textSecondaryColor;
    if (_rating <= 1) return Colors.red;
    if (_rating <= 2) return Colors.orange;
    if (_rating <= 3) return Colors.amber;
    if (_rating <= 4) return Colors.lightGreen;
    return Colors.green;
  }
}
