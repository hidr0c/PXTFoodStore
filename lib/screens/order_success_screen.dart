// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:foodie/constant/theme_constants.dart';
import 'home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ThemeConstants.spacingXL),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 100,
                      color: ThemeConstants.primaryColor,
                    ),
                  ),
                  SizedBox(height: ThemeConstants.spacingXL),
                  Text(
                    'Đặt hàng thành công!',
                    style: ThemeConstants.headingLarge.copyWith(
                      color: ThemeConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ThemeConstants.spacingMD),
                  Text(
                    'Cảm ơn bạn đã đặt hàng. Chúng tôi sẽ giao hàng đến bạn trong thời gian sớm nhất!',
                    style: ThemeConstants.bodyLarge.copyWith(
                      color: ThemeConstants.textSecondaryColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ThemeConstants.spacingXL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ThemeConstants.spacingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ThemeConstants.borderRadiusLG),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Trở về trang chủ',
                        style: ThemeConstants.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
