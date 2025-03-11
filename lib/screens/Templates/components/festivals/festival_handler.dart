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

class FestivalHandler {
  static final GlobalKey festivalImageKey = GlobalKey();
  static final GlobalKey festivalSharingImageKey = GlobalKey();
  static final FestivalService _festivalService = FestivalService();

  // Handle festival selection with subscription check
  static Future<void> handleFestivalSelection(
    BuildContext context,
    FestivalPost festival,
    Function(FestivalPost) onFestivalSelected,
  ) async {
    bool isSubscribed = await _festivalService.isUserSubscribed();

    if (festival.isPaid && !isSubscribed) {
      // Show subscription popup
      SubscriptionPopup.show(context);
    } else {
      // Show confirmation dialog with preview
      showFestivalConfirmationDialog(
        context,
        festival,
        () => onFestivalSelected(festival),
      );
      
      // Increment view count
      // _festivalService.incrementFestivalViewCount(festival.id);
    }
  }

  // Function to capture the festival image with user details
static Future<Uint8List?> captureFestivalImage() async {
  return captureFestivalImageFromContext(festivalImageKey.currentContext!);
}

  // Show rating dialog for festivals
  static Future<void> _showRatingDialog(BuildContext context, FestivalPost festival) async {
    double rating = 0;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate This Festival Post'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How would you rate your experience with this festival post?'),
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
          }
        );
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Submit rating
        _submitRating(value, festival);

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

  // Submit rating to Firestore
  static Future<void> _submitRating(double rating, FestivalPost festival) async {
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
    }
  }

  // Update average rating in Firestore
  static Future<void> _updateFestivalAverageRating(String festivalId, double newRating) async {
    try {
      // Get reference to the festival document
      final festivalRef = FirebaseFirestore.instance.collection('festivals').doc(festivalId);

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
          double newAvgRating = ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

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
      // If userName or userProfileImageUrl are null, get them from Firebase
      if (userName == null || userProfileImageUrl == null) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        userName = currentUser?.displayName ?? context.loc.user;
        userProfileImageUrl = currentUser?.photoURL ?? '';
      }

      // Check if we're coming from the sharing page - if not, navigate to it
      if (!(Navigator.of(context).widget is FestivalSharingPage)) {
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

      // If we're already on the sharing page, perform the actual sharing
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
      Navigator.of(context, rootNavigator: true).pop();

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
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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

  static Future<Uint8List?> captureFestivalImageFromContext(BuildContext context) async {
  try {
    // Determine if we're on the sharing page or dialog
    GlobalKey keyToUse = Navigator.of(context).widget is FestivalSharingPage 
      ? festivalSharingImageKey 
      : festivalImageKey;
      
    final RenderRepaintBoundary boundary = keyToUse.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
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
    bool isPaidUser = await _festivalService.isUserSubscribed();

    User? currentUser = FirebaseAuth.instance.currentUser;
    String userName = currentUser?.displayName ?? context.loc.user;
    String userProfileImageUrl = currentUser?.photoURL ?? '';

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
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(festival.imageUrl),
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
                                                      padding: EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.6),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 10,
                                                            backgroundImage: userProfileImageUrl.isNotEmpty
                                                                ? NetworkImage(userProfileImageUrl)
                                                                : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            userName,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
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
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => EditScreen(
                                              title: 'Edit Festival Post',
                                              templateImageUrl: festival.imageUrl,
                                            ),
                                          ),
                                        );
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
                              // Share Button - navigates to share page
                              Center(
                                child: SizedBox(
                                  width: 140,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => FestivalSharingPage(
                                            festival: festival,
                                            userName: userName,
                                            userProfileImageUrl: userProfileImageUrl,
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

  // Method to initialize festivals if none exist
  static Future<void> initializeFestivalsIfNeeded() async {
    final festivals = await _festivalService.getActiveFestivals(); // if there is no festival new should have some other general templates.
    // Add any initialization logic here
  }
}