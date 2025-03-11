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
import 'package:mtquotes/screens/Templates/template_sharing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/quote_template.dart';
import 'package:mtquotes/screens/Templates/template_service.dart';
import '../Create_Screen/edit_screen_create.dart';

class TemplateHandler {
  static final GlobalKey templateImageKey = GlobalKey();

  // Handle template selection with subscription check and directly navigate to edit screen
  static Future<void> handleTemplateSelection(
      BuildContext context,
      QuoteTemplate template,
      Function(QuoteTemplate) onAccessGranted,
      ) async {
    final templateService = TemplateService();
    bool isSubscribed = await templateService.isUserSubscribed();

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
      // Directly navigate to edit screen or call the callback
      onAccessGranted(template);

      // Optional: If you want to directly navigate to edit screen instead of using callback
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => EditScreen(
      //       title: 'Edit Template',
      //       templateImageUrl: template.imageUrl,
      //     ),
      //   ),
      // );
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

// Add this function to submit the rating to your backend
  static Future<void> _submitRating(double rating, QuoteTemplate template) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object using your QuoteTemplate model
      final Map<String, dynamic> ratingData = {
        'templateId': template.id,
        'rating': rating,
        'category': template.category,
        'createdAt': now,  // Firestore will convert this to Timestamp
        'imageUrl': template.imageUrl,
        'isPaid': template.isPaid,
        'title': template.title,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // Get user ID if logged in
      };

      await FirebaseFirestore.instance
          .collection('ratings')
          .add(ratingData);

      // print('Rating submitted: $rating for template ${template.imageUrl}');
      print('Rating submitted: $rating for template ${template.title}');

      // Update the template's average rating
      await _updateTemplateAverageRating(template.id, rating);

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

  // Method to share template
  static Future<void> shareTemplate(
      BuildContext context,
      QuoteTemplate template, {
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
      if (!(Navigator.of(context).widget is TemplateSharingPage)) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TemplateSharingPage(
              template: template,
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
      Navigator.of(context, rootNavigator: true).pop();

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
      if (context.mounted) {
        await _showRatingDialog(context, template);
      }

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error sharing template: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to initialize templates if none exist
  static Future<void> initializeTemplatesIfNeeded() async {
    final templateService = TemplateService();
    final templates = await templateService.fetchRecentTemplates();
    // Add any initialization logic here
  }
}