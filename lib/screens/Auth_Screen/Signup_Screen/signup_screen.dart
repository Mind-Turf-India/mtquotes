import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mtquotes/screens/Auth_Screen/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../User_Home/components/Notifications/notification_service.dart';
import 'email_verification.dart';

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
      if (user != null && user.emailVerified) {
        // Only proceed to main screen if email is verified
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        });
      } else if (user != null && !user.emailVerified) {
        // If user exists but email not verified, navigate to verification screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: user.email ?? "",
              ),
            ),
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

  // Updated sign up function
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
    // Step 1: Create Firebase Auth user
    UserCredential userCredential =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Step 2: Send email verification
    await userCredential.user!.sendEmailVerification();
    
    // Step 3: Create temporary user record
    // Store referral code if provided, but don't apply rewards yet
    await createTemporaryUser(
      userCredential.user, 
      referralCode: _referralController.text.trim()
    );

    // Handle user change for notifications
    await NotificationService.instance
        .handleUserChanged(userCredential.user?.uid);

    // Request notification permissions after successful signup
    await NotificationService.instance.requestPermissions();

    _hideLoadingDialog();

    // Navigate to email verification screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: _emailController.text.trim(),
        ),
      ),
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

// New function to save temporary user data
Future<void> _saveTemporaryUserData(User? user) async {
  if (user == null) return;
  
  try {
    // You can store minimal data with an "isVerified" flag set to false
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'tempCreation': true,  // Flag to identify unverified accounts for potential cleanup
    });
  } catch (e) {
    print("Error saving temporary user data: $e");
  }
}

// Function to save the complete user profile after verification
Future<void> saveVerifiedUserToFirestore(User? user) async {
  if (user == null) return;
  
  try {
    // Get any additional user info you want to store
    // This would update the temporary record with full user data
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'email': user.email,
      'isVerified': true,
      'tempCreation': false,
      'verifiedAt': FieldValue.serverTimestamp(),
      // Add any other user fields you want to store
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      // Add additional fields as needed
    });
  } catch (e) {
    print("Error saving verified user to Firestore: $e");
  }
}

 // Step 1: Create a temporary user record during signup
Future<void> createTemporaryUser(User? user, {String? referralCode}) async {
  if (user == null || user.email == null) return;
  
  try {
    final String userEmail = user.email!.replaceAll(".", "_"); // Firestore doesn't allow '.' in document IDs
    final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
    
    // Basic temporary data
    Map<String, dynamic> tempUserData = {
      'uid': user.uid,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'isEmailVerified': false,
      'tempAccount': true,
      'pendingReferralCode': referralCode, // Store this to apply after verification
    };
    
    // Save temporary user data
    await userRef.set(tempUserData);
    
    print("Temporary user data saved while waiting for verification");
  } catch (e) {
    print("Error creating temporary user: $e");
  }
}

// Step 2: Complete user creation after email verification
Future<void> completeUserCreation(User? user) async {
  if (user == null || user.email == null) return;
  
  try {
    final String userEmail = user.email!.replaceAll(".", "_");
    final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
    
    // Get temporary user data
    DocumentSnapshot userSnapshot = await userRef.get();
    
    if (!userSnapshot.exists) {
      print("Error: User document not found during verification completion");
      return;
    }
    
    // Get data from the temporary record
    final userData = userSnapshot.data() as Map<String, dynamic>;
    String? pendingReferralCode = userData['pendingReferralCode'];
    
    // Generate full user data
    final String referralCode = _generateReferralCode(user.uid);
    Map<String, dynamic> completeUserData = {
      'uid': user.uid,
      'email': user.email,
      'name': null,
      'bio': null,
      'createdAt': userData['createdAt'], // Keep original creation timestamp
      'verifiedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
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
      'isEmailVerified': true,
      'tempAccount': false,
    };
    
    // Handle pending referral code if it exists
    if (pendingReferralCode != null && pendingReferralCode.isNotEmpty) {
      // Find the referrer in Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: pendingReferralCode)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot referrerDoc = querySnapshot.docs.first;
        String referrerUid = referrerDoc.id;
        // Update user data with referrer info
        completeUserData['referrerUid'] = referrerUid;
        completeUserData['rewardPoints'] += 100; // Reward for using a referral
        
        // Grant reward points to referrer
        await FirebaseFirestore.instance
            .collection('users')
            .doc(referrerUid)
            .update({
          'rewardPoints': FieldValue.increment(50),
        });
      }
    }
    
    // Update the user document with complete data
    await userRef.update(completeUserData);
    
    print("User creation completed after email verification");
  } catch (e) {
    print("Error completing user creation: $e");
  }
}

// Step 3: Handle user cleanup if verification is cancelled or times out
Future<void> cleanupUnverifiedUser(User? user) async {
  if (user == null || user.email == null) return;
  
  try {
    final String userEmail = user.email!.replaceAll(".", "_");
    final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
    
    // Delete the Firestore document
    await userRef.delete();
    print("Temporary user data cleaned up");
  } catch (e) {
    print("Error cleaning up unverified user: $e");
  }
}

// For backward compatibility - redirect to appropriate function
Future<void> saveUserToFirestore(User? user, {required bool isNewSignUp}) async {
  if (user == null || user.email == null) return;
  
  final String userEmail = user.email!.replaceAll(".", "_");
  final userRef = FirebaseFirestore.instance.collection('users').doc(userEmail);
  
  try {
    if (isNewSignUp) {
      // This is a new user - create full user record
      final String referralCode = _generateReferralCode(user.uid);
      
      // Extract pending referral code if it exists (You'll need to implement how you track this)
      String? pendingReferralCode = await _getPendingReferralCode();
      
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? null,
        'photoURL': user.photoURL,
        'bio': null,
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(), 
        'lastLoginAt': FieldValue.serverTimestamp(),
        'referralCode': referralCode,
        'referrerUid': null, // Will be handled by the cloud function if referral code is valid
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
        'isEmailVerified': true,
        'tempAccount': false,
        'googleSignIn': true, // Mark as Google sign-in
        'provider': 'google.com',
        'welcomeEmailSent': false // The cloud function will set this to true after sending the email
      };
      
      // Add pending referral code if it exists
      if (pendingReferralCode != null && pendingReferralCode.isNotEmpty) {
        userData['pendingReferralCode'] = pendingReferralCode;
      }
      
      // Create new user document
      await userRef.set(userData);
      
      print("New Google user created successfully");
    } else {
      // This is an existing user - just update login timestamp
      await userRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'appOpenCount': FieldValue.increment(1)
      });
      
      print("Existing user login updated");
    }
  } catch (e) {
    print("Error saving user to Firestore: $e");
    // You might want to handle this error, possibly by showing a notification
  }
}


// Helper method to retrieve pending referral code
// Implement this based on how you track referral codes in your app
Future<String?> _getPendingReferralCode() async {
  // Example implementation - replace with your actual implementation
  // This might be stored in SharedPreferences, app state, etc.
  
  // For example, if using SharedPreferences:
  // final prefs = await SharedPreferences.getInstance();
  // return prefs.getString('pendingReferralCode');
  
  return null; // Return null if no pending referral code
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

    // Before signing in, check if this is an existing user
    bool isExistingUser = false;
    String userEmail = '';
    try {
      // Check if email exists in Firestore
      userEmail = googleUser.email.replaceAll(".", "_");
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();
      isExistingUser = userDoc.exists;
    } catch (e) {
      // If error checking, proceed with normal flow
      print("Error checking existing user: $e");
    }

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Pass information about whether this is a new signup or existing user login
    await saveUserToFirestore(userCredential.user,
        isNewSignUp: !isExistingUser);

    // Handle user change for notifications
    await NotificationService.instance
        .handleUserChanged(userCredential.user?.uid);

    // Request notification permissions after successful login/signup
    await NotificationService.instance.requestPermissions();

    _hideLoadingDialog();

    // If it's an existing user coming from signup flow, show a message
    if (isExistingUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "You already have an account with this email. Logging you in."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show welcome message for new users
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Welcome! Your account has been created successfully.",
          ),
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
    String randomString = String.fromCharCodes(Iterable.generate(
        5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return '${uid.substring(0, 6)}$randomString'; // Example: "AB1234XYZ89"
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() ==
        _confirmPasswordController.text.trim();
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
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final secondaryTextColor =
        isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final iconColor = isDarkMode ? AppColors.darkIcon : AppColors.lightIcon;
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset('assets/logo.png', height: 100, width: 100),
                    const SizedBox(height: 10),
                    Text('Welcome',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        )),
                    Text('Create New Account',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        )),
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
                          icon: _isObscure1
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
                              _isObscure1 = !_isObscure1;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _confirmPasswordController,
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
                          icon: _isObscure2
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
                      child:
                          const Text('Sign Up', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                    Text('or', style: TextStyle(color: textColor)),
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
                          "Already have an account? ",
                          style: TextStyle(color: textColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()));
                          },
                          child: Text('Sign In',
                              style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold)),
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
