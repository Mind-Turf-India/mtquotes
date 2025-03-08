import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'components/settings.dart';
import 'components/text_size.dart'; // Import the language settings screen
import 'package:mtquotes/providers/text_size_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
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
                _user!.displayName ?? context.loc.user,
                style: TextStyle(
                    fontSize: fontSize + 2, fontWeight: FontWeight.w600),
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
            child: Text.rich(
              TextSpan(
                text: "${context.loc.earncredits} : ",
                style: TextStyle(fontSize: fontSize, color: Colors.black),
                children: [
                  TextSpan(
                    text: "250 ${context.loc.points}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
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
                _buildMenuItem(context.loc.aboutus, fontSize, () {
                  // Handle About Us navigation
                }),
                _buildMenuItem(context.loc.shareapplication, fontSize, () {
                  // Handle Share Application
                }),
                _buildMenuItem(context.loc.drafts, fontSize, () {
                  // Handle Drafts navigation
                }),
                _buildMenuItem(context.loc.settings, fontSize, () {
                  // Navigate to the language settings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsLanguage(),
                    ),
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
                  style: TextStyle(
                      fontSize: fontSize + 2,
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
  Widget _buildMenuItem(String title, double textSize, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(title, style: TextStyle(fontSize: textSize)),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
            onTap: onTap,
          ),
          Divider(thickness: 1, color: Colors.grey.shade300, height: 0),
        ],
      ),
    );
  }
}
