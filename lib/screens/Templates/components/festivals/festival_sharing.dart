import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class FestivalSharingPage extends StatelessWidget {
  final FestivalPost festival;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;

  const FestivalSharingPage({
    Key? key,
    required this.festival,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Festival Post'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Free sharing option (moved to the top)
              Text(
                'Free Sharing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic sharing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Share the festival post without personal branding'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('No personal branding or watermark'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Standard quality export'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Preview of festival without branding
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(festival.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Free share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _shareFestival(
                            context,
                            isPaid: false,
                          ),
                          icon: Icon(Icons.share),
                          label: Text('Share Basic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // Premium sharing option
              Text(
                'Premium Sharing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPaidUser ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share with your branding',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Include your name and profile picture on the festival post'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Personalized sharing message'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('High quality image export'),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Preview of festival with branding
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(festival.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
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
                        ),
                      ),
                      SizedBox(height: 16),
                      // Premium share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isPaidUser
                              ? () => _shareFestival(
                            context,
                            isPaid: true,
                          )
                              : () => Navigator.pushNamed(context, '/subscription'),
                          icon: Icon(isPaidUser ? Icons.share : Icons.lock),
                          label: Text(isPaidUser ? 'Share Now' : 'Upgrade to Pro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaidUser ? Colors.blue : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Customize option
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditScreen(
                          title: 'Edit Festival Post',
                          templateImageUrl: festival.imageUrl,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit),
                  label: Text(
                    context.loc.customize,
                    style: GoogleFonts.poppins(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sharing implementation
  Future<void> _shareFestival(BuildContext context, {required bool isPaid}) async {
    try {
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

      if (isPaid) {
        try {
          // For paid users, first try to capture the whole festival including profile details
          imageBytes = await FestivalHandler.captureFestivalImage();

          // If imageBytes is null, fall back to the original image
          if (imageBytes == null) {
            print('Festival capture returned null, falling back to direct download');
            final response = await http.get(Uri.parse(festival.imageUrl));

            if (response.statusCode == 200) {
              imageBytes = response.bodyBytes;
            }
          }
        } catch (e) {
          print('Error in premium capture: $e, falling back to direct download');
          // If festival capture fails, fall back to direct download
          final response = await http.get(Uri.parse(festival.imageUrl));

          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          } else {
            throw Exception('Failed to load image after festival capture failed');
          }
        }
      } else {
        // For free users, just download the original festival image
        final response = await http.get(Uri.parse(festival.imageUrl));

        if (response.statusCode != 200) {
          throw Exception('Failed to load image');
        }
        imageBytes = response.bodyBytes;
      }

      // Close loading dialog
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (imageBytes == null) {
        throw Exception('Failed to process image');
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_festival.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaid) {
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
        await _showRatingDialog(context);
      }

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error sharing festival: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Rating dialog implementation
  Future<void> _showRatingDialog(BuildContext context) async {
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
                      Navigator.of(context).pushReplacementNamed('/nav_bar');
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

// Submit rating - this calls the FestivalHandler version
  static Future<void> _submitRating(double rating, FestivalPost festival) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'festivalId': festival.id,
        'rating': rating,
        'category': festival.category,
        'createdAt': now,  // Firestore will convert this to Timestamp
        'imageUrl': festival.imageUrl,
        'isPaid': festival.isPaid,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // Get user ID if logged in
      };

      await FirebaseFirestore.instance
          .collection('ratings')
          .add(ratingData);

      // Update the festival's average rating
      await _updateFestivalAverageRating(festival.id, rating);

    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

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
  }}