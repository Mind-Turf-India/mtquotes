import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/about_us.dart';
import 'package:mtquotes/screens/User_Home/components/Notifications/notifications.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/support.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/refferral_screen.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_provider.dart';
import 'components/Notifications/notification_service.dart';
import 'components/Settings/settings.dart';
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
    await NotificationService.instance.handleUserChanged(null);

    if (mounted) {
      Navigator.pushReplacementNamed(context, 'login');
    }
  }

  void _showUserProfileDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Don't store the dialog context for later use
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing without completing
      builder: (dialogContext) {
        TextEditingController nameController =
        TextEditingController(text: _userDisplayName);
        TextEditingController bioController = TextEditingController();
        File? selectedImage;
        bool isImageLoading = false; // Flag to track image loading state

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
              backgroundColor: AppColors.getBackgroundColor(isDarkMode),
              title: Text(
                context.loc.edityourprofile,
                style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isImageLoading
                        ? null // Disable tap when loading
                        : () async {
                      final pickedImage = await _pickImage();
                      if (pickedImage != null) {
                        setState(() {
                          selectedImage = pickedImage;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (_profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                          as ImageProvider
                              : null),
                          child: (selectedImage == null &&
                              (_profileImageUrl == null ||
                                  _profileImageUrl!.isEmpty))
                              ? SvgPicture.asset(
                            'assets/icons/camera.svg',
                            width: 40,
                            height: 40,
                            colorFilter: ColorFilter.mode(
                              AppColors.getIconColor(isDarkMode),
                              BlendMode.srcIn,
                            ),
                          )
                              : null,
                        ),
                        // Overlay a loading indicator when image is being processed
                        if (isImageLoading)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(color: AppColors.getTextColor(isDarkMode).withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.getTextColor(isDarkMode).withOpacity(0.3)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  TextField(
                    controller: bioController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    decoration: InputDecoration(
                      labelText: "Bio",
                      labelStyle: TextStyle(color: AppColors.getTextColor(isDarkMode).withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.getTextColor(isDarkMode).withOpacity(0.3)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isImageLoading
                      ? null // Disable cancel button when loading
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    context.loc.cancel,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isImageLoading
                      ? null // Disable save button when loading
                      : () async {
                    // 1. Validate input synchronously
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text("Name cannot be empty")),
                      );
                      return;
                    }

                    // 2. Capture all data needed BEFORE any async operation
                    final User? currentUser =
                        FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text("Error: User not logged in")),
                      );
                      return;
                    }

                    // 3. If there's a selected image, start loading state and upload it right away
                    if (selectedImage != null) {
                      setState(() {
                        isImageLoading = true;
                      });

                      try {
                        // Upload the image while dialog is still open
                        String? imageUrl =
                        await _uploadImage(selectedImage!);

                        // If upload failed, show error but don't close dialog
                        if (imageUrl == null) {
                          setState(() {
                            isImageLoading = false;
                          });
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(
                            const SnackBar(
                                content: Text("Failed to upload image")),
                          );
                          return;
                        }

                        // Update profile image URL
                        _profileImageUrl = imageUrl;
                      } catch (e) {
                        setState(() {
                          isImageLoading = false;
                        });
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                              content: Text("Error uploading image: $e")),
                        );
                        return;
                      }
                    }

                    final String userDocId =
                    currentUser.email!.replaceAll('.', '_');
                    final String newName = nameController.text;
                    final String newBio = bioController.text;

                    // 4. Close the dialog after image upload completes
                    Navigator.of(dialogContext).pop();

                    // 5. Complete the profile update
                    _saveProfileData(userDocId, newName, newBio, null);
                  },
                  child: Text(context.loc.save),
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

      // Monitor upload progress if needed
      // uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      //   double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      //   print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      // });

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String imageUrl = await snapshot.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _saveProfileData(
      String userDocId, String name, String bio, File? image) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    try {
      // Show loading indicator for the main screen
      if (mounted) {
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

      String? imageUrl;

      // If image parameter is provided, upload it (this path is not used anymore)
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
        // Close loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        setState(() {
          _userDisplayName = name;
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
        // Close loading dialog if open
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      body: _userName == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: 24,
                    color: AppColors.getIconColor(isDarkMode),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/nav_bar');
                  },
                ),

                const Spacer(),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/notification_3002272.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      AppColors.getTextColor(isDarkMode),
                      BlendMode.srcIn,
                    ),
                  ),
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
              backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              backgroundImage:
              _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                  ? SvgPicture.asset(
                'assets/icons/user_profile_new.svg',
                width: 50,
                height: 50,
                colorFilter: ColorFilter.mode(
                  AppColors.getIconColor(isDarkMode),
                  BlendMode.srcIn,
                ),
              )

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
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  _showUserProfileDialog();
                },
                child: SvgPicture.asset(
                  'assets/icons/pen_1659682.svg',
                  width: 15,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    AppColors.getIconColor(isDarkMode),
                    BlendMode.srcIn,
                  ),
                )
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(
                text: "${context.loc.earncredits} : ",
                style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                children: [
                  TextSpan(
                    text: "$_rewardPoints ${context.loc.points}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                children: [
                  TextSpan(
                    text: " $_referralCode",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
                _buildMenuItem(
                    'assets/icons/premium_1659060.svg',
                    context.loc.subscriptions,
                    fontSize,
                    isDarkMode,
                        () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SubscriptionScreen()
                          )
                      );
                    }
                ),
                _buildMenuItem(
                    'assets/icons/share.svg',
                    context.loc.shareapplication,
                    fontSize,
                    isDarkMode,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReferralPage()
                        ),
                      );
                    }
                ),
                _buildMenuItem(
                    'assets/icons/customer-support_3888615.svg',
                    context.loc.support,
                    fontSize,
                    isDarkMode,
                        () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SupportScreen()
                          )
                      );
                    }
                ),
                _buildMenuItem(
                    'assets/icons/info_1504403.svg',
                    context.loc.aboutus,
                    fontSize,
                    isDarkMode,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AboutUsScreen()
                        ),
                      );
                    }
                ),
                _buildMenuItem(
                  'assets/icons/settings_2099058.svg',
                  context.loc.settings,
                  fontSize,
                  isDarkMode,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsPage()
                      ),
                    );
                  },
                ),
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
                  padding: EdgeInsets.zero, // Remove default padding for the gradient
                  backgroundColor: Colors.transparent, // Make button background transparent
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0, // Optional: Remove elevation shadow
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    width: double.infinity, // Make button expand to full width
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center, // Center the text
                    child: Text(
                      context.loc.logout,
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      String iconPath,
      String title,
      double textSize,
      bool isDarkMode,
      VoidCallback onTap
      ) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          AppColors.getIconColor(isDarkMode),
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: textSize,
          color: AppColors.getTextColor(isDarkMode),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.getIconColor(isDarkMode).withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }
}