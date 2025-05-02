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
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:mtquotes/screens/Templates/components/template/template_sharing.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../../../../utils/shimmer.dart';
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

// Fixed hideLoadingIndicator function
  static void hideLoadingIndicator(BuildContext context) {
    // Check if the context is still mounted before trying to pop
    if (context.mounted &&
        Navigator.of(context, rootNavigator: true).canPop()) {
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

  // Show rating dialog


  // Update category template rating
  static Future<void> _updateCategoryTemplateRating(
      String templateId, String category, double newRating) async {
    try {
      // Reference to the template document in the category collection
      final DocumentReference categoryTemplateRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(category.toLowerCase())
          .collection('templates')
          .doc(templateId);

      // Get the current template data first to verify it exists
      final DocumentSnapshot templateDoc = await categoryTemplateRef.get();

      if (!templateDoc.exists) {
        print('Warning: Template $templateId not found in category $category');
        return;
      }

      // Extract current data
      final data = templateDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('Warning: Category template data is null');
        return;
      }

      // Calculate the new average rating and count
      double currentRating = 0.0;
      if (data.containsKey('avgRating')) {
        currentRating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('avgRatings')) {
        currentRating = (data['avgRatings'] as num?)?.toDouble() ?? 0.0;
      }

      int ratingCount = (data['ratingCount'] as int?) ?? 0;

      // Calculate new values
      int newRatingCount = ratingCount + 1;
      double newAvgRating =
          ((currentRating * ratingCount) + newRating) / newRatingCount;

      // Debug info
      print(
          'Category template $templateId - Current avgRating: $currentRating, Count: $ratingCount');
      print(
          'Category template $templateId - New avgRating: $newAvgRating, Count: $newRatingCount');

      // Update the document with new rating values
      Map<String, dynamic> updateData = {
        'avgRating': newAvgRating,
        'ratingCount': newRatingCount,
        'lastRated': FieldValue.serverTimestamp(),
      };

      await categoryTemplateRef.update(updateData);
      print('Successfully updated template $templateId in category $category');
    } catch (e) {
      print('Error updating category template rating: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }


  // Update template in the main templates collection
  static Future<void> _updateMainTemplateRating(
      String templateId, double newRating) async {
    try {
      // Reference to the template document in the main collection
      final DocumentReference templateRef =
          FirebaseFirestore.instance.collection('templates').doc(templateId);

      // Get the current template data first to verify it exists
      final DocumentSnapshot templateDoc = await templateRef.get();

      if (!templateDoc.exists) {
        print(
            'Warning: Template $templateId not found in main templates collection');
        return;
      }

      // Extract current data
      final data = templateDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('Warning: Template data is null');
        return;
      }

      // Calculate the new average rating and count
      double currentRating = 0.0;
      if (data.containsKey('avgRating')) {
        currentRating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      } else if (data.containsKey('averageRating')) {
        currentRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      }

      int ratingCount = (data['ratingCount'] as int?) ?? 0;

      // Calculate new values
      int newRatingCount = ratingCount + 1;
      double newAvgRating =
          ((currentRating * ratingCount) + newRating) / newRatingCount;

      // Debug info
      print(
          'Template $templateId - Current avgRating: $currentRating, Count: $ratingCount');
      print(
          'Template $templateId - New avgRating: $newAvgRating, Count: $newRatingCount');

      // Update the document with new rating values
      Map<String, dynamic> updateData = {
        'avgRating': newAvgRating,
        'ratingCount': newRatingCount,
        'lastRated': FieldValue.serverTimestamp(),
      };

      await templateRef.update(updateData);
      print('Successfully updated template $templateId in main collection');
    } catch (e) {
      print('Error updating template rating in main collection: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Method to show the template confirmation dialog
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

    // Get username and profile image from current user
    String userName = 'User';
    String userProfileImageUrl = '';

    // Try to get current user info synchronously
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userName = currentUser.displayName ?? 'User';
        userProfileImageUrl = currentUser.photoURL ?? '';
      }
    } catch (e) {
      print('Error getting user data: $e');
    }

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
                          // Close button (X) in top right corner
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding:
                                  EdgeInsets.only(top: 0, right: 4, bottom: 8),
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: Icon(
                                  Icons.close,
                                  color: AppColors.getIconColor(isDarkMode),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                          // Template Image with Shimmer Loading Effect
                          Container(
                            height: 420,
                            // Slightly taller to account for overlap
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              // Important: don't clip children
                              children: [
                                // Image container with rounded corners
                                Container(
                                  height: 400,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Image with shimmer loading state
                                        CachedNetworkImage(
                                          imageUrl: template.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              ShimmerLoader(
                                            width: double.infinity,
                                            height: double.infinity,
                                            isDarkMode: isDarkMode,
                                            type: ShimmerType.template,
                                            margin: EdgeInsets.zero,
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                          cacheKey:
                                              '${template.id}_confirmation',
                                          memCacheWidth: 600,
                                          // Optimize memory cache size
                                          maxHeightDiskCache:
                                              800, // Optimize disk cache size
                                        ),

                                        // PRO badge (only if template is paid)
                                        if (template.isPaid)
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 2, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/icons/premium_1659060.svg',
                                                width: 24,
                                                height: 24,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ),

                                        // Watermark in top right corner (show for non-paid users or non-paid templates)
                                        if (!isPaidUser || !template.isPaid)
                                          Positioned(
                                            top: 16,
                                            // Position from top with padding
                                            right: 16,
                                            // Position from right edge with padding
                                            child: Opacity(
                                              opacity: 0.9,
                                              child: SvgPicture.asset(
                                                'assets/Vaky_bnw.svg',
                                                width: 50, // Fixed width size
                                                height: 50, // Fixed height size
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // User profile container at the bottom, overlapping the image
                                Positioned(
                                  bottom: -15,
                                  // Negative value creates overlap effect
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, -2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // User name in container similar to example
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              userName,
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: 8),

                                        // User profile image
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: userProfileImageUrl
                                                    .isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl:
                                                        userProfileImageUrl,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context,
                                                            url) =>
                                                        CircularProgressIndicator(),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(
                                                      Icons.person,
                                                      color: Colors.grey,
                                                      size: 24,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
                                                    size: 24,
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

                          SizedBox(height: 30),
                          Text(
                            context.loc.doYouWishToContinue,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 24),
                          // Button row with Create and Share buttons
                          Row(
                            children: [
                              // Create button (with outline style)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _navigateToProfileDetailsScreen(
                                        context, template, isPaidUser);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: dividerColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    context.loc.create,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 16),

                              // Share button (with filled blue style)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _handleShareTemplate(
                                        context, template, isPaidUser);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    context.loc.share,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
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
