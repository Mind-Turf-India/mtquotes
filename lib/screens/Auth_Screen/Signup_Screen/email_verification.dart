import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Auth_Screen/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // Start a timer to periodically check if email is verified
      timer = Timer.periodic(Duration(seconds: 3), (_) => checkEmailVerified());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // Navigate to main screen after a short delay
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen()),
              (Route<dynamic> route) => false,
        );
      });
    }
  }

  Future resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      setState(() => canResendEmail = false);
      await Future.delayed(Duration(seconds: 60));
      setState(() => canResendEmail = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Verification email sent!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send verification email: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Email Verification', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen())
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A verification email has been sent to:\n${widget.email}',
              style: TextStyle(color: textColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ),
            SizedBox(height: 30),
            Text(
              'Checking verification status...',
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canResendEmail ? AppColors.primaryBlue : Colors.grey,
                minimumSize: const Size(200, 50),
                foregroundColor: Colors.white,
              ),
              onPressed: canResendEmail ? resendVerificationEmail : null,
              child: Text('Resend Email'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen())
                );
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}