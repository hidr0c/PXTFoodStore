import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodie/screens/cart_provider.dart';
import 'package:foodie/screens/main_navigator.dart';
import 'package:foodie/screens/auth/splash_screen.dart';
import 'package:foodie/constant/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if user is logged in
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;

  // Check if user has admin role
  bool isAdmin = false;
  if (isLoggedIn) {
    final prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool('isAdmin') ?? false;
  }
  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider<CartProvider>(
            create: (context) => CartProvider(),
          ),
        ],
        child: MyApp(isLoggedIn: isLoggedIn, isAdmin: isAdmin),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isAdmin;

  const MyApp({
    super.key,
    this.isLoggedIn = false,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PXT Food Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        scaffoldBackgroundColor: AppTheme.scaffoldBgColor,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: isLoggedIn ? MainNavigator(isAdmin: isAdmin) : const SplashScreen(),
    );
  }
}
