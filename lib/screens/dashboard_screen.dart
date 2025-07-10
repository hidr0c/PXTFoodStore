import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/screens/main_navigator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Check if the current user is an admin
  bool get isAdmin =>
      FirebaseAuth.instance.currentUser?.email == 'admin@foodstore.com';

  @override
  Widget build(BuildContext context) {
    // Use MainNavigator to provide the main app structure
    return MainNavigator(isAdmin: isAdmin);
  }
}
