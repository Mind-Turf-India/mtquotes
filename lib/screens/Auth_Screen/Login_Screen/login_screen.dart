import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtquotes/screens/Auth_Screen/Signup_Screen/signup_screen.dart';
import 'package:mtquotes/screens/Auth_Screen/Forgot_Password_Screen/forgot_password.dart';
import 'package:provider/provider.dart';
import '../../User_Home/components/Notifications/notification_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isObscure = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  void _showLoadingDialog() {
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

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _checkSavedCredentials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedEmail = prefs.getString('saved_email');
      String? savedPassword = prefs.getString('saved_password');

      if (savedEmail != null && savedPassword != null) {
        _showLoginPopup(savedEmail, savedPassword);
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginPopup(String email, String password) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurfaceColor(isDarkMode),
        title: Text(
          "Login with saved credentials?",
          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
        ),
        content: Text(
          "Would you like to log in as $email?",
          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              "No",
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signInWithSavedCredentials(email, password);
            },
            child: Text(
              "Yes",
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithSavedCredentials(
      String email, String password) async {
    _showLoadingDialog();

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await saveUserToFirestore(userCredential.user);

      // Handle user change for notifications
      await NotificationService.instance
          .handleUserChanged(userCredential.user?.uid);

      // Request notification permissions after successful login
      await NotificationService.instance.requestPermissions();

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    _showLoadingDialog();

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveCredentials();

      await saveUserToFirestore(userCredential.user);

      // Handle user change for notifications
      await NotificationService.instance
          .handleUserChanged(userCredential.user?.uid);

      // Request notification permissions after successful login
      await NotificationService.instance.requestPermissions();

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    _showLoadingDialog();

    try {
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _hideLoadingDialog();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await saveUserToFirestore(userCredential.user);

      // Handle user change for notifications
      await NotificationService.instance
          .handleUserChanged(userCredential.user?.uid);

      // Request notification permissions after successful login
      await NotificationService.instance.requestPermissions();

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    String randomString = String.fromCharCodes(Iterable.generate(
        5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return '${uid.substring(0, 6)}$randomString';
  }

  Future<void> saveUserToFirestore(User? user) async {
    if (user != null && user.email != null) {
      final String userEmail = user.email!.replaceAll(".", "_");
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userEmail);

      DocumentSnapshot doc = await userRef.get();

      if (!doc.exists) {
        final String referralCode = _generateReferralCode(user.uid);

        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email,
          'name': null,
          'bio': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'referralCode': referralCode,
          'referrerUid': null,
          'rewardPoints': 100,
          'previousRewardPoints': 0,
          'isSubscribed': false,
          'isPaid': false,
          'role': 'user',
          'answeredSurveys': [],
          'appOpenCount': 0,
          'lastAnsweredQuestionIndex': -1,
          'lastSurveyAppOpenCount': 0,
          'lastSurveyShown': null,
        };

        await userRef.set(userData);
      } else {
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = AppColors.getTextColor(isDarkMode);
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);
    final iconColor = AppColors.getIconColor(isDarkMode);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 70),
                        Image.asset(
                          'assets/logo.png',
                          height: 100,
                          width: 100,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Login to your account',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 50),
                        TextField(
                          controller: _emailController,
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.primaryBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: secondaryTextColor),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: AppColors.primaryBlue),
                            ),
                            suffixIcon: IconButton(
                              icon: _isObscure
                                  ? SvgPicture.asset(
                                      'assets/icons/hidden_5340196.svg',
                                      width: 24,
                                      height: 24,
                                      color: iconColor,
                                    )
                                  : SvgPicture.asset(
                                      'assets/icons/blind_6212534 1.svg',
                                      width: 24,
                                      height: 24,
                                      color: iconColor,
                                    ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.primaryBlue,
                                  checkColor: Colors.white,
                                ),
                                Text(
                                  'Remember me',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _signInWithEmailAndPassword,
                          child: const Text(
                            'Log In',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'or',
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: SvgPicture.asset(
                                'assets/icons/Group.svg',
                                width: 20,
                                height: 35,
                              ),
                              onPressed: _signInWithGoogle,
                            ),
                            IconButton(
                              icon: SvgPicture.asset(
                                'assets/icons/facebook_2111393.svg',
                                width: 24,
                                height: 33,
                              ),
                              onPressed: () {
                                // Implement Facebook login
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: textColor),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(color: AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
