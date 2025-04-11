import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mtquotes/screens/Auth_Screen/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../User_Home/components/Notifications/notification_service.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _rememberMe = false;
  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isLoading = true; // Add loading state for initial check

  @override
  void initState() {
    super.initState();
    _checkUserLoginStatus();
  }

  // Show loading dialog
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

  // Hide loading dialog
  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _checkUserLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        });
      }
    } catch (e) {
      // Handle any errors silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!passwordConfirmed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showLoadingDialog();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store user info in Firestore
      await saveUserToFirestore(userCredential.user);

      // Handle user change for notifications
      await NotificationService.instance.handleUserChanged(userCredential.user?.uid);

      // Request notification permissions after successful signup
      await NotificationService.instance.requestPermissions();

      _hideLoadingDialog();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false, // Remove all previous screens
      );
    } catch (e) {
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signup Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveUserToFirestore(User? user, {bool isNewSignUp = true}) async {
    if (user != null && user.email != null) {
      final String userEmail = user.email!.replaceAll(".", "_"); // Firestore doesn't allow '.' in document IDs
      final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);

      // First check if the user already exists
      DocumentSnapshot userSnapshot = await userRef.get();

      // If user exists and this is coming from signup flow, don't override data
      if (userSnapshot.exists && !isNewSignUp) {
        // Just update the login timestamp if needed
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // For new users or explicit signup flow
      if (!userSnapshot.exists) {
        final String referralCode = _generateReferralCode(user.uid);
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email,
          'name': null,
          'bio': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'referralCode': referralCode,
          'referrerUid': null,
          'rewardPoints': 100,
          'previousRewardPoints': 0,
          'isSubscribed': false,
          'isPaid': false,
          'role': 'user',
        };

        // Handling referral codes
        if (_referralController.text.trim().isNotEmpty) {
          String usedReferralCode = _referralController.text.trim();
          // Find the referrer in Firestore
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('referralCode', isEqualTo: usedReferralCode)
              .get();
          if (querySnapshot.docs.isNotEmpty) {
            DocumentSnapshot referrerDoc = querySnapshot.docs.first;
            String referrerUid = referrerDoc.id;
            // Update user data with referrer info
            userData['referrerUid'] = referrerUid;
            userData['rewardPoints'] += 100; // Reward for using a referral
            // Grant reward points to referrer
            await FirebaseFirestore.instance.collection('users').doc(referrerUid).update({
              'rewardPoints': FieldValue.increment(50),
            });
          }
        }

        // Save user data for new users
        await userRef.set(userData);
      }
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Before signing in, check if this is an existing user
      bool isExistingUser = false;
      try {
        // Check if email exists in Firestore
        final String userEmail = googleUser.email.replaceAll(".", "_");
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
        isExistingUser = userDoc.exists;
      } catch (e) {
        // If error checking, proceed with normal flow
        print("Error checking existing user: $e");
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Pass information about whether this is a new signup or existing user login
      await saveUserToFirestore(userCredential.user, isNewSignUp: !isExistingUser);

      // Handle user change for notifications
      await NotificationService.instance.handleUserChanged(userCredential.user?.uid);

      // Request notification permissions after successful login/signup
      await NotificationService.instance.requestPermissions();

      _hideLoadingDialog();

      // If it's an existing user coming from signup flow, show a message
      if (isExistingUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You already have an account with this email. Logging you in."),
            backgroundColor: Colors.green,
          ),
        );
      }

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

  // Function to generate a unique referral code
  String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String randomString = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return '${uid.substring(0, 6)}$randomString'; // Example: "AB1234XYZ89"
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Use AppColors directly for consistent theming
    final backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final iconColor = isDarkMode ? AppColors.darkIcon : AppColors.lightIcon;
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('assets/logo.png', height: 100, width: 100),
              const SizedBox(height: 10),
              Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  )
              ),
              Text(
                  'Create New Account',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  )
              ),
              const SizedBox(height: 50),
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
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure1,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure1 ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure1 = !_isObscure1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _isObscure2,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure2 ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _referralController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Referral code (if any)',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _signInWithEmailAndPassword,
                child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              Text('or', style: TextStyle(color: textColor)),
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
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: textColor),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                    },
                    child: Text(
                        'Sign In',
                        style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold
                        )
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}