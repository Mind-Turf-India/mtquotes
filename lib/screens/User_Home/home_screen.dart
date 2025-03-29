import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_service.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';
import '../Templates/components/festivals/festival_card.dart';
import '../Templates/components/recent/recent_section.dart';
import '../Templates/components/recent/recent_service.dart';
import '../Templates/components/template/template_service.dart';
import 'components/Categories/category_screen.dart';
import 'components/templates_list.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    });

    // Load initial points
    fetchUserRewardPoints();
    fetchCheckInStreak();
    _fetchRecentTemplates();

    // Listen for auth state changes to reload recent templates when user signs in/out
    _authStateChanges.listen((User? user) {
      print("Auth state changed: User ${user != null ? 'logged in' : 'logged out'}");
      _fetchRecentTemplates(); // Reload recent templates on auth state change
    });
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

      print('RECENT TEMPLATES: Found ${templates.length} templates for user: ${user.email}');
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
  void _handleRecentTemplateSelection(QuoteTemplate template) async {
    try {
      // Check if premium template and user is premium
      bool isUserSubscribed = await _templateService.isUserSubscribed();

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Use dialogContext instead of context for the dialog
        TextEditingController nameController = TextEditingController();
        TextEditingController bioController = TextEditingController();
        File? _selectedImage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Rename setState to setDialogState to avoid confusion
            return AlertDialog(
              title: Text("Complete Your Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedImage = await _pickImage();
                      if (pickedImage != null) {
                        setDialogState(() {
                          _selectedImage = pickedImage;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (profileImageUrl != null &&
                          profileImageUrl!.isNotEmpty
                          ? NetworkImage(profileImageUrl!) as ImageProvider
                          : null),
                      child: (_selectedImage == null &&
                          (profileImageUrl == null ||
                              profileImageUrl!.isEmpty))
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
                      final File? imageToUpload = _selectedImage;

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
                          const SnackBar(
                              content: Text("Profile updated successfully")),
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
            'profile_pictures/${userEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg')
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
    FirebaseStorage.instance.ref().child('profile_pictures/$uid.jpg');
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

  void shareImage(String? qotdImageUrl) async {
    if (qotdImageUrl != null && qotdImageUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(qotdImageUrl);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/quote_image.jpg';
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          /// ✅ Correct way to share files using `share_plus`
          await Share.shareXFiles([XFile(filePath)], text: "Quote of the Day");
        } else {
          debugPrint("Failed to download image");
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    } else {
      await Share.share("Check out this amazing quote!");
    }
  }

  @override
  Widget build(BuildContext context) {
    greetings = _getGreeting(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize; // Get font size

    return WillPopScope(
        onWillPop: () async =>
            false, // Prevents navigating back to the login screen
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child:
                            profileImageUrl == null || profileImageUrl!.isEmpty
                                ? Icon(LucideIcons.user, color: Colors.black)
                                : null,
                      )),
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
                  GestureDetector(
                    onTap: showNotificationsSheet,
                    child: Icon(
                      LucideIcons.bellRing,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
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
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Container(
                                    color:
                                        Colors.grey[300], // Fallback background
                                    alignment: Alignment.center,
                                    child: Text(
                                      "No quote available today",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 35,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => shareImage(qotdImageUrl),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share, color: Colors.white),
                                SizedBox(width: 6),
                                Text("Share",
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.loc.recents,
                              style: GoogleFonts.poppins(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold),
                            ),
                            // Optional: Add a refresh button for testing
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
                              ? Center(child: CircularProgressIndicator())
                              : _recentTemplates.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No recent templates",
                                        style: GoogleFonts.poppins(
                                            fontSize: fontSize - 2),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _recentTemplates.length,
                                      itemBuilder: (context, index) {
                                        final template =
                                            _recentTemplates[index];
                                        return GestureDetector(
                                          onTap: () =>
                                              _handleRecentTemplateSelection(
                                                  template),
                                          child: Container(
                                            width: 100,
                                            
                                            margin: EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey.shade300,
                                                    blurRadius: 5)
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                                 
                                              child: Stack(
                                                fit: StackFit.expand,
                                                
                                                children: [
                                                  // Image background
                                                  template.imageUrl.isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl:
                                                              template.imageUrl,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2),
                                                          ),
                                                          errorWidget: (context,
                                                              url, error) {
                                                            print(
                                                                "Image error: $error for URL: $url");
                                                            return Container(
                                                              color: Colors
                                                                  .grey[300],
                                                              child: Icon(
                                                                  Icons.error),
                                                            );
                                                          },
                                                          fit: BoxFit.cover,
                                                          
                                                        )
                                                      : Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: Center(
                                                            child: Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color: Colors
                                                                    .grey),
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
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.lock,
                                                                color: Colors
                                                                    .amber,
                                                                size: 12),
                                                            SizedBox(width: 2),
                                                            Text(
                                                              'PRO',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                  // // Template title
                                                  // Positioned(
                                                  //   bottom: 0,
                                                  //   left: 0,
                                                  //   right: 0,
                                                  //   child: Container(
                                                  //     padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                                  //     color: Colors.black.withOpacity(0.5),
                                                  //     child: Text(
                                                  //       template.title.isNotEmpty
                                                  //           ? template.title
                                                  //           : "Template",
                                                  //       style: GoogleFonts.poppins(
                                                  //         color: Colors.white,
                                                  //         fontSize: fontSize - 4,
                                                  //         fontWeight: FontWeight.w500,
                                                  //       ),
                                                  //       overflow: TextOverflow.ellipsis,
                                                  //       maxLines: 1,
                                                  //       textAlign: TextAlign.center,
                                                  //     ),
                                                  //   ),
                                                  // ),
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
                    SizedBox(
                      height: 30,
                    ),
// Categories section with View All button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.loc.categories,
                              style: GoogleFonts.poppins(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              categoryCard(
                                  Icons.lightbulb,
                                  context.loc.motivational,
                                  Colors.green,
                                  ),
                              categoryCard(Icons.favorite, context.loc.love,
                                  Colors.red, ),
                              categoryCard(Icons.emoji_emotions,
                                  context.loc.funny, Colors.orange, ),
                              categoryCard(Icons.people, context.loc.friendship,
                                  Colors.blue, ),
                              categoryCard(Icons.self_improvement,
                                  context.loc.life, Colors.purple, ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.loc.trendingQuotes,
                                style: GoogleFonts.poppins(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () {
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
                                  'View All',
                                  style: GoogleFonts.poppins(
                                    fontSize: fontSize - 2,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TemplateSection(
                            title: '',
                            fetchTemplates:
                                _templateService.fetchRecentTemplates,
                            fontSize: fontSize,
                            onTemplateSelected: _handleTemplateSelection,
                          ),
                          SizedBox(height: 20),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.loc.newtemplate,
                                      style: GoogleFonts.poppins(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TemplatesListScreen(
                                              title: context.loc.newtemplate,
                                              listType:
                                                  TemplateListType.festival,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'View All',
                                        style: GoogleFonts.poppins(
                                          fontSize: fontSize - 2,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  height:
                                      150, // Changed from 200 to 100 to match other card sections
                                  child: _loadingFestivals
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : _festivalPosts.isEmpty
                                          ? Center(
                                              child: Text(
                                                "No festival posts available",
                                                style: GoogleFonts.poppins(
                                                    fontSize: fontSize - 2),
                                              ),
                                            )
                                          : ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _festivalPosts.length,
                                              itemBuilder: (context, index) {
                                                return FestivalCard(
                                                  festival:
                                                      _festivalPosts[index],
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                style: GoogleFonts.poppins(
                                                    fontSize: fontSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "• ${_currentTimeOfDay.capitalize()}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Right side with View All
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TemplatesListScreen(
                                                  title:
                                                      "${context.loc.foryou} • ${_currentTimeOfDay.capitalize()}",
                                                  listType: TemplateListType
                                                      .timeOfDay,
                                                  timeOfDay: _currentTimeOfDay,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'View All',
                                            style: GoogleFonts.poppins(
                                              fontSize: fontSize - 2,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      height: 150,
                                      // width: 0,
                                      child: _loadingTimeOfDay
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : _timeOfDayPosts.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    "No templates available for ${_currentTimeOfDay}",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: fontSize - 2),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount:
                                                      _timeOfDayPosts.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return TimeOfDayPostComponent(
                                                      post: _timeOfDayPosts[
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
            ))));
  }

  Widget buildCategoriesSection(BuildContext context, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.loc.categories,
              style: GoogleFonts.poppins(
                  fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              categoryCard(
                  Icons.lightbulb, context.loc.motivational, Colors.green),
              categoryCard(Icons.favorite, context.loc.love, Colors.red),
              categoryCard(
                  Icons.emoji_emotions, context.loc.funny, Colors.orange),
              categoryCard(Icons.people, context.loc.friendship, Colors.blue),
              categoryCard(
                  Icons.self_improvement, context.loc.life, Colors.purple),
            ],
          ),
        ),
      ],
    );
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
        width: 100, // Match other cards width
        height: 80, // Match other cards height
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
                      cacheKey: festival.id + "_image",
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
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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

  // Update the categoryCard function in your HomeScreen class
  Widget categoryCard(
      IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: title,
              categoryColor: color,
              categoryIcon: icon,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(
              height: 5,
              width: 10,
            ),
            Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                 fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
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
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
