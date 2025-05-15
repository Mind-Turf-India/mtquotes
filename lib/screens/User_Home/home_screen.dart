import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:mtquotes/screens/User_Home/components/Notifications/notifications.dart';
import 'package:mtquotes/screens/User_Home/vaky_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/text_size_provider.dart';
import '../Create_Screen/components/details_screen.dart';
import '../Templates/components/festivals/festival_handler.dart';
import '../Templates/components/festivals/festival_post.dart';
import '../Templates/components/festivals/festival_service.dart';
import '../Templates/components/template/template_sharing.dart';
import '../Templates/components/totd/totd_handler.dart';
import '../Templates/unified_model.dart';
import 'components/Categories/category_screen.dart';
import 'components/Home components/calendar_screen.dart';
import 'components/Home components/post_card_ui.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:mtquotes/screens/Templates/components/recent/recent_service.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/l10n/app_localization.dart';

import 'components/daily_check_in.dart';
import 'components/tapp_effect.dart';
import 'components/templates_list.dart';
import 'components/user_survey.dart';
import 'components/Home components/vertical_feed.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import 'files_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FeedManagerService _feedManager = FeedManagerService();
  final TemplateService _templateService = TemplateService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final FestivalService _festivalService = FestivalService();
  bool _loadingFestivals = false;
  List<FestivalPost> _festivalPosts = [];

  List<dynamic> _feedItems = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  String userName = "User";
  String profileImageUrl = "";
  TextEditingController _searchController = TextEditingController();
  bool _isListening = false;
  bool isCheckingReward = false;
  bool isLoadingPoints = false;
  bool isLoadingStreak = false;
  int userRewardPoints = 0;
  int checkInStreak = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadInitialFeed();
    _fetchFestivalPosts();
    _scrollController.addListener(_scrollListener);
    _checkUserProfile(); // Check if user profile is complete
    checkAndShowSurvey();


    isCheckingReward = false;
    isLoadingPoints = false;
    isLoadingStreak = false;
    userRewardPoints = 0;
    checkInStreak = 0;

    // Delay the check slightly to ensure UI is fully rendered
    Future.delayed(const Duration(milliseconds: 1000), () {
      checkDailyReward();
      checkAndShowSurvey();
    });

    // Load initial points
    fetchUserRewardPoints();
    fetchCheckInStreak();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Check if user profile is complete and show dialog if not
  void _checkUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    String userEmail = user.email!.replaceAll(".", "_");

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .get();

    if (!userDoc.exists || userDoc['name'] == null || userDoc['bio'] == null) {
      Future.delayed(Duration.zero, () => _showUserProfileDialog());
    }
  }

  void _toggleListening() {
    // This function would implement voice recognition functionality
    // For now, just toggle the state for UI changes
    setState(() {
      _isListening = !_isListening;
    });
  }

  // Show user profile dialog to collect user details
  void _showUserProfileDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        TextEditingController nameController = TextEditingController();
        TextEditingController bioController = TextEditingController();
        File? selectedImage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.getBackgroundColor(isDarkMode),
              title: Text(
                "Complete Your Profile",
                style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () async {
                        final pickedImage = await _pickImage();
                        if (pickedImage != null) {
                          setDialogState(() {
                            selectedImage = pickedImage;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl) as ImageProvider
                            : null),
                        child: (selectedImage == null && profileImageUrl.isEmpty)
                            ? Icon(Icons.camera_alt,
                            size: 40,
                            color: AppColors.getIconColor(!isDarkMode))
                            : null,
                      ),
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle:
                      TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    ),
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                  ),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      labelStyle:
                      TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    ),
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text("Name cannot be empty")),
                        );
                        return;
                      }

                      final String newName = nameController.text;
                      final String newBio = bioController.text;
                      final File? imageToUpload = selectedImage;

                      Navigator.pop(dialogContext);

                      bool canUpdateUI = true;

                      try {
                        await _updateUserProfile(
                          newName,
                          newBio,
                          imageToUpload,
                        );
                      } catch (e) {
                        canUpdateUI = false;
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error updating profile: $e")),
                          );
                        }
                      }

                      if (canUpdateUI && mounted) {
                        _fetchUserData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                              Text(context.loc.profileUpdatedSuccessfully)),
                        );
                      }
                    } catch (e) {
                      print("Error in profile update flow: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error updating profile: $e")),
                        );
                      }
                    }
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


  Future<void> _downloadImage(BuildContext context, String imageUrl, String title) async {
    final _auth = FirebaseAuth.instance;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Show loading indicator
    _showLoadingIndicator(context);

    try {
      // Download the image data
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final imageData = response.bodyBytes;

      // Check if user is logged in
      User? user = _auth.currentUser;
      if (user == null) {
        _hideLoadingIndicator(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please log in to save images"))
        );
        return;
      }

      // Request proper permissions based on platform and Android version
      bool hasPermission = false;

      if (Platform.isAndroid) {
        // Request different permissions based on Android SDK version
        if (await _getAndroidVersion() >= 33) {
          // Android 13+
          hasPermission = await _requestAndroid13Permission();
        } else if (await _getAndroidVersion() >= 29) {
          // Android 10-12
          hasPermission = await Permission.storage.isGranted;
          if (!hasPermission) {
            hasPermission = (await Permission.storage.request()).isGranted;
          }
        } else {
          // Android 9 and below
          hasPermission = await Permission.storage.isGranted;
          if (!hasPermission) {
            hasPermission = (await Permission.storage.request()).isGranted;
          }
        }
      } else if (Platform.isIOS) {
        // iOS typically doesn't need explicit permission for saving to gallery
        hasPermission = true;
      }

      if (!hasPermission) {
        _hideLoadingIndicator(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Storage permission is required to save images"))
        );
        return;
      }

      // Generate a unique filename based on timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "Vaky_${timestamp}.jpg";

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        imageData,
        quality: 100,
        name: fileName,
      );

      // Check if save was successful
      bool isGallerySaveSuccess = false;
      if (result is Map) {
        isGallerySaveSuccess = result['isSuccess'] ?? false;
      } else {
        isGallerySaveSuccess = result != null;
      }

      if (!isGallerySaveSuccess) {
        throw Exception("Failed to save image to gallery");
      }

      // Also save to user-specific directory for Files screen
      String userDirPath = await _getUserSpecificDirectoryPath(user);
      String filePath = '$userDirPath/$fileName';

      File file = File(filePath);
      await file.writeAsBytes(imageData);

      // Keep track of saved images in Firestore
      await _trackSavedImage(user, fileName, title);

      _hideLoadingIndicator(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image saved to your gallery and downloads"),
          duration: Duration(seconds: 3),
          backgroundColor: isDarkMode
              ? AppColors.primaryGreen.withOpacity(0.7)
              : AppColors.primaryGreen,
          action: SnackBarAction(
            label: 'VIEW ALL',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to FilesPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilesPage(),
                ),
              );
            },
          ),
        ),
      );

      print("Image saved to gallery and user directory: $fileName");
    } catch (e) {
      _hideLoadingIndicator(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
      print("Error saving image: $e");
    }
  }

// Function to get Android version
  Future<int> _getAndroidVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

// Function to request Android 13+ permissions
  Future<bool> _requestAndroid13Permission() async {
    // For Android 13, we need to request photos-specific permissions
    bool photos = await Permission.photos.isGranted;
    if (!photos) {
      photos = (await Permission.photos.request()).isGranted;
    }
    return photos;
  }

// Function to sanitize email for file path
  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

// Get user-specific directory path
  Future<String> _getUserSpecificDirectoryPath(User user) async {
    String userDir = _sanitizeEmail(user.email!);

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Pictures/Vaky/$userDir');
    } else {
      baseDir = Directory(
          '${(await getApplicationDocumentsDirectory()).path}/Vaky/$userDir');
    }

    // Create directory if it doesn't exist
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir.path;
  }

  Future<void> _trackSavedImage(User user, String fileName, String title) async {
    try {
      String userEmail = user.email!.replaceAll('.', '_');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('saved_images')
          .add({
        'fileName': fileName,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'path': Platform.isAndroid
            ? '/storage/emulated/0/Pictures/Vaky/${_sanitizeEmail(user.email!)}/$fileName'
            : '${(await getApplicationDocumentsDirectory()).path}/Vaky/${_sanitizeEmail(user.email!)}/$fileName',
      });
    } catch (e) {
      print('Error tracking saved image: $e');
    }
  }

// Show loading indicator
  void _showLoadingIndicator(BuildContext context) {
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

// Hide loading indicator
  void _hideLoadingIndicator(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

// 2. Daily Check-in Functionality
  Future<void> checkDailyReward() async {
    try {
      // Ensure the widget is still mounted
      if (!mounted) {
        print("HomeScreen not mounted, can't process daily check-in");
        return;
      }

      print("Checking daily reward eligibility...");

      // Show loading indicator
      setState(() {
        isCheckingReward = true;
      });

      // Check eligibility
      bool isEligible = await DailyCheckInService.isEligibleForDailyReward();

      print("User is eligible for daily reward: $isEligible");

      if (isEligible && mounted) {
        // Process the check-in with the current context
        bool processed = await DailyCheckInService.processDailyCheckIn(context);

        print("Daily check-in processed: $processed");

        if (processed && mounted) {
          // Wait a short moment to ensure Firebase has updated
          await Future.delayed(const Duration(milliseconds: 500));

          // Refresh user data to show updated points
          await fetchUserRewardPoints();

          // Optionally fetch streak
          await fetchCheckInStreak();
        }
      } else {
        print("User not eligible for daily reward");
      }

      // Hide loading indicator if still mounted
      if (mounted) {
        setState(() {
          isCheckingReward = false;
        });
      }
    } catch (e) {
      print("Error in checkDailyReward: $e");

      // Hide loading indicator in case of error
      if (mounted) {
        setState(() {
          isCheckingReward = false;
        });
      }
    }
  }

// Function to fetch and update user reward points
  Future<void> fetchUserRewardPoints() async {
    try {
      print("Fetching user reward points...");

      // Show loading indicator
      if (mounted) {
        setState(() {
          isLoadingPoints = true;
        });
      }

      // Get points from service
      int points = await DailyCheckInService.getUserRewardPoints();

      print("Fetched user reward points: $points");

      // Update UI if widget is still mounted
      if (mounted) {
        setState(() {
          userRewardPoints = points;
          isLoadingPoints = false;
        });
      }
    } catch (e) {
      print("Error fetching reward points: $e");

      // Hide loading indicator in case of error
      if (mounted) {
        setState(() {
          isLoadingPoints = false;
        });
      }
    }
  }

// Function to fetch check-in streak
  Future<void> fetchCheckInStreak() async {
    try {
      if (!mounted) return;

      setState(() {
        isLoadingStreak = true;
      });

      int streak = await DailyCheckInService.getCheckInStreak();

      if (mounted) {
        setState(() {
          checkInStreak = streak;
          isLoadingStreak = false;
        });
      }
    } catch (e) {
      print("Error fetching check-in streak: $e");

      if (mounted) {
        setState(() {
          isLoadingStreak = false;
        });
      }
    }
  }


  // Method to pick an image from gallery
  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Method to update user profile data
  Future<void> _updateUserProfile(String name, String bio, File? image) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        print("Error: No user logged in.");
        return;
      }

      String userEmail = user.email!.replaceAll(".", "_");
      String imageUrl = "";

      if (image != null) {
        print("Uploading image...");
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref(
            'profile_images/${userEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg')
            .putFile(image);

        imageUrl = await snapshot.ref.getDownloadURL();
        print("Image uploaded successfully: $imageUrl");
      }

      await FirebaseFirestore.instance.collection('users').doc(userEmail).set({
        'name': name,
        'bio': bio,
        'profileImage': imageUrl.isNotEmpty
            ? imageUrl
            : profileImageUrl, // Keep existing if no new one
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("User profile updated successfully");

      if (mounted) {
        setState(() {
          userName = name;
          if (imageUrl.isNotEmpty) {
            profileImageUrl = imageUrl;
          }
        });
      }
    } catch (e) {
      print("Error in _updateUserProfile: $e");
      throw e; // Re-throw to handle in the calling method
    }
  }

  // Scroll listener for infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // Load more content when we're 500 pixels from the bottom
      if (!_isLoadingMore && !_hasReachedEnd) {
        _loadMoreContent();
      }
    }
  }

  // Update _fetchUserData method to ensure profile image URL is set correctly

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      String emailIdWithUnderscores = user.email!.replaceAll('.', '_');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(emailIdWithUnderscores)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Add debug print to see profile image value
        print("Fetched profile image from Firestore: ${data.containsKey('profileImage') ? data['profileImage'] : 'not found'}");

        setState(() {
          userName = data['name'] ?? 'User';
          // Make sure we handle null or missing profileImage properly
          if (data.containsKey('profileImage') && data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
            profileImageUrl = data['profileImage'].toString();
          } else {
            // Set to placeholder if not available
            profileImageUrl = '';
          }
        });

        // Debug print after setting
        print("After setting, profileImageUrl = $profileImageUrl");

        // Update the user info in FeedManagerService
        _feedManager.setCurrentUserInfo(userName, profileImageUrl);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Make sure profileImageUrl has a valid value even if there's an error
      if (profileImageUrl.isEmpty && mounted) {
        setState(() {
          profileImageUrl = '';
        });
      }
    }
  }

  Future<void> _loadInitialFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _hasReachedEnd = false;
      });

      final feedItems = await _feedManager.generateInitialFeed();

      if (mounted) {
        setState(() {
          _feedItems = feedItems;
          _isLoading = false;
          _isRefreshing = false;
          _hasReachedEnd =
              feedItems.isEmpty; // If no items, we've reached the end
        });
      }
    } catch (e) {
      print('Error loading initial feed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final moreItems = await _feedManager.fetchMoreContent();

      if (mounted) {
        setState(() {
          if (moreItems.isEmpty) {
            _hasReachedEnd = true;
          } else {
            _feedItems.addAll(moreItems);
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more content: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      _hasReachedEnd = false;
    });
    await _loadInitialFeed();
  }

  Future _handleEditPost(UnifiedPost post) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check if user is subscribed for premium templates
      bool isSubscribed = await _templateService.isUserSubscribed();

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Handle premium content
      if (post.isPaid && !isSubscribed) {
        SubscriptionPopup.show(context);
        return;
      }

      // Convert post to QuoteTemplate for compatibility with existing screens
      QuoteTemplate template = post.toQuoteTemplate();

      // Add to recent templates
      await RecentTemplateService.addRecentTemplate(template);

      // CHANGED: Navigate to DetailsScreen instead of EditScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            template: template,
            isPaidUser: isSubscribed,
          ),
        ),
      );
    } catch (e) {
      print('Error handling edit post: $e');

      // Close loading dialog if still open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String getValidProfileImageUrl() {
    // Add debug prints
    print("Current profileImageUrl in HomeScreen: $profileImageUrl");

    // Check if profileImageUrl is empty or null
    if (profileImageUrl.isEmpty) {
      // Return empty string instead of placeholder URL
      return '';
    }

    return profileImageUrl;
  }


  Future<void> _handleSharePost(BuildContext context, UnifiedPost post) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Check if user is subscribed
      bool isSubscribed = await _templateService.isUserSubscribed();

      // Debug print profile image URLs
      print("User Profile Image URL from HomeScreen: $profileImageUrl");
      print("User Profile Image URL from Post: ${post.userProfileUrl}");

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Convert post to QuoteTemplate for compatibility with existing sharing functionality
      QuoteTemplate template = post.toQuoteTemplate();

      // Let's use a profile image URL that we know exists - prefer the HomeScreen's URL
      String effectiveProfileUrl = profileImageUrl.isNotEmpty
          ? profileImageUrl
          : (post.userProfileUrl.isNotEmpty ? post.userProfileUrl : '');

      // Navigate to TemplateSharingPage which handles different sharing options
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateSharingPage(
            template: template,
            userName: userName.isNotEmpty ? userName : post.userName,
            userProfileImageUrl: effectiveProfileUrl, // Use effective profile URL
            isPaidUser: isSubscribed,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error handling share post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> checkAndShowSurvey() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print("No user logged in, skipping survey check");
        return;
      }

      // Get updated status from Firestore to ensure we have fresh data
      String userEmail = user.email!.replaceAll(".", "_");
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (!userDoc.exists) {
        print("User document doesn't exist");
        return;
      }

      // Fetch the latest values
      final userData = userDoc.data() as Map<String, dynamic>;
      int appOpenCount = userData['appOpenCount'] ?? 0;
      int lastSurveyAppOpenCount = userData['lastSurveyAppOpenCount'] ?? 0;
      int lastAnsweredQuestionIndex =
          userData['lastAnsweredQuestionIndex'] ?? -1;

      print(
          "Current state - appOpenCount: $appOpenCount, lastSurveyAppOpenCount: $lastSurveyAppOpenCount, lastAnsweredQuestionIndex: $lastAnsweredQuestionIndex");

      // Then show survey dialog if needed
      await UserSurveyManager.showSurveyDialog(context);
    } catch (e) {
      print("Error checking for survey: $e");
    }
  }

  Future<void> _fetchFestivalPosts() async {
    setState(() {
      _loadingFestivals = true;
    });

    try {
      // Use the FestivalService to fetch festival posts
      final festivals = await _festivalService.fetchRecentFestivalPosts();

      if (mounted) {
        setState(() {
          // Convert festivals to festival posts
          _festivalPosts = [];
          for (var festival in festivals) {
            _festivalPosts.addAll(FestivalPost.multipleFromFestival(festival));
          }
          _loadingFestivals = false;
        });
      }
    } catch (e) {
      print("Error loading festival posts: $e");
      if (mounted) {
        setState(() {
          _loadingFestivals = false;
        });
      }
    }
  }


  // Fixed handlers with correct QuoteTemplate properties

  // Correct handlers using the actual properties from FestivalPost and TimeOfDayPost classes

  void _handleFestivalPostSelection(FestivalPost festival) {
    FestivalHandler.handleFestivalSelection(
      context,
      festival,
          (selectedFestival) {
        // Create a QuoteTemplate with properties from FestivalPost
        final template = QuoteTemplate(
          id: selectedFestival.id,
          imageUrl: selectedFestival.imageUrl,
          title: selectedFestival.name, // FestivalPost has 'name' instead of 'title'
          category: selectedFestival.category,
          isPaid: selectedFestival.isPaid,
          createdAt: selectedFestival.createdAt,
          festivalId: null, // Optional in QuoteTemplate
          festivalName: selectedFestival.name, // Use name as festivalName
          avgRating: selectedFestival.avgRating,
          ratingCount: selectedFestival.ratingCount,
          language: null, // Optional in QuoteTemplate
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              template: template,
              isPaidUser: true, // They already passed the festival selection check
            ),
          ),
        );
      },
    );
  }

// Correct implementation for TimeOfDayPost
  void _handleTimeOfDayPostSelection(TimeOfDayPost post) {
    TimeOfDayHandler.handleTimeOfDayPostSelection(
      context,
      post,
          (selectedPost) {
        // Create a QuoteTemplate with properties from TimeOfDayPost
        final template = QuoteTemplate(
          id: selectedPost.id,
          imageUrl: selectedPost.imageUrl,
          title: selectedPost.title, // TimeOfDayPost has 'title'
          category: "", // TimeOfDayPost doesn't have category field, use empty string
          isPaid: selectedPost.isPaid,
          createdAt: selectedPost.createdAt.toDate(), // Convert Timestamp to DateTime
          festivalId: null, // Optional in QuoteTemplate
          festivalName: null, // Optional in QuoteTemplate
          avgRating: selectedPost.avgRating,
          ratingCount: selectedPost.ratingCount,
          language: null, // Optional in QuoteTemplate
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              template: template,
              isPaidUser: true, // They already passed the time of day selection check
            ),
          ),
        );
      },
    );
  }

// Add this method to build festival cards
  Widget _buildFestivalCard(FestivalPost festival) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () => _handleFestivalPostSelection(festival),
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade300,
              blurRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Festival image
              CachedNetworkImage(
                imageUrl: festival.imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 300, // Constrain memory cache size
                memCacheWidth: 300,
                height: double.infinity,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.error),
                ),
              ),

              // Premium badge if needed
              if (festival.isPaid)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 16,
                      height: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),

              // User info container at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    children: [
                      // User profile image
                      Container(
                        width: 18,
                        height: 18,
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: profileImageUrl.isNotEmpty
                              ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),

                      // User name (current user's name)
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationsSheet(),
    );
  }

  // Helper method to build tab buttons
  // Widget _buildTabButton(String title) {
  //   return Container(
  //     height: 30,
  //     decoration: BoxDecoration(
  //     //   //color: isActive ? Colors.blue : Colors.blue.shade400,
  //     border: Border(
  //        bottom: BorderSide(
  //     //       //color: isActive ? Colors.white : Colors.transparent,
  //        width: 1,
  //         ),
  //       ),
  //     ),
  //     child: Center(
  //       child: Text(
  //         title,
  //         style: GoogleFonts.poppins(
  //           color: Colors.white,
  //           fontSize: 16,
  //           //fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Helper method to build category items - fixed to prevent overflow
  Widget categoryCard(String svgAssetPath, String title, Color color, bool isDarkMode) {
    return TapEffectWidget(
      scaleEffect: 0.85,
      opacityEffect: 0.99,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: title,
              categoryColor: color,
              categorySvgPath: svgAssetPath,
            ),
          ),
        );
      },
      child: Container(
        width: 80, // Fixed width to prevent overflow
        margin: EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgAssetPath,
                  width: 40,
                  height: 40,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextColor(isDarkMode),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              context.loc.quotes,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.getTextColor(isDarkMode),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCardWithDownload(QuoteTemplate template) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () async {
        bool isSubscribed = await _templateService.isUserSubscribed();
        if (!template.isPaid || isSubscribed) {
          await RecentTemplateService.addRecentTemplate(template);

          // Navigate to DetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(
                template: template,
                isPaidUser: isSubscribed,
              ),
            ),
          );
        } else {
          SubscriptionPopup.show(context);
        }
      },
      // Add a long press action to open sharing options
      onLongPress: () async {
        // Check if user is subscribed
        bool isSubscribed = await _templateService.isUserSubscribed();

        // Navigate to TemplateSharingPage directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateSharingPage(
              template: template,
              userName: userName,
              userProfileImageUrl: profileImageUrl,
              isPaidUser: isSubscribed,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade300,
              blurRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Template image
              CachedNetworkImage(
                imageUrl: template.imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 300, // Constrain memory cache size
                memCacheWidth: 300,
                height: double.infinity,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.error),
                ),
              ),

              // Premium badge if needed
              if (template.isPaid)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 16,
                      height: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),

              // Download button overlay
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: () => _downloadImage(context, template.imageUrl, template.title),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/download_home.svg',
                      width: 16,
                      height: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // User info container at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    children: [
                      // User profile image
                      Container(
                        width: 18,
                        height: 18,
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: profileImageUrl.isNotEmpty
                              ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),

                      // User name (current user's name)
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Add a small share button
                      GestureDetector(
                        onTap: () async {
                          // Check if user is subscribed
                          bool isSubscribed = await _templateService.isUserSubscribed();

                          // Navigate to TemplateSharingPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemplateSharingPage(
                                template: template,
                                userName: userName,
                                userProfileImageUrl: profileImageUrl,
                                isPaidUser: isSubscribed,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHorizontalSection(String sectionType) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    switch (sectionType) {
      case 'trending_section':
      // TRENDING SECTION - Show template posts
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.trendingQuotes,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to trending templates
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemplatesListScreen(
                            title: context.loc.trendingQuotes,
                            listType: TemplateListType.trending,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      context.loc.viewall,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize - 2,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: FutureBuilder<List<QuoteTemplate>>(
                // This uses the template service for trending templates
                future: _templateService.fetchRecentTemplates(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No trending quotes available',
                        style: GoogleFonts.poppins(
                          fontSize: fontSize - 2,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final template = snapshot.data![index];
                      return _buildTemplateCardWithDownload(template); // Use the new card with download button
                    },
                  );
                },
              ),
            ),
          ],
        );

      case 'new_templates_section':
      // NEW TEMPLATES SECTION - Show festival posts
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.newtemplate,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to festival section
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemplatesListScreen(
                            title: context.loc.newtemplate,
                            listType: TemplateListType.festival,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      context.loc.viewall,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize - 2,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              // Use cached festival posts or show loading indicator
              child: _loadingFestivals
                  ? Center(child: CircularProgressIndicator())
                  : _festivalPosts.isEmpty
                  ? Center(
                child: Text(
                  'No new festival templates available',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemCount: _festivalPosts.length,
                itemBuilder: (context, index) {
                  final festivalPost = _festivalPosts[index];
                  return _buildFestivalCard(festivalPost);
                },
              ),
            ),
          ],
        );

      // case 'for_you_section':
      // // FOR YOU SECTION - Show time of day posts
      //   return Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      //         child: Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             Text(
      //               context.loc.foryou,
      //               style: GoogleFonts.poppins(
      //                 fontSize: fontSize,
      //                 fontWeight: FontWeight.w600,
      //                 color: AppColors.getTextColor(isDarkMode),
      //               ),
      //             ),
      //             TextButton(
      //               onPressed: () {
      //                 // Navigate to time of day section
      //                 Navigator.push(
      //                   context,
      //                   MaterialPageRoute(
      //                     builder: (context) => TemplatesListScreen(
      //                       title: context.loc.foryou,
      //                       listType: TemplateListType.timeOfDay,
      //                     ),
      //                   ),
      //                 );
      //               },
      //               child: Text(
      //                 context.loc.viewall,
      //                 style: GoogleFonts.poppins(
      //                   fontSize: fontSize - 2,
      //                   color: Colors.blue,
      //                   fontWeight: FontWeight.w500,
      //                 ),
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
      //       SizedBox(
      //         height: 150,
      //         child: FutureBuilder<List<TimeOfDayPost>>(
      //           // This uses the time of day service specifically for this section
      //           future: TimeOfDayService().fetchTimeOfDayPosts(),
      //           builder: (context, snapshot) {
      //             if (snapshot.connectionState == ConnectionState.waiting) {
      //               return Center(child: CircularProgressIndicator());
      //             }
      //             if (!snapshot.hasData || snapshot.data!.isEmpty) {
      //               return Center(
      //                 child: Text(
      //                   'No personalized posts available',
      //                   style: GoogleFonts.poppins(
      //                     fontSize: fontSize - 2,
      //                     color: AppColors.getTextColor(isDarkMode),
      //                   ),
      //                 ),
      //               );
      //             }
      //
      //             return ListView.builder(
      //               scrollDirection: Axis.horizontal,
      //               padding: EdgeInsets.symmetric(horizontal: 8),
      //               itemCount: snapshot.data!.length,
      //               itemBuilder: (context, index) {
      //                 final post = snapshot.data![index];
      //                 return _buildTOTDCard(post);
      //               },
      //             );
      //           },
      //         ),
      //       ),
      //     ],
      //   );

      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildTemplateCard(QuoteTemplate template) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () async {
        bool isSubscribed = await _templateService.isUserSubscribed();
        if (!template.isPaid || isSubscribed) {
          await RecentTemplateService.addRecentTemplate(template);

          // Navigate to DetailsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(
                template: template,
                isPaidUser: isSubscribed,
              ),
            ),
          );
        } else {
          SubscriptionPopup.show(context);
        }
      },
      // Add a long press action to open sharing options
      onLongPress: () async {
        // Check if user is subscribed
        bool isSubscribed = await _templateService.isUserSubscribed();

        // Navigate to TemplateSharingPage directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateSharingPage(
              template: template,
              userName: userName,
              userProfileImageUrl: profileImageUrl,
              isPaidUser: isSubscribed,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade300,
              blurRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Template image
              CachedNetworkImage(
                imageUrl: template.imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 300, // Constrain memory cache size
                memCacheWidth: 300,
                height: double.infinity,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.error),
                ),
              ),

              // Premium badge if needed
              if (template.isPaid)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 16,
                      height: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),

              // User info container at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    children: [
                      // User profile image
                      Container(
                        width: 18,
                        height: 18,
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: profileImageUrl.isNotEmpty
                              ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),

                      // User name (current user's name)
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Add a small share button
                      GestureDetector(
                        onTap: () async {
                          // Check if user is subscribed
                          bool isSubscribed = await _templateService.isUserSubscribed();

                          // Navigate to TemplateSharingPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemplateSharingPage(
                                template: template,
                                userName: userName,
                                userProfileImageUrl: profileImageUrl,
                                isPaidUser: isSubscribed,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          // child: Icon(
                          //   Icons.share,
                          //   color: Colors.white,
                          //   size: 12,
                          // ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Helper method to build TOTD cards for horizontal sections
  Widget _buildTOTDCard(TimeOfDayPost post) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () {
        // Handle TOTD post selection
        _handleTimeOfDayPostSelection(post);
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.shade300,
              blurRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // TOTD image
              CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 300, // Constrain memory cache size
                memCacheWidth: 300,
                height: double.infinity,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(Icons.error),
                ),
              ),

              // Premium badge if needed
              if (post.isPaid)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 16,
                      height: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),

              // User info container at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Row(
                    children: [
                      // User profile image
                      Container(
                        width: 18,
                        height: 18,
                        margin: EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: profileImageUrl.isNotEmpty
                              ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),

                      // User name (current user's name)
                      Expanded(
                        child: Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      // Use shorter app bar with just the essential top UI elements
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Reduced height, only top elements
        child: Container(
          color: AppColors.getBackgroundColor(isDarkMode),
          child: SafeArea(
            child: Column(
              children: [
                // Top section with user profile, logo, and notifications
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User profile with name
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileScreen()),
                              );
                            },
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              child: profileImageUrl.isNotEmpty
                                  ? ClipOval(
                                child: Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
                                    'assets/icons/user_profile_new.svg',
                                    width: 25,
                                    height: 25,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              )
                                  : SvgPicture.asset(
                                'assets/icons/user_profile_new.svg',
                                width: 25,
                                height: 25,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            userName, // Use actual username here
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getTextColor(isDarkMode),
                            ),
                          ),
                        ],
                      ),

                      // Right side with Vaky logo and notifications
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => VakyPlus()),
                              );
                            },
                            child: SvgPicture.asset(
                              "assets/icons/vaky_plus_wobg.svg", // Use your Vaky logo here
                              width: 50,
                              height: 50,
                            ),
                          ),
                          SizedBox(width: 16),
                          InkWell(
                            onTap: showNotificationsSheet,
                            borderRadius: BorderRadius.circular(8),
                            child: SvgPicture.asset(
                              'assets/icons/notification_3002272.svg',
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                AppColors.getTextColor(isDarkMode),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryBlue,
        ),
      )
          : RefreshIndicator(
        color: AppColors.primaryBlue,
        onRefresh: _handleRefresh,
        child: _feedItems.isEmpty
            ? Center(
          child: Text(
            'No content available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
        )
            : ListView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 80),
          children: [
            // Search bar with calendar button - MOVED HERE FROM APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                        decoration: InputDecoration(
                          hintText: context.loc.searchquotes,
                          hintStyle: GoogleFonts.poppins(
                            fontSize: fontSize,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/icons/search_button.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // New filter icon
                              IconButton(
                                icon: _isListening
                                    ? SvgPicture.asset(
                                  'assets/icons/microphone open.svg',
                                  width: 20,
                                  height: 34,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.primaryBlue,
                                    BlendMode.srcIn,
                                  ),
                                )
                                    : SvgPicture.asset(
                                  'assets/icons/microphone close.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onPressed: _toggleListening,
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),

                  // Calendar button
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/calendar.svg',
                        height: 24,
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          AppColors.getIconColor(isDarkMode),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> CalendarScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10,),

            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 10),
                    child: Text(
                      context.loc.categories,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                  ),
                  // Horizontal scrollable categories
                  Container(
                    height: 135, // Reduced height to avoid overflow
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        categoryCard(
                            'assets/icons/motivation.svg',
                            context.loc.motivational,
                            Colors.green,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/love.svg',
                            context.loc.love,
                            Colors.red,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/funny.svg',
                            context.loc.funny,
                            Colors.orange,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/friendship.svg',
                            context.loc.friendship,
                            const Color(0xFF9E4282),
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/sad.svg',
                            context.loc.sad,
                            const Color(0xFFAADA0D),
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/Patriotic_1.svg',
                            context.loc.patriotic,
                            const Color(0xFF000088),
                            isDarkMode
                        ),
                        // Additional categories can be added here
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content feed
            // Main content feed
            ...List.generate(_feedItems.length, (index) {
              final item = _feedItems[index];

              // Handle different types of feed items
              if (item is UnifiedPost) {
                // Render post card for UnifiedPost with user info from the UnifiedPost object
                return PostCard(
                    post: item,
                    onEditPressed: () => _handleEditPost(item),
                    onSharePressed: () => _handleSharePost(context, item),
                    onRatingChanged: (post) {
                      // Handle rating change - update UI
                      setState(() {
                        // Update the post in _feedItems
                        final int itemIndex = _feedItems.indexWhere(
                              (p) => p is UnifiedPost && p.id == post.id,
                        );
                        if (itemIndex != -1) {
                          _feedItems[itemIndex] = post;
                        }
                      });
                    },
                    userName: item.userName.isNotEmpty ? item.userName : userName,
                    userProfileUrl: item.userProfileUrl.isNotEmpty ? item.userProfileUrl : getValidProfileImageUrl(),
                    // Add userProfileImageUrl to match TemplateSharingPage parameter
                    userProfileImageUrl: item.userProfileUrl.isNotEmpty ? item.userProfileUrl : getValidProfileImageUrl(),
                  );
              } else if (item is String) {
                // Render horizontal section for section markers
                return _buildHorizontalSection(item);
              }
              // Default case - shouldn't happen
              return SizedBox.shrink();
            }),

            // Loading or end indicator
            if (_hasReachedEnd)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'You\'ve reached the end of content',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
              )
            else
              SizedBox(height: 50), // Space for loading more trigger
          ],
        ),
      ),
    );
  }
}

// Add this extension method if it's not already defined
extension StringExtensions on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}