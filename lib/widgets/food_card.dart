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
    // Calculate the total available height for the card
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - (3 * ThemeConstants.spacingSM)) / 2;
    final cardHeight = cardWidth / 0.7; // Match the grid's aspect ratio

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingXS / 2,
            vertical: ThemeConstants.spacingXS / 2,
          ),
          decoration: BoxDecoration(
            color: ThemeConstants.surfaceColor,
            borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLG),
            boxShadow: ThemeConstants.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: cardHeight * 0.5, // 50% of card height for image
                child: Stack(
                  children: [
                    NetworkImageWithFallback(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(ThemeConstants.borderRadiusLG),
                        topRight: Radius.circular(ThemeConstants.borderRadiusLG),
                      ),
                    ),
                    if (onFavoriteToggle != null)
                      Positioned(
                        top: ThemeConstants.spacingXS,
                        right: ThemeConstants.spacingXS,
                        child: Container(
                          padding: EdgeInsets.all(ThemeConstants.spacingXS),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: ThemeConstants.shadowSm,
                          ),
                          child: InkWell(
                            onTap: onFavoriteToggle,
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? ThemeConstants.errorColor : ThemeConstants.textSecondaryColor,
                              size: 18,
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
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ThemeConstants.spacingXS / 2),
                      Text(
                        category,
                        style: ThemeConstants.bodyMedium.copyWith(
                          fontSize: 12,
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
                              color: ThemeConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusSM),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: ThemeConstants.primaryColor,
                                  size: 12,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '4.8',
                                  style: ThemeConstants.bodyMedium.copyWith(
                                    color: ThemeConstants.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
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
      ),
    );
  }
} 