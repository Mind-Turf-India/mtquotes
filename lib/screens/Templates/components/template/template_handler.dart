import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:mtquotes/screens/Templates/components/template/template_sharing.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../../../Create_Screen/edit_screen_create.dart';
import '../recent/recent_service.dart';

class TemplateHandler {
  static final GlobalKey templateImageKey = GlobalKey();

  // Handle template selection with subscription check
  static Future<void> handleTemplateSelection(
    BuildContext context,
    QuoteTemplate template,
    Function(QuoteTemplate) onAccessGranted,
  ) async {
    showLoadingIndicator(context);
    try {
      final templateService = TemplateService();
      bool isSubscribed = await templateService.isUserSubscribed();

      // Add to recent templates if user is subscribed or template is free
      if (!template.isPaid || isSubscribed) {
        try {
          await RecentTemplateService.addRecentTemplate(template);
          print('Added template to recents on selection: ${template.id}');
        } catch (e) {
          print('Error adding template to recents: $e');
        }
      }

      hideLoadingIndicator(context);

      if (template.isPaid && !isSubscribed) {
        // Show subscription dialog/prompt with proper theming
        final ThemeData theme = Theme.of(context);
        final bool isDarkMode = theme.brightness == Brightness.dark;
        final Color backgroundColor =
            isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
        final Color textColor =
            isDarkMode ? AppColors.darkText : AppColors.lightText;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              context.loc.premiumTemplate,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: Text(
              context.loc.thisRequiresSubscription,
              style: TextStyle(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.loc.cancel,
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
                  context.loc.subscribe,
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show confirmation dialog with preview
        showTemplateConfirmationDialog(
          context,
          template,
          isSubscribed,
        );
      }
    } catch (e) {
      hideLoadingIndicator(context);
      print('Error in handleTemplateSelection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void showLoadingIndicator(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
            backgroundColor:
                isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          ),
        );
      },
    );
  }

  static void hideLoadingIndicator(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Function to capture the template with user details as an image
  static Future<Uint8List?> captureTemplateImage() async {
    try {
      final RenderRepaintBoundary boundary = templateImageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing template image: $e');
      return null;
    }
  }

  // Add this function to your TemplateConfirmationDialog class
  static Future<void> _showRatingDialog(
      BuildContext context, QuoteTemplate template) async {
    double rating = 0;
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor =
        isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              context.loc.rateThisContent,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.loc.howWouldYouRateExperience,
                  style: TextStyle(color: secondaryTextColor),
                ),
                SizedBox(height: 20),
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating
                              ? Colors.amber
                              : isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
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
                  context.loc.skip,
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(rating); // Close the dialog
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text(
                  context.loc.submit,
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // TODO: Send rating to your backend
        _submitRating(value, template);

        // Show thank you message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.loc.thanksForYourRating),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      }
    });
  }

  static Future<void> _updateCategoryTemplateRating(
      String templateId, String category, double newRating) async {
    try {
      // Path to the category template document
      final templateRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(category.toLowerCase())
          .collection('templates')
          .doc(templateId);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current template data
        final templateSnapshot = await transaction.get(templateRef);

        if (templateSnapshot.exists) {
          final data = templateSnapshot.data() as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = data['avgRatings']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

          // Update the template with the new average rating
          transaction.update(templateRef, {
            'avgRatings': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });

          print('Updated category template average rating successfully');
        } else {
          print('Template not found in category collection');
        }
      });
    } catch (e) {
      print('Error updating category template average rating: $e');
    }
  }

  // Add this function to submit the rating to your backend
  static Future<void> _submitRating(
      double rating, QuoteTemplate template) async {
    try {
      final DateTime now = DateTime.now();
      final User? currentUser = FirebaseAuth.instance.currentUser;

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'templateId': template.id,
        'rating': rating,
        'category': template.category,
        'createdAt': now,
        'imageUrl': template.imageUrl,
        'isPaid': template.isPaid,
        'title': template.title,
        'userId': currentUser?.uid ?? 'anonymous',
        'userEmail': currentUser?.email ?? 'anonymous',
      };

      // Add to ratings collection
      DocumentReference ratingRef = await FirebaseFirestore.instance
          .collection('ratings')
          .add(ratingData);

      print(
          'Rating submitted: $rating for template ${template.title} (ID: ${template.id})');

      // Determine if this is a category template based on non-empty category field
      if (template.category.isNotEmpty) {
        // Update the category template's rating
        await _updateCategoryTemplateRating(
            template.id, template.category, rating);
      } else {
        // Use the original method for regular templates
        await _updateTemplateAverageRating(template.id, rating);
      }
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  static Future<void> _updateTemplateAverageRating(
      String templateId, double newRating) async {
    try {
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
        }
      });

      print('Updated template average rating successfully');
    } catch (e) {
      print('Error updating template average rating: $e');
    }
  }

  // Method to show the template confirmation dialog
  // Advanced version using CachedNetworkImage for better performance
  static void showTemplateConfirmationDialog(
    BuildContext context,
    QuoteTemplate template,
    bool isPaidUser,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color dividerColor =
        isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;

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
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Template Image with Loading Indicator
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image with loading state
                                  CachedNetworkImage(
                                    imageUrl: template.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            color: AppColors.primaryBlue,
                                            backgroundColor: isDarkMode
                                                ? Colors.grey.shade700
                                                : Colors.grey.shade300,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            context.loc.loading,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 48,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            context.loc.failedToLoadImage,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Add these options for better caching behavior
                                    cacheKey: '${template.id}_confirmation',
                                    memCacheWidth:
                                        600, // Optimize memory cache size
                                    maxHeightDiskCache:
                                        800, // Optimize disk cache size
                                  ),

                                  // PRO badge (only if template is paid)
                                  if (template.isPaid)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock,
                                                color: Colors.amber, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'PRO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
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
                          SizedBox(height: 24),
                          Text(
                            context.loc.doYouWishToContinue,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
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
                                        _navigateToProfileDetailsScreen(
                                            context, template, isPaidUser);
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
                                          color: isDarkMode ? AppColors.primaryBlue: AppColors.primaryBlue,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 26),
                                          child: Text(context.loc.create),
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
                                        backgroundColor: backgroundColor,
                                        foregroundColor: textColor,
                                        elevation: 0,
                                        side: BorderSide(color: dividerColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(context.loc.cancel),
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
                                      _handleShareTemplate(
                                          context, template, isPaidUser);
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
                                        color: isDarkMode ? AppColors.primaryBlue: AppColors.primaryBlue,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.share,
                                                color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(context.loc.share),
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

  static void _navigateToProfileDetailsScreen(
      BuildContext context, QuoteTemplate template, bool isPaidUser) {
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

  static void _handleShareTemplate(
      BuildContext context, QuoteTemplate template, bool isPaidUser) {
    if (isPaidUser) {
      // For paid users, try to fetch user info first
      _navigateToSharing(context, template, 'User', '', true);
    } else {
      // For free users, go to template sharing page
      _navigateToSharing(context, template, 'User', '', false);
    }
  }

  // Helper method to safely navigate to sharing page
  static void _navigateToSharing(BuildContext context, QuoteTemplate template,
      String userName, String userProfileImageUrl, bool isPaidUser) {
    print("navigating to sharing");
    // Check if context is still mounted before navigating
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateSharingPage(
            template: template,
            userName: userName,
            userProfileImageUrl: userProfileImageUrl,
            isPaidUser: isPaidUser,
          ),
        ),
      );
    }
    print("success");
  }

  static Future<void> _getUserInfoAndShare(
      BuildContext context, QuoteTemplate template) async {
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
        print("user deets");

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Get name from Firestore with fallback
          if (userData.containsKey('name') &&
              userData['name'] != null &&
              userData['name'].toString().isNotEmpty) {
            userName = userData['name'];
            print("name fetched");
          }

          // Get profile image from Firestore with fallback
          if (userData.containsKey('profileImage') &&
              userData['profileImage'] != null &&
              userData['profileImage'].toString().isNotEmpty) {
            userProfileImageUrl = userData['profileImage'];
            print("pic fetched");
          }
        }
      }

      // Use the helper method to navigate safely
      _navigateToSharing(
          capturedContext, template, userName, userProfileImageUrl, true);
      print("navigated");
    } catch (e) {
      print('Error getting user info for sharing: $e');
      // Fall back to basic sharing if there's an error
      if (context.mounted) {
        _navigateToSharing(context, template, 'User', '', true);
      }
      print("not navigated");
    }
  }

  static Future<void> handleEditScreenSharing(
      BuildContext context, Uint8List imageData, bool isPaidUser) async {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;

    // For free users, redirect to template sharing
    if (!isPaidUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDarkMode ? AppColors.darkSurface : null,
          content: Text(
            'Upgrade to access direct sharing',
            style: TextStyle(color: textColor),
          ),
          action: SnackBarAction(
            label: 'UPGRADE',
            textColor: AppColors.primaryBlue,
            onPressed: () {
              Navigator.pushNamed(context, '/subscription');
            },
          ),
        ),
      );
      return;
    }
    // For paid users, directly share using Share.shareFiles
    try {
      // Show loading indicator
      showLoadingIndicator(context);

      // Save image to temp file
      final temp = await getTemporaryDirectory();
      final path = "${temp.path}/edited_image.jpg";
      File(path).writeAsBytes(imageData);

      // Hide loading indicator
      hideLoadingIndicator(context);

      // Share the image
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Check out this amazing template from our app!',
      );
    } catch (e) {
      print('Error sharing from edit screen: $e');

      // Hide loading indicator if visible
      hideLoadingIndicator(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isDarkMode ? AppColors.darkSurface : null,
            content: Text(
              'Failed to share image. Please try again.',
              style: TextStyle(color: textColor),
            ),
          ),
        );
      }
    }
  }

  // Method to initialize templates if none exist
  static Future<void> initializeTemplatesIfNeeded() async {
    final templateService = TemplateService();
    final templates = await templateService.fetchRecentTemplates();
    // Add any initialization logic here
  }
}
