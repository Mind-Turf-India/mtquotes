
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
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../Create_Screen/edit_screen_create.dart';

class TimeOfDayHandler {
  static final GlobalKey totdImageKey = GlobalKey();

  // Handle TOTD post selection with subscription check
  static Future<void> handleTimeOfDayPostSelection(
      BuildContext context,
      TimeOfDayPost post,
      Function(TimeOfDayPost) onAccessGranted,
      ) async {
    final timeOfDayService = TimeOfDayService();
    bool isSubscribed = await _isUserSubscribed();

    if (post.isPaid && !isSubscribed) {
      // Show subscription dialog/prompt
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Premium Content'),
          content: Text(
              'This content requires a subscription. Subscribe to access all premium time of day posts.'),
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
      showTOTDConfirmationDialog(
        context,
        post,
        () => onAccessGranted(post),
      );
    }
  }

  // Helper method to check if user is subscribed
  static Future<bool> _isUserSubscribed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

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
  static Future<void> _showRatingDialog(BuildContext context, TimeOfDayPost post) async {
    double rating = 0;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Rate This Content'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('How would you rate your experience with this content?'),
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
        // Send rating to backend
        _submitRating(value, post);

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

  // Add this function to submit the rating to your backend
  static Future<void> _submitRating(double rating, TimeOfDayPost post) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'postId': post.id,
        'rating': rating,
        'timeOfDay': post.id.split('_')[0], // Extract time of day from ID
        'createdAt': now,  // Firestore will convert this to Timestamp
        'imageUrl': post.imageUrl,
        'isPaid': post.isPaid,
        'title': post.title,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // Get user ID if logged in
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

  static Future<void> _updateTOTDPostAverageRating(String postId, double newRating) async {
    try {
      // Parse time of day from post ID (assuming format like "morning_post1")
      final parts = postId.split('_');
      if (parts.length < 2) {
        print('Invalid post ID format: $postId');
        return;
      }
      
      final timeOfDay = parts[0];
      
      // Get reference to the TOTD document
      final totdRef = FirebaseFirestore.instance.collection('totd').doc(timeOfDay);

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
            double newAvgRating = ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

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
    try {
      // If userName or userProfileImageUrl are null, get them from Firebase
      if (userName == null || userProfileImageUrl == null) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        userName = currentUser?.displayName ?? context.loc.user;
        userProfileImageUrl = currentUser?.photoURL ?? '';
      }

      // Check if we're coming from the sharing page - if not, navigate to it
      if (!(Navigator.of(context).widget is TOTDSharingPage)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TOTDSharingPage(
              post: post,
              userName: userName ?? context.loc.user,  // Default value if null
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

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

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

      // Show rating dialog after sharing
      await Future.delayed(Duration(milliseconds: 500));
      if (context.mounted) {
        await _showRatingDialog(context, post);
      }

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error sharing TOTD post: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show the TOTD confirmation dialog
  static void showTOTDConfirmationDialog(
      BuildContext context,
      TimeOfDayPost post,
      VoidCallback onCreatePressed,
      ) async {
    bool isPaidUser = await _isUserSubscribed();

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
                                    key: totdImageKey,
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
                                                    image: NetworkImage(post.imageUrl),
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
                                    post.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
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
                                                      title: 'Edit Content',
                                                      templateImageUrl: post.imageUrl,
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
                                      Center(
                                        child: SizedBox(
                                          width: 140,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).pop();
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
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to initialize TOTD posts if none exist
  static Future<void> initializeTOTDPostsIfNeeded() async {
    final timeOfDayService = TimeOfDayService();
    final posts = await timeOfDayService.fetchTimeOfDayPosts();
    // Add any initialization logic here
  }
}
