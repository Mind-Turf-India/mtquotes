import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mtquotes/screens/Templates/quote_template.dart';
import 'package:mtquotes/screens/Templates/template_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class TemplateHandler {
  // Handle template selection with subscription check
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
          content: Text('This template requires a subscription. Subscribe to access all premium templates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to subscription page
                // Replace with your actual subscription page
                Navigator.pushNamed(context, '/subscription');
              },
              child: Text('Subscribe'),
            ),
          ],
        ),
      );
    } else {
      // Show confirmation dialog with preview
      showTemplateConfirmationDialog(
        context,
        template,
            () => onAccessGranted(template),
      );
    }
  }

  // Method to share template
  static Future<void> shareTemplate(QuoteTemplate template) async {
    try {
      // Download the image from the URL
      final response = await http.get(Uri.parse(template.imageUrl));
      if (response.statusCode == 200) {
        // Get temp directory
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/shared_template.jpg');

        // Save image as file
        await tempFile.writeAsBytes(response.bodyBytes);

        // Share the image
        await Share.shareXFiles([XFile(tempFile.path)], text: 'Check out this quote template!');
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error sharing template: $e');
    }
  }

  // Method to show the template confirmation dialog
  static void showTemplateConfirmationDialog(
      BuildContext context,
      QuoteTemplate template,
      VoidCallback onCreatePressed,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Template Preview
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
                        // Template Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              // Template Image only (heart icon and title removed)
                              Container(
                                height: 400,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(template.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Heart icon and title have been removed from here
                              ),

                              // User Profile Section
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                child: Row(
                                  children: [
                                    // Profile Image
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                                      onBackgroundImageError: (e, stackTrace) {
                                        // Fallback for missing asset
                                        return;
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    // Username TextField
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Aakanksha', // Replace with dynamic username if available
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Confirmation Text
                        Text(
                          'Do you wish to continue?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 16),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Cancel Button
                            Expanded(
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
                            SizedBox(width: 16),
                            // Share Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  shareTemplate(template);
                                },
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
                                child: Text('Share'),
                              ),
                            ),
                            SizedBox(width: 16,),
                            // Create Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onCreatePressed();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('Create'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to initialize templates if none exist
  static Future<void> initializeTemplatesIfNeeded() async {
    final templateService = TemplateService();
    final templates = await templateService.fetchRecentTemplates();
  }
}