import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _rewardPoints = "0";
  String _referralCode = "Loading...";
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final String _appPlayStoreLink = "https://play.google.com/store/apps/details?id=com.example.app"; 


  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // _getUser();
  }

  // void _getUser() {
  //   setState(() {
  //     User = FirebaseAuth.instance.currentUser;
  //   });
  // }

    Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentUser == null
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
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
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
                  child:
                      const Icon(Icons.person, size: 50, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentUser!.displayName ?? "User",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:  Text.rich(
                    TextSpan(
                      text: "Earned Credits : ",
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(
                          text: " $_rewardPoints",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                   
                ),
                SizedBox(height: 10,),
                GestureDetector(
                  onTap: () => _shareReferralCode(context),
                  child: Text.rich(
                      TextSpan(
                        text: "Referral Code : ",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          TextSpan(
                            text: " $_referralCode",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                ), 
                const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildMenuItem("About Us"),
                      _buildMenuItem("Share Application"),
                      _buildMenuItem("Drafts"),
                      _buildMenuItem("Settings"),
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
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Helper Widget for List Items
  Widget _buildMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: const TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: () {
              // Handle navigation
            },
          ),
          Divider(thickness: 1, color: Colors.grey.shade300, height: 0),
        ],
      ),
    );
  }
}
