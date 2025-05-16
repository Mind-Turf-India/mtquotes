import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Set system UI to match your splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Check onboarding status and auth status
        await _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    User? currentUser = FirebaseAuth.instance.currentUser;

    // Navigation logic that follows your desired flow
    if (!hasCompletedOnboarding) {
      // User hasn't completed onboarding
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, 'onboarding');
    } else if (currentUser == null) {
      // User has completed onboarding but isn't logged in
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, 'login');
    } else {
      // User is logged in
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/nav_bar');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/intro.json',
              width: 500,
              height: 500,
              controller: _controller,
              onLoaded: (composition) {
                // Configure the animation controller
                _controller.duration = composition.duration;
                _controller.forward();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Vaky",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}