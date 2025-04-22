import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isProcessingVerification = false;

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

  Future checkEmailVerified() async {
    // Skip if we're already processing a verification
    if (_isProcessingVerification) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Set flag to prevent multiple simultaneous verification attempts
      _isProcessingVerification = true;
      
      // Reload user to get latest verification status
      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;
      
      final verified = freshUser?.emailVerified ?? false;
      setState(() {
        isEmailVerified = verified;
      });

      if (isEmailVerified) {
        timer?.cancel();
        
        // Complete the user creation with all data now that email is verified
        await completeUserCreation(freshUser);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Email verified successfully!"),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        
        // Navigate to main screen after a short delay
        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => MainScreen()),
            (Route<dynamic> route) => false,
          );
        });
      }
    } catch (e) {
      print("Error checking email verification: $e");
    } finally {
      // Reset processing flag
      _isProcessingVerification = false;
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
          backgroundColor: AppColors.primaryGreen,
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

  Future<void> _cancelVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Clean up the temporary user data
        await cleanupUnverifiedUser(user);
        
        // Then delete the auth user
        await user.delete();
      }
      
      await FirebaseAuth.instance.signOut();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen())
      );
    } catch (e) {
      // Handle error (user might have been signed in for too long to delete without re-authentication)
      print("Error during cancelation: $e");
      
      // Just sign out if we can't delete
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen())
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Verification cancelled, please sign up again."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Using theme-based colors
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);
    final surfaceColor = AppColors.getSurfaceColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final iconColor = AppColors.getIconColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Email Verification', 
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: _cancelVerification,
        ),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black12 : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 24),
              Text(
                'Verification Required',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'A verification email has been sent to:',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              if (!isEmailVerified)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              SizedBox(height: 16),
              Text(
                isEmailVerified ? 'Email verified!' : 'Checking verification status...',
                style: TextStyle(
                  color: isEmailVerified ? AppColors.primaryGreen : secondaryTextColor, 
                  fontSize: 14,
                  fontWeight: isEmailVerified ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canResendEmail ? AppColors.primaryBlue : Colors.grey.shade400,
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canResendEmail && !isEmailVerified ? resendVerificationEmail : null,
                child: Text(
                  'Resend Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _cancelVerification,
                child: Text(
                  'Cancel Verification',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}