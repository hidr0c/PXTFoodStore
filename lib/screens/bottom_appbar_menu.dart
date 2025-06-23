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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
        break;
      case 1:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const UserProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? Theme.of(context).primaryColor
                      : Colors.black),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.receipt_long,
                  color: _selectedIndex == 1
                      ? Theme.of(context).primaryColor
                      : Colors.black),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: Icon(Icons.star,
                  color: _selectedIndex == 2
                      ? Theme.of(context).primaryColor
                      : Colors.black),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              icon: Icon(Icons.person_3_outlined,
                  color: _selectedIndex == 3
                      ? Theme.of(context).primaryColor
                      : Colors.black),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}
