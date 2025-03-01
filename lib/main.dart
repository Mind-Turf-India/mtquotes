import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/User_Home/components/navbar_mainscreen.dart';
import 'package:mtquotes/screens/Onboarding_Screen/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  // Check if the user is already signed in
  User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(MyApp(
    startScreen: currentUser != null
        ? MainScreen() // User is signed in, go to main screen
        : (hasCompletedOnboarding ? LoginScreen() : OnboardingScreen()),
  ));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: startScreen,
      routes: {
        'onboarding': (context) => OnboardingScreen(),
        'login': (context) => LoginScreen(),
        'main': (context) => MainScreen(),
      },
    );
  }
}
