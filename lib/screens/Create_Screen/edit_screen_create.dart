import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:mtquotes/screens/Create_Screen/components/drafts_service.dart';
import 'package:mtquotes/screens/Create_Screen/components/imageEditDraft.dart';
import '../../utils/app_colors.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_service.dart';
import '../Templates/components/template/template_sharing.dart';
import '../User_Home/files_screen.dart';

class EditScreen extends StatefulWidget {
  EditScreen({
    Key? key,
    required this.title,
    this.templateImageUrl,
    this.initialImageData,
    // this.draftId, // Add draftId parameter
  }) : super(key: key);

  final String title;
  final String? templateImageUrl;
  final Uint8List? initialImageData;

  // final String? draftId; // To track if we're editing an existing draft

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Uint8List? imageData;
  final ImagePicker _picker = ImagePicker();
  bool defaultImageLoaded = true;
  bool isLoading = false;
  final uuid = Uuid();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // final DraftService _draftService = DraftService();
  // String? currentDraftId; // Track the current draft ID
  String? originalImagePath; // Track the original image path
  bool showInfoBox = true;
  String infoBoxBackground = 'white';
  String userName = '';
  String userLocation = '';
  String userMobile = '';
  String userDescription = '';
  String? userProfileImageUrl;
  bool isBusinessProfile = false;
  String companyName = '';
  bool isPaidUser = false;
  bool isPersonal = true;
  String userSocialMedia = '';

  final GlobalKey imageContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // currentDraftId = widget.draftId;

    if (widget.templateImageUrl != null) {
      loadTemplateImage(widget.templateImageUrl!);
    } else if (widget.initialImageData != null) {
      setState(() {
        imageData = widget.initialImageData;
        defaultImageLoaded = false;
      });
    }
    _loadUserPreferences();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final templateService = TemplateService();
      bool isSubscribed = await templateService.isUserSubscribed();

      setState(() {
        isPaidUser = isSubscribed;
      });
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  // Add this method to load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email != null) {
        String docId = currentUser!.email!.replaceAll('.', '_');

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;

          setState(() {
            showInfoBox = userData['showInfoBox'] ?? true;
            infoBoxBackground = userData['infoBoxBackground'] ?? 'white';
            userName = userData['name'] ?? '';
            userLocation = userData['location'] ?? '';
            userMobile = userData['mobile'] ?? '';
            userDescription = userData['description'] ?? '';
            userSocialMedia =
                userData['socialMedia'] ?? ''; // Load social media handle
            userProfileImageUrl = userData['profileImage'];
            companyName = userData['companyName'] ?? '';

            // Determine if using business profile based on which tab was last active
            isBusinessProfile = userData['lastActiveProfileTab'] == 'business';
            isPersonal = userData['lastActiveProfileTab'] == 'personal';
          });
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  // Get user-specific directory path for downloads
  Future<String> _getUserSpecificDirectoryPath() async {
    // Check if user is logged in
    User? user = _auth.currentUser;
    String userDir = user != null ? _sanitizeEmail(user.email!) : 'guest';

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

  // Sanitize email for directory name (replace dots with underscores)
  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

  Widget _buildInfoBox() {
    if (!showInfoBox) return SizedBox();

    // Get theme-aware colors for info box
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    switch (infoBoxBackground) {
      case 'lightGray':
        bgColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
        break;
      case 'lightBlue':
        bgColor = isDarkMode ? Colors.blue[900]! : Colors.blue[100]!;
        break;
      case 'lightGreen':
        bgColor = isDarkMode ? Colors.green[900]! : Colors.green[100]!;
        break;
      case 'white':
      default:
        bgColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    }

    // Get text color based on theme
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDarkMode ? AppColors.darkText : AppColors.lightText);
    final secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: isDarkMode ? AppColors.darkDivider : AppColors.lightDivider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image:
              userProfileImageUrl != null && userProfileImageUrl!.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(userProfileImageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            child: userProfileImageUrl == null || userProfileImageUrl!.isEmpty
                ? Icon(
              Icons.person,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
              size: 30,
            )
                : null,
          ),
          SizedBox(width: 12),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPersonal)
                  Text(
                    userName.isNotEmpty ? userName : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                if (isBusinessProfile) // Business profile - show both name and company
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company name first for business cards
                      Text(
                        companyName.isNotEmpty ? companyName : 'Company Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      // Then person's name
                      Text(
                        userName.isNotEmpty ? userName : 'Your Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                if (userLocation.isNotEmpty)
                  Text(
                    userLocation,
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                if (userMobile.isNotEmpty)
                  Text(
                    userMobile,
                    style: TextStyle(fontSize: 14, color: textColor),
                  ),
                // Only show social media and description for business profile
                if (isBusinessProfile) ...[
                  if (userSocialMedia.isNotEmpty)
                    Text(
                      userSocialMedia,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                    ),
                  if (userDescription.isNotEmpty)
                    Text(
                      userDescription,
                      style: TextStyle(fontSize: 14, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureImageWithInfoBox() async {
    try {
      final RenderRepaintBoundary boundary = imageContainerKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing image with info box: $e');
      return null;
    }
  }

  // In EditScreen class
  Future<void> _captureFullImage() async {
    // First ensure the widget has been rendered
    await Future.delayed(Duration(milliseconds: 500));

    try {
      RenderRepaintBoundary boundary = imageContainerKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Get the image with higher quality
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        setState(() {
          imageData = byteData.buffer.asUint8List();
        });
      }
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image with details')),
      );
    }
  }

  void showNoImageSelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Image Selected'),
          content: Text('Please select an image from gallery first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to show login required dialog
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text(
              'Please sign in to download images. This helps keep your downloads organized.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to show loading indicator
  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  // Helper method to hide loading indicator
  void _hideLoadingIndicator() {
    Navigator.of(context).pop();
  }

  Future<void> loadTemplateImage(String imageUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          imageData = response.bodyBytes;
          defaultImageLoaded = false;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error loading template image: $e');

      if (this.mounted) {
        setState(() {
          isLoading = false;
        });
      }

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading template image")),
        );
      }
    }
  }

  Future<void> shareImage() async {
    // Check if there's an image to share
    if (imageData == null) {
      showNoImageSelectedDialog();
      return;
    }

    _showLoadingIndicator();

    try {
      // Get user's subscription status
      final templateService = TemplateService();
      bool isPaidUser = await templateService.isUserSubscribed();

      Uint8List finalImageData;

      // For paid users with info box, capture the image with the info box
      if (isPaidUser && showInfoBox) {
        // This would capture the entire widget including info box
        finalImageData = await _captureImageWithInfoBox() ?? imageData!;
      } else {
        // For free users or paid users without info box, use the raw image
        finalImageData = imageData!;
      }

      _hideLoadingIndicator();

      // Navigate to template sharing page with the appropriate image data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateSharingPage(
            // Use a timestamp to ensure uniqueness in the key
            key: ValueKey("template_sharing_custom_${DateTime.now().millisecondsSinceEpoch}"),
            template: QuoteTemplate(
              id: 'custom',
              imageUrl: widget.templateImageUrl ?? 'custom_image',
              title: 'Custom Template',
              category: '',
              isPaid: false,
              createdAt: DateTime.now(),
            ),
            userName: userName.isNotEmpty ? userName : 'User',
            userProfileImageUrl: userProfileImageUrl ?? '',
            isPaidUser: isPaidUser,
            // Pass the custom image data to the sharing page
            customImageData: finalImageData,
          ),
        ),
      );
    } catch (e) {
      _hideLoadingIndicator();

      // Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to share image: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    double rating = 0;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate This Content'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How would you rate your experience with this template?'),
                SizedBox(height: 20),
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating ? Colors.amber : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(null);
                },
                child: Text('Skip'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(rating); // Close the dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                        (route) => false,
                  );
                },
                child: Text('Submit'),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Submit rating
        _submitRating(value);

        // Show thank you message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanks for your rating!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      }
    });
  }

// Add rating submission to Firebase
  Future<void> _submitRating(double rating) async {
    try {
      final DateTime now = DateTime.now();
      final User? currentUser = FirebaseAuth.instance.currentUser;

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'templateId': widget.templateImageUrl != null
            ? 'template_${DateTime.now().millisecondsSinceEpoch}'
            : 'custom_${DateTime.now().millisecondsSinceEpoch}',
        'rating': rating,
        'createdAt': now, // Firestore will convert this to Timestamp
        'imageUrl': widget.templateImageUrl ?? 'custom_image',
        'title': widget.title,
        'userId': currentUser?.uid ?? 'anonymous', // Get user ID if logged in
        'userEmail': currentUser?.email ?? 'anonymous',
        'isCustomTemplate': widget.templateImageUrl == null,
      };

      await FirebaseFirestore.instance
          .collection('template_ratings')
          .add(ratingData);

      print('Rating submitted: $rating for template ${widget.title}');

      // If this is a template from the library, update its average rating
      if (widget.templateImageUrl != null) {
        await _updateTemplateAverageRating(widget.templateImageUrl!, rating);
      }
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  Future<void> _updateTemplateAverageRating(
      String templateUrl, double newRating) async {
    try {
      // Extract template ID from URL if possible
      String templateId = 'unknown';

      // Try to parse template ID from URL or use something unique
      if (templateUrl.contains('/')) {
        templateId = templateUrl.split('/').last.split('.').first;
      }

      // Get reference to the template document
      final templateRef =
      FirebaseFirestore.instance.collection('templates').doc(templateId);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current template data
        final templateSnapshot = await transaction.get(templateRef);

        if (templateSnapshot.exists) {
          final data = templateSnapshot.data() as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = data['averageRating']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

          // Update the template with the new average rating
          transaction.update(templateRef, {
            'averageRating': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });
        } else {
          // If the document doesn't exist, create it with initial rating data
          transaction.set(templateRef, {
            'averageRating': newRating,
            'ratingCount': 1,
            'lastRated': FieldValue.serverTimestamp(),
            'templateUrl': templateUrl,
          });
        }
      });

      print('Updated template average rating successfully');
    } catch (e) {
      print('Error updating template average rating: $e');
    }
  }

  Future<void> downloadImage() async {
    if (imageData == null) {
      showNoImageSelectedDialog();
      return;
    }

    // Check if user is logged in
    User? user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    _showLoadingIndicator();

    try {
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
        _hideLoadingIndicator();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Storage permission is required to save images")));
        return;
      }

      // Generate a unique filename based on timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "Vaky_${timestamp}.jpg";

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        imageData!,
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

      // 2. Also save to user-specific directory for Files screen
      String userDirPath = await _getUserSpecificDirectoryPath();
      String filePath = '$userDirPath/$fileName';

      File file = File(filePath);
      await file.writeAsBytes(imageData!);

      // Keep track of saved images in Firestore
      await _trackSavedImage(fileName);

      _hideLoadingIndicator();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image saved to your gallery and downloads"),
          duration: Duration(seconds: 3),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
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
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
      print("Error saving image: $e");
    }
  }

// Get Android version as an integer (e.g., 29 for Android 10)
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt;
      } catch (e) {
        print('Error getting Android version: $e');
        return 0;
      }
    }
    return 0;
  }

// Request permissions for Android 13+ (API level 33+)
  Future<bool> _requestAndroid13Permission() async {
    // Check if photos permission is already granted
    bool photosGranted = await Permission.photos.isGranted;

    if (!photosGranted) {
      // Request photos permission
      final status = await Permission.photos.request();
      photosGranted = status.isGranted;
    }

    return photosGranted;
  }

// New helper method to track saved images in Firestore
  Future<void> _trackSavedImage(String fileName) async {
    try {
      User? user = _auth.currentUser;
      if (user?.email == null) return;

      String userEmail = user!.email!.replaceAll('.', '_');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('saved_images')
          .add({
        'fileName': fileName,
        'savedAt': FieldValue.serverTimestamp(),
        'imageType': widget.templateImageUrl != null ? 'template' : 'custom',
        'templateId': widget.templateImageUrl ?? 'none',
        'templateTitle': widget.title,
      });
    } catch (e) {
      print('Error tracking saved image: $e');
      // Continue even if tracking fails - the image is still saved to gallery
    }
  }

  Future<void> pickImageFromGallery() async {
    _showLoadingIndicator();

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      _hideLoadingIndicator();

      if (image != null) {
        // Show loading indicator for file reading
        _showLoadingIndicator();

        try {
          final File file = File(image.path);
          final Uint8List bytes = await file.readAsBytes();

          // Store the original image path
          originalImagePath = image.path;

          _hideLoadingIndicator();

          setState(() {
            imageData = bytes;
            defaultImageLoaded = false;
          });
        } catch (e) {
          _hideLoadingIndicator();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error reading image: $e")),
          );
        }
      }
    } catch (e) {
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final borderColor = isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: isDarkMode ? AppColors.darkDivider : Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainScreen(),
                    ));
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.share, color: primaryColor),
              onPressed: shareImage,
            ),
            TextButton(
              onPressed: downloadImage,
              child: Text("Download", style: TextStyle(color: textColor)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isLoading)
                Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                imageData == null
                    ? GestureDetector(
                        onTap: pickImageFromGallery,
                        child: Container(
                          height: 400,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.shade400,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tap to upload from gallery',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RepaintBoundary(
                        key: imageContainerKey,
                        child: Column(
                          children: [
                            Image.memory(imageData!),
                            if (showInfoBox && isPaidUser) _buildInfoBox(),
                          ],
                        ),
                      ),
              SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: Icon(Icons.photo_library,
                    color: Colors.white,),
                    label: Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (imageData == null) {
                        showNoImageSelectedDialog();
                      } else {
                        _showLoadingIndicator();

                        try {
                          var editedImage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ImageEditor(image: imageData),
                            ),
                          );

                          _hideLoadingIndicator();

                          if (editedImage != null) {
                            setState(() {
                              imageData = editedImage;
                            });
                          }
                        } catch (e) {
                          _hideLoadingIndicator();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error editing image: $e")),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.edit,color: Colors.white,),
                    label: Text('Edit Image'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
