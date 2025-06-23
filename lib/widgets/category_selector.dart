import 'package:flutter/material.dart';
import '../constant/theme_constants.dart';

class CategorySelector extends StatelessWidget {
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.symmetric(horizontal: ThemeConstants.spacingMD),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category['name'] == selectedCategory;

          return GestureDetector(
            onTap: () => onCategorySelected(category['name']!),
            child: Container(
              margin: EdgeInsets.only(right: ThemeConstants.spacingMD),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: ThemeConstants.animationFast,
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(ThemeConstants.borderRadiusMD),
                      boxShadow: isSelected
                          ? ThemeConstants.shadowMd
                          : ThemeConstants.shadowSm,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(ThemeConstants.borderRadiusMD),
                      child: Image.asset(
                        category['image']!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: ThemeConstants.spacingSM),
                  Text(
                    category['name']!,
                    style: ThemeConstants.bodyMedium.copyWith(
                      color: isSelected
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.textSecondaryColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
