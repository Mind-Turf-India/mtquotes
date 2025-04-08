import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_service.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_sharing.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../Create_Screen/components/details_screen.dart';
import '../recent/recent_service.dart';

class FestivalHandler {
  static final GlobalKey festivalImageKey = GlobalKey();
  static final GlobalKey festivalSharingImageKey = GlobalKey();
  static final FestivalService _festivalService = FestivalService();

  // Helper method to show loading indicator
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
            backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          ),
        );
      },
    );
  }

  // Helper method to hide loading indicator
  static void hideLoadingIndicator(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Convert FestivalPost to QuoteTemplate for recent templates
  static QuoteTemplate _convertFestivalToQuoteTemplate(FestivalPost festival) {
    return QuoteTemplate(
      id: festival.id,
      title: festival.name,
      imageUrl: festival.imageUrl,
      isPaid: festival.isPaid,
      category: festival.category,
      createdAt: festival.createdAt,
    );
  }

  // Function to capture the festival image with user details
  static Future<Uint8List?> captureFestivalImage() async {
    return captureFestivalImageFromContext(festivalImageKey.currentContext!);
  }

  // Show rating dialog for festivals
  static Future<void> _showRatingDialog(
      BuildContext context, FestivalPost festival) async {
    double rating = 0;
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
    final fontSize = textSizeProvider.fontSize;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              context.loc.rateThisContent,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.loc.howWouldYouRateExperience,
                  style: TextStyle(
                    color: secondaryTextColor,
                  ),
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
                  context.loc.skip,
                  style: TextStyle(
                    color: AppColors.primaryBlue,

                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(rating); // Close the dialog
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text(
                  context.loc.submit,
                  style: TextStyle(
                    color: AppColors.primaryBlue,

                  ),
                ),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Show loading indicator when submitting rating
        showLoadingIndicator(context);

        // Submit rating
        _submitRating(value, festival).then((_) {
          // Hide loading indicator
          hideLoadingIndicator(context);

          // Show thank you message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc.thanksForYourRating),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        }).catchError((error) {
          // Hide loading indicator in case of error
          hideLoadingIndicator(context);

          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc.failedToSubmitRating + ': ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    });
  }

  // Submit rating to Firestore
  static Future<void> _submitRating(
      double rating, FestivalPost festival) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'festivalId': festival.id,
        'rating': rating,
        'category': festival.category,
        'createdAt': now,
        'imageUrl': festival.imageUrl,
        'isPaid': festival.isPaid,
        'name': festival.name,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      };

      await FirebaseFirestore.instance
          .collection('festival_ratings')
          .add(ratingData);

      print('Rating submitted: $rating for festival ${festival.name}');

      // Update the festival's average rating
      await _updateFestivalAverageRating(festival.id, rating);
    } catch (e) {
      print('Error submitting festival rating: $e');
      throw e; // Rethrow to handle in calling method
    }
  }

  // Update average rating in Firestore
  static Future<void> _updateFestivalAverageRating(
      String festivalId, double newRating) async {
    try {
      // Get reference to the festival document
      final festivalRef = FirebaseFirestore.instance
          .collection('festivals')
          .doc(festivalId.split('_')[0]);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current festival data
        final festivalSnapshot = await transaction.get(festivalRef);

        if (festivalSnapshot.exists) {
          final data = festivalSnapshot.data() as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = data['averageRating']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

          // Update the festival with the new average rating
          transaction.update(festivalRef, {
            'averageRating': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('Updated festival average rating successfully');
    } catch (e) {
      print('Error updating festival average rating: $e');
      throw e; // Rethrow to handle in calling method
    }
  }

  // Method to share festival post
  static Future<void> shareFestival(
      BuildContext context,
      FestivalPost festival, {
        String? userName,
        String? userProfileImageUrl,
        bool isPaidUser = false,
      }) async {
    try {
      // Add to recent templates when sharing
      try {
        // Convert festival to quote template format for recent templates
        QuoteTemplate template = _convertFestivalToQuoteTemplate(festival);
        await RecentTemplateService.addRecentTemplate(template);
        print('Added festival to recents when sharing: ${festival.id}');
      } catch (e) {
        print('Error adding festival to recents when sharing: $e');
      }

      // Show loading indicator
      showLoadingIndicator(context);

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
      if (!(Navigator.of(context).widget is FestivalSharingPage)) {
        // Hide loading indicator before navigation
        hideLoadingIndicator(context);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FestivalSharingPage(
              festival: festival,
              userName: userName ?? context.loc.user,
              userProfileImageUrl: userProfileImageUrl ?? '',
              isPaidUser: isPaidUser,
            ),
          ),
        );
        return;
      }

      final ThemeData theme = Theme.of(context);
      final bool isDarkMode = theme.brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
              backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
            ),
          );
        },
      );

      // If we're already on the sharing page, perform the actual sharing
      Uint8List? imageBytes;

      if (isPaidUser) {
        // For paid users, capture the whole festival including profile details
        // Use a different method that determines which key to use based on context
        imageBytes = await captureFestivalImageFromContext(context);
      } else {
        // For free users, just download the original festival image
        final response = await http.get(Uri.parse(festival.imageUrl));

        if (response.statusCode != 200) {
          throw Exception('Failed to load image');
        }
        imageBytes = response.bodyBytes;
      }

      // Close loading dialog
      hideLoadingIndicator(context);

      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_festival.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaidUser) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing festival post by $userName!',
        );
      } else {
        // For free users, share without branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing festival post!',
        );
      }

      // Show rating dialog after sharing
      await Future.delayed(Duration(milliseconds: 500));
      if (context.mounted) {
        await _showRatingDialog(context, festival);
      }
    } catch (e) {
      // Close loading dialog if open
      hideLoadingIndicator(context);

      print('Error sharing festival: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<Uint8List?> captureFestivalImageFromContext(
      BuildContext context) async {
    try {
      // Determine if we're on the sharing page or dialog
      GlobalKey keyToUse = Navigator.of(context).widget is FestivalSharingPage
          ? festivalSharingImageKey
          : festivalImageKey;

      final RenderRepaintBoundary boundary =
      keyToUse.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing festival image: $e');
      return null;
    }
  }

  // Method to show the festival confirmation dialog
  static void _showFestivalInfoBox(
      BuildContext context,
      FestivalPost festival,
      bool isPaidUser,
      ) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final Color dividerColor = isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
    final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
    final fontSize = textSizeProvider.fontSize;

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
                          // Festival Image with RepaintBoundary for capture
                          RepaintBoundary(
                            key: festivalImageKey,
                            child: Container(
                              height: 400,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                // Remove the DecorationImage to use CachedNetworkImage instead
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Main image with loading state
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: festival.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                            fontSize: fontSize - 2,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),]
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                                fontSize: fontSize - 2,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Add these options for better caching behavior
                                      cacheKey: '${festival.id}_dialog',
                                      memCacheWidth: 600, // Optimize memory cache size
                                      maxHeightDiskCache: 800, // Optimize disk cache size
                                    ),
                                  ),

                                  // PRO badge for paid content
                                  if (festival.isPaid)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, color: Colors.amber, size: 14),
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

                                  // Bottom-right watermark for paid users
                                  if (isPaidUser)
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
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
                                        _navigateToDetailsScreen(
                                            context, festival, isPaidUser);
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
                                          child: Text(
                                            context.loc.create,
                                          ),
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
                                      child: Text(
                                        context.loc.cancel,
                                      ),
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
                                      _handleShareFestival(
                                          context, festival, isPaidUser);
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
                                            Text(
                                              context.loc.share,
                                            ),
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

  // Navigate to the details screen first, not directly to edit screen
  static void _navigateToDetailsScreen(
      BuildContext context, FestivalPost festival, bool isPaidUser) {
    // Convert FestivalPost to QuoteTemplate for compatibility with DetailsScreen
    QuoteTemplate template = QuoteTemplate(
      id: festival.id,
      title: festival.name,
      imageUrl: festival.imageUrl,
      isPaid: festival.isPaid,
      category: festival.category,
      createdAt: festival.createdAt,
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

  static void _handleShareFestival(
      BuildContext context, FestivalPost festival, bool isPaidUser) {
    if (isPaidUser) {
      // For paid users, try to fetch user info first
      _navigateToSharing(context, festival, 'User', '', true);
    } else {
      // For free users, go to festival sharing page
      _navigateToSharing(context, festival, 'User', '', false);
    }
  }

  // Helper method to safely navigate to sharing page
  static void _navigateToSharing(BuildContext context, FestivalPost festival,
      String userName, String userProfileImageUrl, bool isPaidUser) {
    print("navigating to sharing");
    // Check if context is still mounted before navigating
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FestivalSharingPage(
            festival: festival,
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
      BuildContext context, FestivalPost festival) async {
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
          capturedContext, festival, userName, userProfileImageUrl, true);
      print("navigated");
    } catch (e) {
      print('Error getting user info for sharing: $e');
      // Fall back to basic sharing if there's an error
      if (context.mounted) {
        _navigateToSharing(context, festival, 'User', '', true);
      }
      print("not navigated");
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
      return AssetImage('assets/profile_placeholder.png');
    }
  }

  // Integration method for handleFestivalSelection
  static Future<void> handleFestivalSelection(
      BuildContext context,
      FestivalPost festival,
      Function(FestivalPost) onFestivalSelected,
      ) async {
    // Show loading indicator
    showLoadingIndicator(context);

    try {
      bool isSubscribed = await _festivalService.isUserSubscribed();

      // Add to recent templates if user is subscribed or festival is free
      if (!festival.isPaid || isSubscribed) {
        try {
          // Convert festival to quote template format for recent templates
          QuoteTemplate template = _convertFestivalToQuoteTemplate(festival);
          await RecentTemplateService.addRecentTemplate(template);
          print('Added festival to recents on selection: ${festival.id}');
        } catch (e) {
          print('Error adding festival to recents: $e');
        }
      }

      // Hide loading indicator
      hideLoadingIndicator(context);

      if (festival.isPaid && !isSubscribed) {
        // Show subscription dialog/prompt with theme
        final ThemeData theme = Theme.of(context);
        final bool isDarkMode = theme.brightness == Brightness.dark;
        final Color backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
        final Color textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
        final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
        final fontSize = textSizeProvider.fontSize;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              context.loc.premiumTemplate,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
            content: Text(
              context.loc.thisRequiresSubscription,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize - 2,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.loc.cancel,
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: fontSize - 2,
                  ),
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
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: fontSize - 2,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show info box dialog with preview
        _showFestivalInfoBox(
          context,
          festival,
          isSubscribed,
        );
      }
    } catch (e) {
      // Hide loading indicator in case of error
      hideLoadingIndicator(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading festival data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to initialize festivals if none exist
  static Future<void> initializeFestivalsIfNeeded(BuildContext context) async {
    try {
      // Show loading indicator
      showLoadingIndicator(context);

      final festivals = await _festivalService.getActiveFestivals();
      // Add any initialization logic here

      // Hide loading indicator
      hideLoadingIndicator(context);
    } catch (e) {
      // Hide loading indicator in case of error
      hideLoadingIndicator(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.errorInitializingFestivals + ': ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}