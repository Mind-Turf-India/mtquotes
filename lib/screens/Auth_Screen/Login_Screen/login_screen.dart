import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtquotes/screens/Auth_Screen/Signup_Screen/signup_screen.dart';
import 'package:mtquotes/screens/Auth_Screen/Forgot_Password_Screen/forgot_password.dart';
import 'package:http/http.dart' as http;
import '../../User_Home/components/Notifications/notification_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isObscure = true;
  bool _isLoading = true; // Add loading state for initial check

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  // Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // Hide loading dialog
  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Check if credentials exist and prompt user
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

  /// Show a popup to login with saved credentials
  void _showLoginPopup(String email, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Login with saved credentials?"),
        content: Text("Would you like to log in as $email?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close popup
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close popup
              _signInWithSavedCredentials(email, password);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  /// Login automatically with saved credentials
  Future<void> _signInWithSavedCredentials(String email, String password) async {
    _showLoadingDialog();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check and update user data in Firestore
      await saveUserToFirestore(userCredential.user);
      
      // Add this line to handle user change for notifications
      await NotificationService.instance.handleUserChanged(userCredential.user?.uid);

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false, // Remove all previous screens
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
      );
    }
  }

  /// Save credentials when Remember Me is checked
  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text.trim());
    }
  }

  /// Sign in with email & password
  Future<void> _signInWithEmailAndPassword() async {
    _showLoadingDialog();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _saveCredentials();
      
      // Check and update user data in Firestore
      await saveUserToFirestore(userCredential.user);
      
      await NotificationService.instance.handleUserChanged(userCredential.user?.uid);

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false, // Remove all previous screens
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
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

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Check and update user data in Firestore
      await saveUserToFirestore(userCredential.user);
      
      // Add this line to handle user change for notifications
      await NotificationService.instance.handleUserChanged(userCredential.user?.uid);

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false, // Remove all previous screens
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e")));
    }
  }

  // Function to generate a unique referral code (copied from signup screen)
  String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    String randomString = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return '${uid.substring(0, 6)}$randomString'; // Example: "AB1234XYZ89"
  }

  /// Save or update user in Firestore
  Future<void> saveUserToFirestore(User? user) async {
    if (user != null && user.email != null) {
      final String userEmail = user.email!.replaceAll(".", "_"); // Firestore doesn't allow '.' in document IDs
      final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
      
      // Check if user document already exists
      DocumentSnapshot doc = await userRef.get();
      
      if (!doc.exists) {
        // If user doesn't exist in Firestore, create a new profile
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
        };
        
        // Save user data
        await userRef.set(userData);
      } else {
        // If user exists, just update the lastLogin field
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents app from closing immediately
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Closes the app when back button is pressed
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
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
                  const Text('Welcome back!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                  const Text('Login to your account',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 50),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isObscure
                            ? Icons.visibility_off
                            : Icons.visibility),
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
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _signInWithEmailAndPassword,
                    child: const Text('Log In',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  const Text('or', style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Image.asset('assets/gooogle.png', height: 30),
                        onPressed: _signInWithGoogle,
                      ),
                      IconButton(
                        icon: Image.asset('assets/facebook.png', height: 30),
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
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignupScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.blue),
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