import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/navbar_mainscreen.dart';
import 'package:mtquotes/screens/Onboarding_Screen/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool stayLoggedIn = prefs.getBool('stayLoggedIn') ?? true;

  runApp(MyApp(startScreen: stayLoggedIn ? MainScreen() : OnboardingScreen()));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  MyApp({required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: startScreen, // Display the chosen start screen
      routes: {
        'onboarding': (context) => OnboardingScreen(),
        'main': (context) => MainScreen(),
      },
    );
  }
}
