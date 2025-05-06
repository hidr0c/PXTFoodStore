import 'package:flutter/material.dart';
import 'package:foodie/screens/home_screen.dart';
import 'order_history_screen.dart';
import 'user_profile_screen.dart';
import 'feedback_screen.dart';

class BottomAppBarMenu extends StatefulWidget {
  const BottomAppBarMenu({super.key});

  @override
  State<BottomAppBarMenu> createState() => _BottomAppBarMenuState();
}

class _BottomAppBarMenuState extends State<BottomAppBarMenu> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: MediaQuery.of(context).size.height * 0.08,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 5,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) {
                  return const HomeScreen();
                },
              ));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.receipt_long,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const OrderHistoryScreen();
                },
              ));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.star,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const FeedbackScreen();
                },
              ));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_3_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const UserProfileScreen();
                },
              ));
            },
          ),
        ],
      ),
    );
  }
}
