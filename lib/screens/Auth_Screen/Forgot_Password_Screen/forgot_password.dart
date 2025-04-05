import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Helper method to show loading indicator
  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  // Helper method to hide loading indicator
  void _hideLoadingIndicator() {
    Navigator.of(context).pop();
  }

  Future<void> passwordReset() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              content: Text(
                "Please enter your email.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            );
          });
      return;
    }

    // Show loading indicator
    _showLoadingIndicator();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Hide loading indicator
      _hideLoadingIndicator();

      // Show a success dialog (whether the email exists or not)
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              content: Text(
                "If this email is registered, a password reset link has been sent.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            );
          });
    } on FirebaseAuthException catch (e) {
      // Hide loading indicator
      _hideLoadingIndicator();

      // Handle specific Firebase errors
      String message = "An error occurred. Please try again.";

      if (e.code == 'invalid-email') {
        message = "Invalid email format. Please enter a valid email.";
      }

      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              content: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            );
          });
    } catch (e) {
      // Hide loading indicator for any other exceptions
      _hideLoadingIndicator();

      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              content: Text(
                "An unexpected error occurred. Please try again.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 30),
                Text(
                  'Forgot Password',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Enter your email to reset your password',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 100),
                TextField(
                  controller: _emailController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                    labelStyle: theme.textTheme.bodyMedium,
                    fillColor: theme.colorScheme.surface,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : passwordReset,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}