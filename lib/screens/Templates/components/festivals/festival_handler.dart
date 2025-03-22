import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';
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
import 'package:mtquotes/screens/Templates/subscription_popup.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../recent/recent_service.dart';

class FestivalHandler {
  static final GlobalKey festivalImageKey = GlobalKey();
  static final GlobalKey festivalSharingImageKey = GlobalKey();
  static final FestivalService _festivalService = FestivalService();

  // Helper method to show loading indicator
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
      createdAt: DateTime.now(),
    );
  }

  // Handle festival selection with subscription check
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
        showFestivalConfirmationDialog(
          context,
          festival,
              () => onFestivalSelected(festival),
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

  // Function to capture the festival image with user details
  static Future<Uint8List?> captureFestivalImage() async {
    return captureFestivalImageFromContext(festivalImageKey.currentContext!);
  }

  // Show rating dialog for festivals
  static Future<void> _showRatingDialog(
      BuildContext context, FestivalPost festival) async {
    double rating = 0;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Rate This Festival Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'How would you rate your experience with this festival post?'),
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
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text('Submit'),
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
                content: Text('Thanks for your rating!'),
                backgroundColor: Colors.green,
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
                content: Text('Failed to submit rating: ${error.toString()}'),
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
      final festivalRef =
      FirebaseFirestore.instance.collection('festivals').doc(festivalId);

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
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
  static void showFestivalConfirmationDialog(
      BuildContext context,
      FestivalPost festival,
      VoidCallback onCreatePressed,
      ) async {
    // Add to recent templates when showing confirmation dialog
    try {
      // Convert festival to quote template format for recent templates
      QuoteTemplate template = _convertFestivalToQuoteTemplate(festival);
      await RecentTemplateService.addRecentTemplate(template);
      print('Added festival to recents in confirmation dialog: ${festival.id}');
    } catch (e) {
      print('Error adding festival to recents in confirmation dialog: $e');
    }

    // Show loading indicator
    showLoadingIndicator(context);

    try {
      bool isPaidUser = await _festivalService.isUserSubscribed();

      User? currentUser = FirebaseAuth.instance.currentUser;

      // Default values from Firebase Auth
      String defaultUserName = currentUser?.displayName ?? context.loc.user;
      String defaultProfileImageUrl = currentUser?.photoURL ?? '';

      String userName = defaultUserName;
      String userProfileImageUrl = defaultProfileImageUrl;

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
            }

            // Get profile image from Firestore with fallback
            if (userData.containsKey('profileImage') && userData['profileImage'] != null && userData['profileImage'].toString().isNotEmpty) {
              userProfileImageUrl = userData['profileImage'];
            }
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      // Hide loading indicator before showing dialog
      hideLoadingIndicator(context);

      // Continue with the rest of your method using userName and userProfileImageUrl
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
                            RepaintBoundary(
                              key: festivalImageKey,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          height: 400,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image:
                                              NetworkImage(festival.imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          child: isPaidUser
                                              ? Stack(
                                            children: [
                                              // Branded corner mark for paid users
                                              Positioned(
                                                bottom: 10,
                                                right: 10,
                                                child: Container(
                                                  padding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 10,
                                                        backgroundImage: userProfileImageUrl
                                                            .isNotEmpty
                                                            ? NetworkImage(
                                                            userProfileImageUrl)
                                                            : AssetImage(
                                                            'assets/profile_placeholder.png')
                                                        as ImageProvider,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        userName,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                          Colors.white,
                                                          fontWeight:
                                                          FontWeight
                                                              .bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
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
                                        onPressed: () async {
                                          Navigator.of(context).pop();

                                          try {
                                            // Try to add to recent templates, but don't wait for it to complete
                                            // before navigating - this prevents getting stuck if there's an issue
                                            QuoteTemplate template = _convertFestivalToQuoteTemplate(festival);
                                            RecentTemplateService.addRecentTemplate(template).catchError((error) {
                                              print('Error adding to recents, but continuing: $error');
                                            });

                                            // Navigate to edit screen immediately
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => EditScreen(
                                                  title: 'Edit Festival Post',
                                                  templateImageUrl: festival.imageUrl,
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            print('Error navigating to edit screen: $e');
                                            // Show error if needed
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error opening template for editing'))
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: Text('Create'),
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                    SizedBox(
                                      width: 100,
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 0,
                                          side: BorderSide(
                                              color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(24),
                                          ),
                                          padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text('Cancel'),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // Share Button - navigates to share page
                                Center(
                                  child: SizedBox(
                                    width: 140,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FestivalSharingPage(
                                                  festival: festival,
                                                  userName: userName,
                                                  userProfileImageUrl:
                                                  userProfileImageUrl,
                                                  isPaidUser: isPaidUser,
                                                ),
                                          ),
                                        );
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
                                        padding:
                                        EdgeInsets.symmetric(vertical: 12),
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
          content: Text('Error initializing festivals: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}