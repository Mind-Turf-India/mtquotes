import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  User? _userName;
  String _rewardPoints = "0";
  String _referralCode = "Loading...";
  String _userDisplayName = "Loading...";
  String? _profileImageUrl; // Add this to store profile image URL
  final String _appPlayStoreLink =
      "https://play.google.com/store/apps/details?id=com.example.app";

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    _userName = FirebaseAuth.instance.currentUser;
    if (_userName != null) {
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (_userName?.email == null) return;

    try {
      String userDocId = _userName!.email!.replaceAll('.', '_');

      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userDocId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _rewardPoints = (data['rewardPoints'] ?? 0).toString();
            _referralCode = data['referralCode'] ?? "Not Assigned";
            _userDisplayName = data['name'] ?? _userName!.displayName ?? "User";
            _profileImageUrl = data['profileImage']; // Get profile image URL
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _shareReferralCode(BuildContext context) {
    if (_referralCode != "Not Assigned") {
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  void _showUserProfileDialog() {
    // Don't store the dialog context for later use
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing without completing
      builder: (dialogContext) {
        TextEditingController nameController = TextEditingController(text: _userDisplayName);
        TextEditingController bioController = TextEditingController();
        File? _selectedImage;

        // Fetch existing bio from Firestore if available
        FirebaseFirestore.instance
            .collection('users')
            .doc(_userName!.email!.replaceAll('.', '_'))
            .get()
            .then((doc) {
              if (doc.exists && doc.data()?['bio'] != null) {
                bioController.text = doc.data()?['bio'];
              }
            });

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Your Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedImage = await _pickImage();
                      if (pickedImage != null) {
                        setState(() {
                          _selectedImage = pickedImage;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null),
                      child: (_selectedImage == null && 
                             (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                          ? Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(labelText: "Bio"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 1. Validate input synchronously
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Name cannot be empty")),
                      );
                      return;
                    }

                    // 2. Capture all data needed BEFORE any async operation
                    final User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Error: User not logged in")),
                      );
                      return;
                    }

                    final String userDocId = currentUser.email!.replaceAll('.', '_');
                    final String newName = nameController.text;
                    final String newBio = bioController.text;
                    final File? imageToUpload = _selectedImage;

                    // 3. Close the dialog before any async operation
                    Navigator.of(dialogContext).pop();

                    // 4. Perform all async operations after the dialog is closed
                    // We don't pass dialogContext here since it will be disposed
                    _saveProfileData(userDocId, newName, newBio, imageToUpload);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<File?> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image == null ? null : File(image.path);
  }

  Future<String?> _uploadImage(File image) async {
    try {
      // Create a unique filename
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child(fileName);

      // Upload image
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String imageUrl = await snapshot.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _saveProfileData(String userDocId, String name, String bio, File? image) async {
    try {
      String? imageUrl;
      
      if (image != null) {
        imageUrl = await _uploadImage(image);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .update({
        'name': name,
        'bio': bio,
        'profileImage': imageUrl ?? _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Only update UI if widget is still mounted
      if (mounted) {
        setState(() {
          _userDisplayName = name;
          if (imageUrl != null) {
            _profileImageUrl = imageUrl;
          }
        });
        
        // Refresh data
        await _fetchUserData();
        
        // Show success message using the main context, not the dialog context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _userName == null
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
                // Profile image - now using the stored URL
                GestureDetector(
                  onTap: _showUserProfileDialog,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.black54)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userDisplayName,
                      style: TextStyle(
                          fontSize: fontSize + 2, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        _showUserProfileDialog();
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
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
                          text: "$_rewardPoints ${context.loc.points}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green),
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
                      _buildMenuItem(context.loc.aboutus, fontSize, () {}),
                      _buildMenuItem(
                          context.loc.shareapplication, fontSize, () {}),
                      _buildMenuItem(context.loc.drafts, fontSize, () {}),
                      _buildMenuItem(context.loc.settings, fontSize, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingsPage()),
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

  Widget _buildMenuItem(String title, double textSize, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: textSize)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}