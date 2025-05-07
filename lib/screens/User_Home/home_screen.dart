import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_card.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_handler.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/screens/Templates/components/template/template_section.dart';
import 'package:mtquotes/screens/User_Home/components/daily_check_in.dart';
import 'package:mtquotes/screens/User_Home/components/Notifications/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:mtquotes/screens/User_Home/vaky_plus.dart';
import 'package:mtquotes/utils/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_service.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_provider.dart';
import '../Templates/components/festivals/festival_card.dart';
import '../Templates/components/recent/recent_section.dart';
import '../Templates/components/recent/recent_service.dart';
import '../Templates/components/template/template_service.dart';
import 'components/Categories/category_screen.dart';
import 'components/Doc Scanner/doc_scanner.dart';
import 'components/app_open_tracker.dart';
import 'components/tapp_effect.dart';
import 'components/templates_list.dart';
import 'components/user_survey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String greetings = "";
  String? qotdImageUrl;
  String? profileImageUrl;
  final TemplateService _templateService = TemplateService();
  final FestivalService _festivalService = FestivalService();
  List<FestivalPost> _festivalPosts = [];
  bool _loadingFestivals = false;

  //totd
  final TimeOfDayService _timeOfDayService = TimeOfDayService();
  List<TimeOfDayPost> _timeOfDayPosts = [];
  bool _loadingTimeOfDay = false;
  String _currentTimeOfDay = '';

  //daily check in impl
  bool isCheckingReward = false;
  bool isLoadingPoints = false;
  bool isLoadingStreak = false;
  int userRewardPoints = 0;
  int checkInStreak = 0;
  List<QuoteTemplate> _recentTemplates = [];
  bool _loadingRecentTemplates = false;

  // Firebase auth for user-specific templates
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for auth state changes
  late Stream<User?> _authStateChanges;

  @override
  void initState() {
    super.initState();
    // Initialize the auth state changes stream
    _authStateChanges = _auth.authStateChanges();

    _fetchUserData();
    _fetchUserDisplayName();
    _fetchQOTDImage();
    _checkUserProfile();
    _fetchFestivalPosts();
    _fetchTimeOfDayPosts();
    // Delay the check slightly to ensure UI is fully rendered
    Future.delayed(const Duration(milliseconds: 1000), () {
      checkDailyReward();
      checkAndShowSurvey();
    });

    // Load initial points
    fetchUserRewardPoints();
    fetchCheckInStreak();
    _fetchRecentTemplates();

    // Listen for auth state changes to reload recent templates when user signs in/out
    _authStateChanges.listen((User? user) {
      print(
          "Auth state changed: User ${user != null ? 'logged in' : 'logged out'}");
      _fetchRecentTemplates(); // Reload recent templates on auth state change
    });
  }

//refresh button
  Future<void> _refreshAllData() async {
    setState(() {
      // Set loading states to true
      _loadingFestivals = true;
      _loadingTimeOfDay = true;
      _loadingRecentTemplates = true;
    });

    // Fetch all data in parallel
    await Future.wait([
      _fetchQOTDImage(),
      _fetchFestivalPosts(),
      _fetchTimeOfDayPosts(),
      _fetchRecentTemplates(),
      fetchUserRewardPoints(),
      fetchCheckInStreak(),
    ]);

    // Update UI
    setState(() {
      _loadingFestivals = false;
      _loadingTimeOfDay = false;
      _loadingRecentTemplates = false;
    });
  }

  //survey
  // Update your HomeScreenState class with this method

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

// Call this method when the user clicks the home button
  void onHomeButtonClicked() async {
    // Increment the app open count
    await UserSurveyManager.incrementAppOpenCount();

    // Check if a survey should be shown
    await checkAndShowSurvey();
  }

  //daily check in
  void checkDailyReward() async {
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

//recent
  Future<void> _fetchRecentTemplates() async {
    print("FETCHING RECENT TEMPLATES!");
    if (mounted) {
      setState(() {
        _loadingRecentTemplates = true;
      });
    }

    try {
      // Check if user is logged in first
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, showing empty recent templates');
        if (mounted) {
          setState(() {
            _recentTemplates = [];
            _loadingRecentTemplates = false;
          });
        }
        return;
      }

      // User is logged in, fetch their specific recent templates from Firestore
      final templates = await RecentTemplateService.getRecentTemplates();

      print(
          'RECENT TEMPLATES: Found ${templates.length} templates for user: ${user.email}');
      for (var template in templates) {
        print('RECENT: ${template.id} - ${template.title}');
      }

      if (mounted) {
        setState(() {
          _recentTemplates = templates;
          _loadingRecentTemplates = false;
        });
      }
    } catch (e) {
      print('Error fetching recent templates: $e');
      if (mounted) {
        setState(() {
          _recentTemplates = [];
          _loadingRecentTemplates = false;
        });
      }
    }
  }

// Override didChangeDependencies to refresh recent templates when returning to the screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRecentTemplates(); // Refresh recent templates
  }

// Add a method to manually refresh recent templates
  void refreshRecentTemplates() {
    _fetchRecentTemplates();
  }

// It's also helpful to make sure HomeScreen is listening for navigation events
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fetchRecentTemplates();
  }

// Add this method to handle template selection
  void _handleRecentTemplateSelection(
    QuoteTemplate template,
  ) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Show loading dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          // decoration: BoxDecoration(
          //   color: AppColors.getBackgroundColor(isDarkMode),
          //   borderRadius: BorderRadius.circular(10),
          //   // boxShadow: [
          //   //   BoxShadow(
          //   //     color: Colors.black.withOpacity(0.2),
          //   //     blurRadius: 10,
          //   //   ),
          //   // ],
          // ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    try {
      // Check if premium template and user is premium
      bool isUserSubscribed = await _templateService.isUserSubscribed();

      // Close loading dialog regardless of outcome
      Navigator.of(context, rootNavigator: true).pop();

      if (!template.isPaid || isUserSubscribed) {
        // Add to recent templates
        await RecentTemplateService.addRecentTemplate(template);

        // Navigate to template editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreen(
              title: template.title,
              templateImageUrl: template.imageUrl,
            ),
          ),
        ).then((_) {
          // Refresh recent templates when returning to this screen
          _fetchRecentTemplates();
        });
      } else {
        // Show subscription popup for premium templates
        SubscriptionPopup.show(context);
      }
    } catch (e) {
      // Close loading dialog in case of error
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error in _handleRecentTemplateSelection: $e');
    }
  }

  //totd
  Future<void> _fetchTimeOfDayPosts() async {
    setState(() {
      _loadingTimeOfDay = true;
      _currentTimeOfDay = _timeOfDayService.getCurrentTimeOfDay();
    });

    try {
      final posts = await _timeOfDayService.fetchTimeOfDayPosts();

      if (mounted) {
        setState(() {
          _timeOfDayPosts = posts;
          _loadingTimeOfDay = false;
        });
      }
    } catch (e) {
      print("Error loading time of day posts: $e");
      if (mounted) {
        setState(() {
          _loadingTimeOfDay = false;
        });
      }
    }
  }

  // finish totd

  // Add this method to handle time of day post selection
  void _handleTimeOfDayPostSelection(TimeOfDayPost post) {
    TimeOfDayHandler.handleTimeOfDayPostSelection(
      context,
      post,
      (selectedPost) {
        // This is the callback that will be executed when access is granted
        print('Access granted to post: ${selectedPost.title}');
        // You can add additional logic here if needed
      },
    );
  }

  // New method to fetch festival posts
  Future<void> _fetchFestivalPosts() async {
    setState(() {
      _loadingFestivals = true;
    });

    try {
      final festivals = await _festivalService.fetchRecentFestivalPosts();

      if (mounted) {
        setState(() {
          // Use the new method to create multiple FestivalPosts from each Festival
          _festivalPosts = [];
          for (var festival in festivals) {
            _festivalPosts.addAll(FestivalPost.multipleFromFestival(festival));
          }

          // Debug prints
          for (var post in _festivalPosts) {
            print("Post: ${post.name}, Image URL: ${post.imageUrl}");
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

  void _handleFestivalPostSelection(FestivalPost festival) {
    FestivalHandler.handleFestivalSelection(
      context,
      festival,
      (selectedFestival) {
        // This is what happens when the user gets access to the festival
        // For example, you could navigate to an edit screen:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreen(
              title: 'Edit Festival Post',
              templateImageUrl: selectedFestival.imageUrl,
            ),
          ),
        );
      },
    );
  }

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

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    String emailIdWithUnderscores = user.email!.replaceAll('.', '_');

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(emailIdWithUnderscores)
        .get();

    if (userDoc.exists && mounted) {
      // Add mounted check here
      final data = userDoc.data() as Map<String, dynamic>;

      setState(() {
        userName = data['name'] ?? '';
        profileImageUrl =
            data.containsKey('profileImage') ? data['profileImage'] : null;
        userRewardPoints = data['rewardPoints'] ?? 0;
      });
    }
  }

  // Update your _showUserProfileDialog method with fixes
  void _showUserProfileDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Use dialogContext instead of context for the dialog
        TextEditingController nameController = TextEditingController();
        TextEditingController bioController = TextEditingController();
        File? selectedImage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Rename setState to setDialogState to avoid confusion
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
                    color: Colors.transparent, // Keep background transparent
                    borderRadius:
                        BorderRadius.circular(8), // Adjust the roundness here
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
                            : (profileImageUrl != null &&
                                    profileImageUrl!.isNotEmpty
                                ? NetworkImage(profileImageUrl!)
                                    as ImageProvider
                                : null),
                        child: (selectedImage == null &&
                                (profileImageUrl == null ||
                                    profileImageUrl!.isEmpty))
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
                      // Validate input before proceeding
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text("Name cannot be empty")),
                        );
                        return;
                      }

                      // Store values before closing dialog
                      final String newName = nameController.text;
                      final String newBio = bioController.text;
                      final File? imageToUpload = selectedImage;

                      // First close the dialog to prevent context issues
                      Navigator.pop(dialogContext);

                      // Use a flag to check if we can proceed with UI updates
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

                      // Only fetch data and show success if the main widget is still mounted
                      // and the update completed successfully
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

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

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
    }
  }

  Future<String?> _uploadProfileImage(String uid, File image) async {
    Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _fetchUserDisplayName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String emailIdWithUnderscores = user.email!.replaceAll('.', '_');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(emailIdWithUnderscores)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName =
              userDoc['name'] ?? ''; // Ensure a fallback if 'name' is null
        });
      }
    }
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    bool isSubscribed = await _templateService.isUserSubscribed();

    if (!template.isPaid || isSubscribed) {
      // Add to recent templates before navigating
      await RecentTemplateService.addRecentTemplate(template);

      // Navigate to template editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            title: template.title,
            templateImageUrl: template.imageUrl,
          ),
        ),
      ).then((_) {
        // Refresh recent templates when returning to this screen
        _fetchRecentTemplates();
      });
    } else {
      // Show subscription popup
      SubscriptionPopup.show(context);
    }
  }

  String _getGreeting(BuildContext context) {
    int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return context.loc.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return context.loc.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return context.loc.goodEvening;
    } else {
      return context.loc.goodNight;
    }
  }

  void showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this to make it more flexible in height
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationsSheet(),
    );
  }

  Future<void> _fetchQOTDImage() async {
    String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    print('date fetched');
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('qotd')
          .doc(formattedDate)
          .get();
      print('snapshot taken');
      if (snapshot.exists && snapshot["imageURL"] != null) {
        setState(() {
          qotdImageUrl = snapshot["imageURL"];
        });
        print('image stored');
      }
    } catch (e) {
      print("Error fetching QOTD: $e");
    }
  }

  void shareImage(BuildContext context, String? qotdImageUrl) async {
    if (qotdImageUrl != null && qotdImageUrl.isNotEmpty) {
      try {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        final isDarkMode = themeProvider.isDarkMode;

        // Show loading indicator dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDarkMode),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(height: 15),
                    Text(
                      context.loc.preparingImage,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        final uri = Uri.parse(qotdImageUrl);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/quote_image.jpg';
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Close the loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          ///  Correct way to share files using `share_plus`
          await Share.shareXFiles([XFile(filePath)], text: "Quote of the Day");
        } else {
          // Close the loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.loc.failedToLoadImage)),
          );
          debugPrint("Failed to download image");
        }
      } catch (e) {
        // Close the loading dialog if open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing image: ${e.toString()}")),
        );
        debugPrint("Error: $e");
      }
    } else {
      await Share.share("Check out this amazing quote!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    greetings = _getGreeting(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize; // Get font size

    return WillPopScope(
        onWillPop: () async =>
            false, // Prevents navigating back to the login screen
        child: Scaffold(
            backgroundColor: AppColors.getBackgroundColor(isDarkMode),
            appBar: AppBar(
              toolbarHeight: 65,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.getBackgroundColor(isDarkMode),
              elevation: 0,
              title: Row(
                children: [
                  Material(
                    color: Colors.transparent, // Keep background transparent
                    borderRadius:
                        BorderRadius.circular(8), // Adjust the roundness here
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  profileImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/user_profile_new.svg',
                                width: 24, // Adjust size as needed
                                height: 24, // Adjust size as needed
                                color: Colors.black, // Optional: set color
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    "Hi, $userName\n$greetings",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  //image enhancer icon.
                  Material(
                    color: Colors.transparent, // Keep background transparent
                    // borderRadius:
                    //     BorderRadius.circular(10), // Adjust the roundness here
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VakyPlus()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SvgPicture.asset(
                          "assets/icons/vaky_plus_wobg.svg",
                          width: 25,
                          height: 45,
                          //color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                    ),
                  ),
                  //notifcation icon
                  Material(
                    color: Colors.transparent, // Keep background transparent
                    borderRadius:
                        BorderRadius.circular(8), // Adjust the roundness here
                    child: InkWell(
                      onTap: showNotificationsSheet,
                      borderRadius: BorderRadius.circular(
                          8), // Match this with Material's radius
                      child: Padding(
                        // Optional: add padding for better touch target
                        padding: EdgeInsets.all(4),
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
                    ),
                  )
                ],
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Featured Quote of the Day
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.transparent,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: qotdImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: qotdImageUrl!,
                                          placeholder: (context, url) =>
                                              _buildQotdShimmer(isDarkMode),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Container(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[
                                                  300], // Fallback background with theme support
                                          alignment: Alignment.center,
                                          child: Text(
                                            context
                                                .loc.noQuoteAvailableForToday,
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSize,
                                              color: AppColors.getTextColor(
                                                  isDarkMode), // Ensure text color respects theme
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    // Important for the gradient to fill the button
                                    backgroundColor: Colors.transparent,
                                    // Make the button background transparent
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation:
                                        0, // Optional: Remove the elevation shadow
                                  ),
                                  onPressed: () =>
                                      shareImage(context, qotdImageUrl),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical:
                                              8), // Adjust padding as needed
                                      constraints: BoxConstraints(
                                          minWidth: 88,
                                          minHeight: 36), // Ensure minimum size
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/share.svg',
                                            width: 24,
                                            height: 18,
                                            colorFilter: ColorFilter.mode(
                                              Colors.white,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(context.loc.share,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          //QOTD section Finish
                          //Recent Section starts
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.loc.recents,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextColor(isDarkMode),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed: refreshRecentTemplates,
                                    tooltip: 'Refresh recent templates',
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                height: 150,
                                child: _loadingRecentTemplates
                                    ? _buildRecentTemplatesShimmer(isDarkMode)
                                    : _recentTemplates.isEmpty
                                        ? Center(
                                            child: Text(
                                              context.loc.norecenttemplates,
                                              style: GoogleFonts.poppins(
                                                fontSize: fontSize - 2,
                                                color: AppColors.getTextColor(
                                                    isDarkMode),
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _recentTemplates.length,
                                            itemBuilder: (context, index) {
                                              final template =
                                                  _recentTemplates[index];
                                              return TapEffectWidget(
                                                scaleEffect:
                                                    0.85, // Slightly more pronounced effect
                                                opacityEffect: 0.99,
                                                onTap: () =>
                                                    _handleRecentTemplateSelection(
                                                        template),
                                                child: Container(
                                                  width: 100,
                                                  margin: EdgeInsets.only(
                                                      right: 10),
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode
                                                        ? Colors.grey[800]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: isDarkMode
                                                              ? Colors.black
                                                                  .withOpacity(
                                                                      0.3)
                                                              : Colors.grey
                                                                  .shade300,
                                                          blurRadius: 5)
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        // Image background
                                                        template.imageUrl
                                                                .isNotEmpty
                                                            ? CachedNetworkImage(
                                                                imageUrl: template
                                                                    .imageUrl,
                                                                placeholder: (context,
                                                                        url) =>
                                                                    _buildTemplateImageShimmer(
                                                                        isDarkMode),
                                                                errorWidget:
                                                                    (context,
                                                                        url,
                                                                        error) {
                                                                  print(
                                                                      "Image error: $error for URL: $url");
                                                                  return Container(
                                                                    color: isDarkMode
                                                                        ? Colors.grey[
                                                                            700]
                                                                        : Colors
                                                                            .grey[300],
                                                                    child: Icon(
                                                                        Icons
                                                                            .error,
                                                                        color: isDarkMode
                                                                            ? Colors.grey[500]
                                                                            : Colors.grey[600]),
                                                                  );
                                                                },
                                                                fit: BoxFit
                                                                    .cover,
                                                              )
                                                            : Container(
                                                                color: isDarkMode
                                                                    ? Colors.grey[
                                                                        700]
                                                                    : Colors.grey[
                                                                        200],
                                                                child: Center(
                                                                  child: Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                    color: isDarkMode
                                                                        ? Colors.grey[
                                                                            500]
                                                                        : Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ),

                                                        // Premium indicator
                                                        if (template.isPaid)
                                                          Positioned(
                                                            top: 5,
                                                            right: 5,
                                                            child: Container(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          2,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.7),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                              ),
                                                              child: SvgPicture
                                                                  .asset(
                                                                'assets/icons/premium_1659060.svg',
                                                                width: 24,
                                                                height: 24,
                                                                color: Colors
                                                                    .amber,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                          // recent section ends
                          SizedBox(
                            height: 30,
                          ),
                          // Categories section with View All button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.loc.categories,
                                    style: GoogleFonts.poppins(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextColor(
                                          isDarkMode), // Ensure text color respects theme
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              SizedBox(
                                height: 130,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    categoryCard(
                                        'assets/icons/motivation.svg',
                                        context.loc.motivational,
                                        Colors.green,
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/love.svg',
                                        context.loc.love,
                                        Colors.red,
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/funny.svg',
                                        context.loc.funny,
                                        Colors.orange,
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/friendship.svg',
                                        context.loc.friendship,
                                        const Color(0xFF9E4282),
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/sad.svg',
                                        context.loc.sad,
                                        const Color(0xFFAADA0D),
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/patriotic.svg',
                                        context.loc.patriotic,
                                        const Color(0xFF000088),
                                        isDarkMode),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          //category section ends
                          //trending section starts
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.loc.trendingQuotes,
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.getTextColor(
                                            isDarkMode), // Ensure text color respects theme
                                      ),
                                    ),
                                    Material(
                                      color: Colors
                                          .transparent, // Keep background transparent
                                      borderRadius: BorderRadius.circular(
                                          8), // Adjust the roundness here
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TemplatesListScreen(
                                                title:
                                                    context.loc.trendingQuotes,
                                                listType:
                                                    TemplateListType.trending,
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
                                    )
                                  ],
                                ),
                                TemplateSection(
                                  title: '',
                                  fetchTemplates:
                                      _templateService.fetchRecentTemplates,
                                  fontSize: fontSize,
                                  onTemplateSelected: _handleTemplateSelection,
                                  isDarkMode: isDarkMode,
                                ),
                                SizedBox(height: 20),
                                //trending ends
                                //festival starts
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            context.loc.newtemplate,
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.getTextColor(
                                                  isDarkMode), // Ensure text color respects theme
                                            ),
                                          ),
                                          Material(
                                            color: Colors
                                                .transparent, // Keep background transparent
                                            borderRadius: BorderRadius.circular(
                                                8), // Adjust the roundness here
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        TemplatesListScreen(
                                                      title: context
                                                          .loc.newtemplate,
                                                      listType: TemplateListType
                                                          .festival,
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
                                          )
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      SizedBox(
                                        height: 150,
                                        child: _loadingFestivals
                                            ? ShimmerHorizontalList(
                                                itemCount: 5,
                                                itemWidth: 100,
                                                itemHeight: 120,
                                                isDarkMode: isDarkMode,
                                                type: ShimmerType.festival,
                                              )
                                            : _festivalPosts.isEmpty
                                                ? Center(
                                                    child: Text(
                                                      context.loc
                                                          .noFestivalsAvailable,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .getTextColor(
                                                                isDarkMode),
                                                      ),
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        _festivalPosts.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return FestivalCard(
                                                        festival:
                                                            _festivalPosts[
                                                                index],
                                                        fontSize: fontSize,
                                                        onTap: () =>
                                                            _handleFestivalPostSelection(
                                                                _festivalPosts[
                                                                    index]),
                                                      );
                                                    },
                                                  ),
                                      ),
                                      SizedBox(height: 30),
                                      //festival ends
                                      //foryou starts
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Left side with title and time
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      context.loc.foryou,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .getTextColor(
                                                                isDarkMode),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "• ${_currentTimeOfDay.capitalize()}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Right side with View All
                                              Material(
                                                color: Colors
                                                    .transparent, // Keep background transparent
                                                borderRadius: BorderRadius.circular(
                                                    8), // Adjust the roundness here
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            TemplatesListScreen(
                                                          title:
                                                              "${context.loc.foryou} • ${_currentTimeOfDay.capitalize()}",
                                                          listType:
                                                              TemplateListType
                                                                  .timeOfDay,
                                                          timeOfDay:
                                                              _currentTimeOfDay,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    context.loc.viewall,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: fontSize - 2,
                                                      color: Colors.blue,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          SizedBox(
                                            height: 150,
                                            child: _loadingTimeOfDay
                                                ? ShimmerHorizontalList(
                                                    itemCount: 5,
                                                    itemWidth: 120,
                                                    itemHeight: 150,
                                                    isDarkMode: isDarkMode,
                                                    type: ShimmerType
                                                        .template, // Assuming this is similar to templates in style
                                                  )
                                                : _timeOfDayPosts.isEmpty
                                                    ? Center(
                                                        child: Text(
                                                          "No templates available for $_currentTimeOfDay",
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize:
                                                                      fontSize -
                                                                          2),
                                                        ),
                                                      )
                                                    : ListView.builder(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            _timeOfDayPosts
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return TimeOfDayPostComponent(
                                                            post:
                                                                _timeOfDayPosts[
                                                                    index],
                                                            fontSize: fontSize,
                                                            onTap: () =>
                                                                _handleTimeOfDayPostSelection(
                                                                    _timeOfDayPosts[
                                                                        index]),
                                                          );
                                                        },
                                                      ),
                                          ),
                                        ],
                                      ),
                                    ]),
                              ]),
                        ]),
                  )),
            )));
  }

  Widget _buildRecentTemplatesSection() {
    return RecentTemplatesSection(
      recentTemplates: _recentTemplates,
      onTemplateSelected: _handleRecentTemplateSelection,
      isLoading: _loadingRecentTemplates,
    );
  }

  Widget quoteCard(String text, double fontSize) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: fontSize - 2)),
      ),
    );
  }

  Widget festivalPostCard(FestivalPost festival, double fontSize) {
    return GestureDetector(
      onTap: () => _handleFestivalPostSelection(festival),
      child: Container(
        width: 100,
        // Match other cards width
        height: 80,
        // Match other cards height
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              festival.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: festival.imageUrl,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) {
                        print("Image loading error: $error for URL: $url");
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.error),
                        );
                      },
                      fit: BoxFit.cover,
                      cacheKey: "${festival.id}_image",
                      maxHeightDiskCache: 500,
                      maxWidthDiskCache: 500,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
              if (festival.isPaid)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 24,
                      height: 24,
                      color: Colors.amber,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the categoryCard function in your HomeScreen class
  Widget categoryCard(
      String svgAssetPath, String title, Color color, bool isDarkMode) {
    return TapEffectWidget(
      scaleEffect: 0.85, // Slightly more pronounced effect
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
      child: Padding(
        padding: EdgeInsets.only(right: 12),
        child: Column(
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
            SizedBox(
              height: 5,
            ),
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                Text(
                  context.loc.quotes,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //shimmer widgets starts
  Widget _buildQotdShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
      ),
    );
  }

  // Add this widget function to your class
  Widget _buildRecentTemplatesShimmer(bool isDarkMode) {
    return SizedBox(
      height: 150,
      child: Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5, // Show 5 shimmer placeholders
          itemBuilder: (context, index) {
            return Container(
              width: 100,
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
      ),
    );
  }

// Single template image shimmer
  Widget _buildTemplateImageShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          width: 100,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ));
  }
}

class FontSizeProvider with ChangeNotifier {
  double _fontSize = 14.0;

  double get fontSize => _fontSize;

  void setFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
