import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'package:provider/provider.dart';
import 'components/settings.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String _rewardPoints = "0";
  String _referralCode = "Loading...";
  final String _appPlayStoreLink = "https://play.google.com/store/apps/details?id=com.example.app";

  @override
  void initState() {
    super.initState();
    _getUser();
    _fetchUserData();
  }

  void _getUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _rewardPoints = (userDoc['rewardPoints'] ?? 0).toString();
          _referralCode = userDoc['referralCode'] ?? "Not Assigned";
        });
      }
    }
  }

  void _shareReferralCode(BuildContext context) {
    if (_referralCode != "Not Assigned") {
      final String message = "Join this amazing app using my referral code: $_referralCode.\n"
          "Get rewards when you sign up!\nDownload now: $_appPlayStoreLink";
      Share.share(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Referral code not available.")),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 24),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, 'main');
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.bellRing, color: Colors.black),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => NotificationsSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, size: 50, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _user!.displayName ?? context.loc.user,
                style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.edit, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(
                text: "${context.loc.earncredits} : ",
                style: TextStyle(fontSize: fontSize, color: Colors.black),
                children: [
                  TextSpan(
                    text: "$_rewardPoints ${context.loc.points}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _shareReferralCode(context),
            child: Text.rich(
              TextSpan(
                text: "Referral Code : ",
                style: TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                    text: " $_referralCode",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context.loc.aboutus, fontSize, () {}),
                _buildMenuItem(context.loc.shareapplication, fontSize, () {}),
                _buildMenuItem(context.loc.drafts, fontSize, () {}),
                _buildMenuItem(context.loc.settings, fontSize, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsLanguage()),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  context.loc.logout,
                  style: TextStyle(fontSize: fontSize + 2, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, double textSize, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: textSize)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
