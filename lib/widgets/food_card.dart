import 'package:flutter/material.dart';
import '../constant/theme_constants.dart';
import 'network_image.dart';

class FoodCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double price;
  final String category;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const FoodCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.category,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - (3 * ThemeConstants.spacingSM)) / 2;
    final cardHeight = cardWidth / 0.7;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      splashColor: ThemeConstants.primaryColor.withOpacity(0.1),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingXS / 2,
          vertical: ThemeConstants.spacingXS / 2,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ThemeConstants.surfaceColor.withOpacity(0.95),
              ThemeConstants.primaryColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: ThemeConstants.primaryColor.withOpacity(0.10),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
            ...ThemeConstants.shadowSm,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: cardHeight * 0.5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: NetworkImageWithFallback(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: ThemeConstants.spacingXS,
                      right: ThemeConstants.spacingXS,
                      child: Material(
                        color: Colors.white,
                        shape: CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: CircleBorder(),
                          onTap: onFavoriteToggle,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? ThemeConstants.errorColor : ThemeConstants.textSecondaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ThemeConstants.spacingSM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: ThemeConstants.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ThemeConstants.spacingXS / 2),
                    Text(
                      category,
                      style: ThemeConstants.bodyMedium.copyWith(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: ThemeConstants.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ThemeConstants.spacingXS / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${price.toStringAsFixed(0)} VNĐ',
                            style: ThemeConstants.bodyMedium.copyWith(
                              color: ThemeConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ThemeConstants.spacingXS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusSM),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: ThemeConstants.primaryColor,
                                size: 13,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '4.8',
                                style: ThemeConstants.bodyMedium.copyWith(
                                  color: ThemeConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
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
          ],
        ),
      ),
    );
  }
}