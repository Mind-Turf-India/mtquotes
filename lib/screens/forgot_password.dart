import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> passwordReset() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              content: Text("Please enter your email."),
            );
          });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      // Show a success dialog (whether the email exists or not)
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text(
                  "If this email is registered, a password reset link has been sent."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          });
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      String message = "An error occurred. Please try again.";

      if (e.code == 'invalid-email') {
        message = "Invalid email format. Please enter a valid email.";
      }

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 70),
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 30),
                const Text('Forgot Password',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                const Text('Enter your email to reset your password',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 100),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: passwordReset,
                  child: const Text('Submit',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
