import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:foodie/screens/splash_screen.dart';
import 'constant/theme_provider.dart';
import 'constant/app_theme.dart';
import 'screens/cart_provider.dart';
import 'screens/main_navigator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Check if user is logged in
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;
  // Check if user is admin
  final isAdmin = FirebaseAuth.instance.currentUser != null &&
      FirebaseAuth.instance.currentUser!.email == 'admin@foodstore.com';

  // Initialize CartProvider and load saved cart
  final cartProvider = CartProvider();
  await cartProvider.loadCart();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider.value(value: cartProvider),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
        isAdmin: isAdmin,
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
