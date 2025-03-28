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
import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/template_service.dart';
import 'package:mtquotes/screens/Templates/components/template/template_sharing.dart';
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
        // Show subscription dialog/prompt
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Premium Template'),
            content: Text(
                'This template requires a subscription. Subscribe to access all premium templates.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to subscription page
                  Navigator.pushNamed(context, '/subscription');
                },
                child: Text('Subscribe'),
              ),
            ],
          ),
        );
      } else {
        // Show confirmation dialog with preview
        // The issue is here - we need to pass isSubscribed as the third parameter
        showTemplateConfirmationDialog(
          context,
          template,
          isSubscribed, // Pass the boolean value here
        );

        // Then we need to modify _showTemplateConfirmationDialog to handle the callback
        // This should be done in the implementation of _showTemplateConfirmationDialog
        // to call onAccessGranted(template) when the create button is pressed
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
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
  static Future<void> _showRatingDialog(BuildContext context,QuoteTemplate template) async {
    double rating = 0;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Rate This Template'),
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
                              color: index < rating ? Colors.amber : Colors.grey,
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
                    )],
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
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    child: Text('Submit'),
                  ),
                ],
              );
            }
        );
      },
    ).then((value) {
      if (value != null && value > 0) {
        // TODO: Send rating to your backend
        _submitRating(value, template);

        // Show thank you message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thanks for your rating!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  static Future<void> _updateCategoryTemplateRating(String templateId, String category, double newRating) async {
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
          double newAvgRating = ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

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
  static Future<void> _submitRating(double rating, QuoteTemplate template) async {
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

      print('Rating submitted: $rating for template ${template.title} (ID: ${template.id})');

      // Determine if this is a category template based on non-empty category field
      if (template.category.isNotEmpty) {
        // Update the category template's rating
        await _updateCategoryTemplateRating(template.id, template.category, rating);
      } else {
        // Use the original method for regular templates
        await _updateTemplateAverageRating(template.id, rating);
      }

    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  static Future<void> _updateTemplateAverageRating(String templateId, double newRating) async {
    try {
      // Get reference to the template document
      final templateRef = FirebaseFirestore.instance.collection('templates').doc(templateId);

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
          double newAvgRating = ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

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


  static Future<void> shareTemplate(
      BuildContext context,
      QuoteTemplate template, {
        String? userName,
        String? userProfileImageUrl,
        bool isPaidUser = false,
      }) async {
    // Capture context early
    final capturedContext = context;

    try {
      // Add to recent templates when sharing
      try {
        await RecentTemplateService.addRecentTemplate(template);
        print('Added template to recents when sharing: ${template.id}');
      } catch (e) {
        print('Error adding template to recents when sharing: $e');
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
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

              // Get name from Firestore with fallback
              if (userData.containsKey('name') && userData['name'] != null && userData['name'].toString().isNotEmpty) {
                userName = userData['name'];
              } else {
                userName = defaultUserName;
              }

              // Get profile image from Firestore with fallback
              if (userData.containsKey('profileImage') && userData['profileImage'] != null && userData['profileImage'].toString().isNotEmpty) {
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
      if (capturedContext.mounted) {
        bool isOnSharingPage = false;

        try {
          // This is more reliable than using is operator which can cause issues
          isOnSharingPage = Navigator.of(capturedContext).widget.toString().contains('TemplateSharingPage');
        } catch (e) {
          print('Error checking current page: $e');
        }

        if (!isOnSharingPage) {
          Navigator.of(capturedContext).push(
            MaterialPageRoute(
              builder: (context) => TemplateSharingPage(
                template: template,
                userName: userName ?? 'User',  // Default value if null
                userProfileImageUrl: userProfileImageUrl ?? '',
                isPaidUser: isPaidUser,
              ),
            ),
          );
          return;
        }
      } else {
        return; // Context is no longer mounted, can't proceed
      }

      // If we're already on the sharing page, perform the actual sharing
      // Show loading indicator
      if (capturedContext.mounted) {
        showDialog(
          context: capturedContext,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      } else {
        return; // Context is no longer mounted, can't proceed
      }

      Uint8List? imageBytes;

      if (isPaidUser) {
        // For paid users, capture the whole template including profile details
        imageBytes = await captureTemplateImage();
      } else {
        // For free users, just download the original template image
        final response = await http.get(Uri.parse(template.imageUrl));

        if (response.statusCode != 200) {
          throw Exception('Failed to load image');
        }
        imageBytes = response.bodyBytes;
      }

      // Close loading dialog
      if (capturedContext.mounted) {
        Navigator.of(capturedContext, rootNavigator: true).pop();
      } else {
        return; // Context is no longer mounted, can't proceed
      }

      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_template.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaidUser) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing quote template by $userName!',
        );
      } else {
        // For free users, share without branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing quote template!',
        );
      }

      // Show rating dialog after sharing
      await Future.delayed(Duration(milliseconds: 500));
      if (capturedContext.mounted) {
        await _showRatingDialog(capturedContext, template);
      }

    } catch (e) {
      print('Error sharing template: $e');

      // Close loading dialog if open
      if (capturedContext.mounted) {
        try {
          Navigator.of(capturedContext, rootNavigator: true).pop();
        } catch (dialogError) {
          print('Error closing dialog: $dialogError');
        }

        // Show error message
        ScaffoldMessenger.of(capturedContext).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Method to show the template confirmation dialog
  static void showTemplateConfirmationDialog(
      BuildContext context,
      QuoteTemplate template,
      bool isPaidUser,
      ) {
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Template Image
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(template.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Do you wish to continue?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                                        // Navigate to profile details screen
                                        _navigateToProfileDetailsScreen(context, template, isPaidUser);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Text('Create'),
                                    ),
                                  ),
                                  SizedBox(width: 40),
                                  SizedBox(
                                    width: 100,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black87,
                                        elevation: 0,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12),
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
                                  width: 140,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _handleShareTemplate(context, template, isPaidUser);
                                    },
                                    icon: Icon(Icons.share),
                                    label: Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12),
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
      BuildContext context,
      QuoteTemplate template,
      bool isPaidUser) {
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
      BuildContext context,
      QuoteTemplate template,
      bool isPaidUser) {
    if (isPaidUser) {
      // For paid users, try to fetch user info first
      _navigateToSharing(
          context,
          template,
          'User',
          '',
          true
      );
    } else {
      // For free users, go to template sharing page
      _navigateToSharing(
          context,
          template,
          'User',
          '',
          false
      );
    }
  }

// Helper method to safely navigate to sharing page
  static void _navigateToSharing(
      BuildContext context,
      QuoteTemplate template,
      String userName,
      String userProfileImageUrl,
      bool isPaidUser) {
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

  static Future<void> _getUserInfoAndShare(BuildContext context, QuoteTemplate template) async {
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
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Get name from Firestore with fallback
          if (userData.containsKey('name') && userData['name'] != null && userData['name'].toString().isNotEmpty) {
            userName = userData['name'];
            print("name fetched");
          }

          // Get profile image from Firestore with fallback
          if (userData.containsKey('profileImage') && userData['profileImage'] != null && userData['profileImage'].toString().isNotEmpty) {
            userProfileImageUrl = userData['profileImage'];
            print("pic fetched");

          }
        }
      }

      // Use the helper method to navigate safely
      _navigateToSharing(capturedContext, template, userName, userProfileImageUrl, true);
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
      BuildContext context,
      Uint8List imageData,
      bool isPaidUser
      ) async {
    // For free users, redirect to template sharing
    if (!isPaidUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgrade to access direct sharing'),
          action: SnackBarAction(
            label: 'UPGRADE',
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
      // Save image to temp file
      final temp = await getTemporaryDirectory();
      final path = "${temp.path}/edited_image.jpg";
      File(path).writeAsBytes(imageData);

      // Share the image
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Check out this amazing template from our app!',
      );
    } catch (e) {
      print('Error sharing from edit screen: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share image. Please try again.')),
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