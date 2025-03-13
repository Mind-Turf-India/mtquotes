import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtquotes/screens/Signup_Screen/signup_screen.dart';
import 'package:mtquotes/screens/User_Home/components/navbar_mainscreen.dart';
import 'package:mtquotes/screens/forgot_password.dart';
import 'package:http/http.dart' as http;
import '../User_Home/components/notification_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }


  /// Check if credentials exist and prompt user
  Future<void> _checkSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('saved_email');
    String? savedPassword = prefs.getString('saved_password');

    if (savedEmail != null && savedPassword != null) {
      _showLoginPopup(savedEmail, savedPassword);
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
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
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
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _saveCredentials();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (Route<dynamic> route) => false, // Remove all previous screens
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google Sign-In Failed: $e")));
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
        body: SingleChildScrollView(
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
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
