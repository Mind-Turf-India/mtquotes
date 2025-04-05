import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart'; // Added import for your colors

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
            color: AppColors.primaryBlue,
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
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _isLoading = false;
      });

      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            final isDarkMode = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              content: Text(
                "Please enter your email.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: AppColors.primaryBlue),
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

      setState(() {
        _isLoading = false;
      });

      // Show a success dialog (whether the email exists or not)
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            final isDarkMode = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              content: Text(
                "If this email is registered, a password reset link has been sent.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            );
          });
    } on FirebaseAuthException catch (e) {
      // Hide loading indicator
      _hideLoadingIndicator();

      setState(() {
        _isLoading = false;
      });

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
            final isDarkMode = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              content: Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            );
          });
    } catch (e) {
      // Hide loading indicator for any other exceptions
      _hideLoadingIndicator();

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) {
            final theme = Theme.of(context);
            final isDarkMode = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
              content: Text(
                "An unexpected error occurred. Please try again.",
                style: theme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(color: AppColors.primaryBlue),
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
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? AppColors.darkIcon : AppColors.lightIcon,
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
                    color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                Text(
                  'Enter your email to reset your password',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(height: 100),
                TextField(
                  controller: _emailController,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : passwordReset,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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