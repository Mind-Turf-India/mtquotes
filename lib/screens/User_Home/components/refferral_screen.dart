import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/theme_provider.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({Key? key}) : super(key: key);

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String _referralCode = "Loading...";
  String _rewardPoints = "0";
  User? _currentUser;
  final String _appPlayStoreLink =
      "https://play.google.com/store/apps/details?id=com.example.app";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser?.email == null) {
      setState(() {
        _isLoading = false;
        _referralCode = "Not Available";
      });
      return;
    }

    try {
      String userDocId = _currentUser!.email!.replaceAll('.', '_');

      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userDocId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _referralCode = data['referralCode'] ?? "Not Assigned";
            _rewardPoints = (data['rewardPoints'] ?? 0).toString();
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareReferralCode() {
    if (_referralCode != "Not Assigned" && _referralCode != "Loading...") {
      final String message =
          "Join this amazing app using my referral code: $_referralCode.\n"
          "Get rewards when you sign up!\nDownload now: $_appPlayStoreLink";
      Share.share(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Referral code not available.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.getIconColor(isDarkMode)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Share',
            style: TextStyle(color: AppColors.getTextColor(isDarkMode))
        ),
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          )
      )
          : SafeArea(
        child: Column(
          children: [
            Divider(color: AppColors.getDividerColor(isDarkMode)),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Referral image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? AppColors.primaryBlue.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/referral.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                            color: isDarkMode ? Colors.white70 : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Refer Friend & Earn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ask your friends to sign up with your referral code. Once done both you and your friend each earn rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Current points display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text.rich(
                              TextSpan(
                                text: "Your Points: ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.getTextColor(isDarkMode),
                                ),
                                children: [
                                  TextSpan(
                                    text: "$_rewardPoints points",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _referralCode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: AppColors.getTextColor(isDarkMode),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // How it works section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.primaryBlue.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isDarkMode
                                  ? AppColors.primaryBlue.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.2)
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How it works:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.getTextColor(isDarkMode),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStep('1. Share your referral code with friends', isDarkMode),
                            _buildStep('2. Friend signs up using your code', isDarkMode),
                            _buildStep('3. Both of you earn reward points', isDarkMode),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          minimumSize: Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _shareReferralCode,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Container(
                            height: 45,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.share, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Share',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextColor(isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}