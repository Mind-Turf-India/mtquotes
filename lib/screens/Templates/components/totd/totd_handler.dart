import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_sharing.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Create_Screen/components/details_screen.dart';
import '../../../Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../recent/recent_service.dart';

class TimeOfDayHandler {
  static final GlobalKey totdImageKey = GlobalKey();

  // Convert TimeOfDayPost to QuoteTemplate for recent templates
  static QuoteTemplate _convertTOTDToQuoteTemplate(TimeOfDayPost post) {
    return QuoteTemplate(
      id: post.id,
      title: post.title,
      imageUrl: post.imageUrl,
      isPaid: post.isPaid,
      category: "Time of Day", // Use a standard category for TOTD posts
      createdAt: DateTime.now(),
    );
  }

  static Future<bool> isUserSubscribed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      // Convert email to document ID format (replace . with _)
      String docId = user.email!.replaceAll('.', '_');

      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(docId).get();

      return userDoc.data()?['isSubscribed'] == true;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  // Function to capture the TOTD post with user details as an image
  static Future<Uint8List?> captureTOTDImage() async {
    try {
      final RenderRepaintBoundary boundary = totdImageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing TOTD image: $e');
      return null;
    }
  }

  // Add rating dialog for TOTD
  static Future<void> _showRatingDialog(
      BuildContext context, TimeOfDayPost post) async {
    double rating = 0;
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.getSurfaceColor(isDarkMode),
            title: Text(
              'Rate This Content',
              style: TextStyle(
                color: AppColors.getTextColor(isDarkMode),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How would you rate your experience with this content?',
                  style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                ),
                SizedBox(height: 20),
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating ? Colors.amber : isDarkMode ? Colors.grey[600] : Colors.grey[400],
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
                child: Text(
                  'Skip',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(rating); // Close the dialog
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text(
                  'Submit',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Send rating to backend
        _submitRating(value, post);

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

  // Add this function to submit the rating to your backend
  static Future<void> _submitRating(double rating, TimeOfDayPost post) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'postId': post.id,
        'rating': rating,
        'timeOfDay': post.id.split('_')[0],
        // Extract time of day from ID
        'createdAt': now,
        // Firestore will convert this to Timestamp
        'imageUrl': post.imageUrl,
        'isPaid': post.isPaid,
        'title': post.title,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        // Get user ID if logged in
      };

      await FirebaseFirestore.instance
          .collection('totd_ratings')
          .add(ratingData);

      print('Rating submitted: $rating for TOTD post ${post.title}');

      // Update the post's average rating
      await _updateTOTDPostAverageRating(post.id, rating);
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  static Future<void> _updateTOTDPostAverageRating(
      String postId, double newRating) async {
    try {
      // Parse time of day from post ID (assuming format like "morning_post1")
      final parts = postId.split('_');
      if (parts.length < 2) {
        print('Invalid post ID format: $postId');
        return;
      }

      final timeOfDay = parts[0];

      // Get reference to the TOTD document
      final totdRef =
      FirebaseFirestore.instance.collection('totd').doc(timeOfDay);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current TOTD document
        final totdSnapshot = await transaction.get(totdRef);

        if (totdSnapshot.exists) {
          final data = totdSnapshot.data() as Map<String, dynamic>;

          // Get the specific post data from the document
          if (data.containsKey(postId)) {
            final postData = data[postId] as Map<String, dynamic>;

            // Calculate the new average rating
            double currentAvgRating = postData['avgRating']?.toDouble() ?? 0.0;
            int ratingCount = postData['ratingCount'] ?? 0;

            int newRatingCount = ratingCount + 1;
            double newAvgRating =
                ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

            // Update only the specific post field within the document
            Map<String, dynamic> updateData = {};
            updateData['$postId.avgRating'] = newAvgRating;
            updateData['$postId.ratingCount'] = newRatingCount;
            updateData['$postId.lastRated'] = FieldValue.serverTimestamp();

            transaction.update(totdRef, updateData);
          }
        }
      });

      print('Updated TOTD post average rating successfully');
    } catch (e) {
      print('Error updating TOTD post average rating: $e');
    }
  }

  // Method to share TOTD post
  static Future<void> shareTOTDPost(
      BuildContext context,
      TimeOfDayPost post, {
        String? userName,
        String? userProfileImageUrl,
        bool isPaidUser = false,
      }) async {
    // Use a flag to track if dialog is dismissed
    bool dialogDismissed = false;
    BuildContext? dialogContext;

    try {
      // Capture theme values early to avoid accessing Provider during disposal
      final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final bool isDarkMode = themeProvider.isDarkMode;
      final Color indicatorColor = AppColors.primaryBlue;
      final Color backgroundColor = AppColors.getSurfaceColor(isDarkMode);
      final Color errorColor = Colors.red;
      final Color successColor = AppColors.primaryGreen;

      // Add to recent templates when sharing
      try {
        // Convert TOTD post to quote template format for recent templates
        QuoteTemplate template = _convertTOTDToQuoteTemplate(post);
        await RecentTemplateService.addRecentTemplate(template);
        print('Added TOTD to recents when sharing: ${post.id}');
      } catch (e) {
        print('Error adding TOTD to recents when sharing: $e');
      }

      // If userName or userProfileImageUrl are null, get them from Firebase
      if (userName == null || userProfileImageUrl == null) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        String defaultUserName = currentUser?.displayName ?? context.loc.user;
        String defaultProfileImageUrl = currentUser?.photoURL ?? '';

        // Fetch user data from users collection if available
        if (currentUser?.email != null) {
          try {
            // Convert email to document ID format (replace . with _)
            String docId = currentUser!.email!.replaceAll('.', '_');

            // Fetch user document from Firestore
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(docId)
                .get();

            // Check if document exists and has required fields
            if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
              Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

              // Get name from Firestore with fallback
              if (userData.containsKey('name') &&
                  userData['name'] != null &&
                  userData['name'].toString().isNotEmpty) {
                userName = userData['name'];
              } else {
                userName = defaultUserName;
              }

              // Get profile image from Firestore with fallback
              if (userData.containsKey('profileImage') &&
                  userData['profileImage'] != null &&
                  userData['profileImage'].toString().isNotEmpty) {
                userProfileImageUrl = userData['profileImage'];
              } else {
                userProfileImageUrl = defaultProfileImageUrl;
              }
            } else {
              userName = defaultUserName;
              userProfileImageUrl = defaultProfileImageUrl;
            }
          } catch (e) {
            print('Error fetching user data: $e');
            userName = defaultUserName;
            userProfileImageUrl = defaultProfileImageUrl;
          }
        } else {
          userName = defaultUserName;
          userProfileImageUrl = defaultProfileImageUrl;
        }
      }

      // Check if we're coming from the sharing page - if not, navigate to it
      if (!(Navigator.of(context).widget is TOTDSharingPage)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TOTDSharingPage(
              post: post,
              userName: userName ?? context.loc.user,
              // Default value if null
              userProfileImageUrl: userProfileImageUrl ?? '',
              isPaidUser: isPaidUser,
            ),
          ),
        );
        return;
      }

      // If we're already on the sharing page, perform the actual sharing
      // Create a simple loading indicator directly in this context without using showDialog
      final overlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: CircularProgressIndicator(
              color: indicatorColor,
              backgroundColor: backgroundColor,
            ),
          ),
        ),
      );

      // Insert the overlay rather than using a dialog
      if (context.mounted) {
        Overlay.of(context).insert(overlay);
      }

      Uint8List? imageBytes;

      try {
        if (isPaidUser) {
          // For paid users, capture the whole post including profile details
          imageBytes = await captureTOTDImage();
        } else {
          // For free users, just download the original post image
          final response = await http.get(Uri.parse(post.imageUrl));

          if (response.statusCode != 200) {
            throw Exception('Failed to load image');
          }
          imageBytes = response.bodyBytes;
        }
      } finally {
        // Always remove the overlay when done, regardless of success or failure
        overlay.remove();
      }

      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_totd.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaidUser) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing time of day content by $userName!',
        );
      } else {
        // For free users, share without branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing time of day content!',
        );
      }

      // After sharing, navigate back to home screen to prevent context issues
      if (context.mounted) {
        // Use pushNamedAndRemoveUntil to clear the navigation stack and return to home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);

        // Show rating dialog after a short delay
        await Future.delayed(Duration(milliseconds: 500));
        if (context.mounted) {
          await _showRatingDialog(context, post);
        }
      }
    } catch (e) {
      // Log error
      print('Error sharing TOTD post: $e');

      // Show error message - only if context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Failed to share image: ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // Navigate back to home screen on error to prevent being stuck
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

// Method to show the TOTD confirmation dialog
  // Add these methods to your TimeOfDayHandler class

  static void _showTemplateConfirmationDialog(
      BuildContext context, TimeOfDayPost post, bool isPaidUser,
      [Function?
      onConfirm] // Optional callback parameter with default value null
      ) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TOTD Image with RepaintBoundary for capture
                          RepaintBoundary(
                            key: totdImageKey,
                            child: Container(
                              height: 400,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(post.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: isPaidUser
                                  ? Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                              )
                                  : null,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Do you wish to continue?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.getTextColor(isDarkMode),
                            ),
                          ),
                          SizedBox(height: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _navigateToDetailsScreen(
                                            context, post, isPaidUser);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: AppColors.primaryGradient,
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                          BorderRadius.circular(24),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 26),
                                          child: Text('Create'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 40),
                                  SizedBox(
                                    width: 90,
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.getSurfaceColor(isDarkMode),
                                        foregroundColor: AppColors.getTextColor(isDarkMode),
                                        elevation: 0,
                                        side: BorderSide(color: AppColors.getDividerColor(isDarkMode)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(24),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Share Button
                              Center(
                                child: SizedBox(
                                  width: 120,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _handleShareTOTD(
                                          context, post, isPaidUser);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: AppColors.primaryGradient,
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Container(
                                        padding:
                                        EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.share, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Share'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Update this method in your TimeOfDayHandler class

  static void _navigateToDetailsScreen(
      BuildContext context, TimeOfDayPost post, bool isPaidUser) {
    // Convert TimeOfDayPost to QuoteTemplate for compatibility with DetailsScreen
    QuoteTemplate template = QuoteTemplate(
      id: post.id,
      title: post.title,
      imageUrl: post.imageUrl,
      isPaid: post.isPaid,
      category: "Time of Day",
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          post.createdAt.millisecondsSinceEpoch),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          template: template,
          isPaidUser: isPaidUser,
        ),
      ),
    );
  }

  static void _handleShareTOTD(
      BuildContext context, TimeOfDayPost post, bool isPaidUser) {
    if (isPaidUser) {
      // For paid users, try to fetch user info first
      _navigateToSharing(context, post, 'User', '', true);
    } else {
      // For free users, go to template sharing page
      _navigateToSharing(context, post, 'User', '', false);
    }
  }

// Helper method to safely navigate to sharing page
  static void _navigateToSharing(BuildContext context, TimeOfDayPost post,
      String userName, String userProfileImageUrl, bool isPaidUser) {
    // Check if context is still mounted before navigating
    if (context.mounted) {
      // Capture theme values before starting async operations
      final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final bool isDarkMode = themeProvider.isDarkMode;
      final Color indicatorColor = AppColors.primaryBlue;
      final Color backgroundColor = AppColors.getSurfaceColor(isDarkMode);

      // First, close any existing dialogs to ensure clean navigation
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Then immediately navigate to sharing page without showing a loading dialog first
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TOTDSharingPage(
            post: post,
            userName: userName,
            userProfileImageUrl: userProfileImageUrl,
            isPaidUser: isPaidUser,
          ),
        ),
      );
    }
  }

  static Future<void> _getUserInfoAndShare(
      BuildContext context, TimeOfDayPost post) async {
    try {
      // Capture these values early to ensure context doesn't change during async operations
      final BuildContext capturedContext = context;

      User? currentUser = FirebaseAuth.instance.currentUser;
      String userName = currentUser?.displayName ?? 'User';
      String userProfileImageUrl = currentUser?.photoURL ?? '';

      // Try to get user details from Firestore if available
      if (currentUser?.email != null) {
        String docId = currentUser!.email!.replaceAll('.', '_');

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;

          // Get name from Firestore with fallback
          if (userData.containsKey('name') &&
              userData['name'] != null &&
              userData['name'].toString().isNotEmpty) {
            userName = userData['name'];
          }

          // Get profile image from Firestore with fallback
          if (userData.containsKey('profileImage') &&
              userData['profileImage'] != null &&
              userData['profileImage'].toString().isNotEmpty) {
            userProfileImageUrl = userData['profileImage'];
          }
        }
      }

      // Use the helper method to navigate safely
      _navigateToSharing(
          capturedContext, post, userName, userProfileImageUrl, true);
    } catch (e) {
      print('Error getting user info for sharing: $e');
      // Fall back to basic sharing if there's an error
      if (context.mounted) {
        _navigateToSharing(context, post, 'User', '', true);
      }
    }
  }

// Helper methods to get user info
  static String _getUserName(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.displayName ?? context.loc.user;
  }

  static ImageProvider _getUserProfileImage(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? photoURL = currentUser?.photoURL;

    if (photoURL != null && photoURL.isNotEmpty) {
      return NetworkImage(photoURL);
    } else {
      return AssetImage('assets/images/profile_placeholder.png');
    }
  }

// Integration method for handleTimeOfDayPostSelection
    static Future<void> handleTimeOfDayPostSelection(
      BuildContext context,
      TimeOfDayPost post,
      Function(TimeOfDayPost) onAccessGranted,
      ) async {
    // Capture theme values early
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;
    final Color indicatorColor = AppColors.primaryBlue;
    final Color backgroundColor = AppColors.getSurfaceColor(isDarkMode);
    final Color textColor = AppColors.getTextColor(isDarkMode);
    final Color secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);

    // Use a stateful flag to track if we've already dismissed the dialog
    bool dialogDismissed = false;

    // Create a completer to handle dialog dismissal
    final completer = Completer<void>();

    // Show a loading indicator that we can reliably dismiss
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // When the dialog builds, store its context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            completer.complete();
          });

          return Center(
            child: CircularProgressIndicator(
              color: indicatorColor,
              backgroundColor: backgroundColor,
            ),
          );
        },
      );
    }

    // Wait for dialog to be fully built
    await completer.future;

    try {
      // Check if user is subscribed
      bool isSubscribed = await isUserSubscribed();

      // Add to recent templates if user is subscribed or post is free
      if (!post.isPaid || isSubscribed) {
        // Convert TOTD post to quote template format for recent templates
        QuoteTemplate template = _convertTOTDToQuoteTemplate(post);
        await RecentTemplateService.addRecentTemplate(template);
        print('Added TOTD to recents on selection: ${post.id}');
      }

      // Dismiss dialog safely
      if (context.mounted && !dialogDismissed) {
        dialogDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Check if context is still mounted before proceeding
      if (!context.mounted) return;

      if (post.isPaid && !isSubscribed) {
        // Show subscription dialog/prompt
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              'Premium Content',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This content requires a subscription. Subscribe to access all premium time of day posts.',
              style: TextStyle(color: secondaryTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to subscription page
                  Navigator.pushNamed(context, '/subscription');
                },
                child: Text(
                  'Subscribe',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show confirmation dialog with preview - pass the callback function
        _showTemplateConfirmationDialog(
          context,
          post,
          isSubscribed,
              () => onAccessGranted(post), // Pass the callback here
        );
      }
    } catch (e) {
      // Dismiss dialog safely in case of error
      if (context.mounted && !dialogDismissed) {
        dialogDismissed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show error message if context is still valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to initialize TOTD posts if none exist
  static Future<void> initializeTOTDPostsIfNeeded(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final timeOfDayService = TimeOfDayService();
    final posts = await timeOfDayService.fetchTimeOfDayPosts();
    // Add any initialization logic here

    // Close loading indicator
    Navigator.of(context, rootNavigator: true).pop();
  }
}
    // Show loading indicator