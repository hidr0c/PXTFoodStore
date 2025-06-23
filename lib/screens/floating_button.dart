import 'package:flutter/material.dart';
import 'package:foodie/constant/app_color.dart';
import 'package:foodie/screens/cart_screen.dart';
import 'package:foodie/widgets/cart_badge.dart';

class FloatingButton extends StatelessWidget {
  const FloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CartBadge(
      color: Colors.orange,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        },
        backgroundColor: AppColor.primaryColor,
        elevation: 8,
        child: Container(
          width: 72,
          height: 72,
          decoration: ShapeDecoration(
            color: AppColor.primaryColor,
            shape: const OvalBorder(),
            shadows: [
              BoxShadow(
                color: const Color(0x66000000),
                blurRadius: 16,
                offset: const Offset(0, 5),
                spreadRadius: 5,
              )
            ],
          ),
          child: const Icon(
            Icons.shopping_cart,
            size: 35,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
