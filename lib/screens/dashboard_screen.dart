import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie/admin/admin_screen.dart';
import 'package:foodie/screens/home_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Check if the current user is an admin
  bool get isAdmin =>
      FirebaseAuth.instance.currentUser?.email == 'admin@foodstore.com';

  @override
  Widget build(BuildContext context) {
    // Redirect to the appropriate screen based on user role
    if (isAdmin) {
      return const AdminScreen();
    } else {
      return const HomeScreen();
    }
  }
}
