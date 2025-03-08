import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mtquotes/screens/Templates/quote_template.dart';

class TemplateConfirmationDialog extends StatelessWidget {
  final QuoteTemplate template;
  final VoidCallback onCreate;
  final VoidCallback onCancel;
  final String userName;

  const TemplateConfirmationDialog({
    Key? key,
    required this.template,
    required this.onCreate,
    required this.onCancel,
    this.userName = '',
  }) : super(key: key);

  Future<void> shareTemplate() async {
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

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
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
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(template.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      userName.isEmpty ? 'Your Name' : userName,
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
                    Text(
                      'Do you wish to continue?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onCreate,
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
                        SizedBox(height: 12),
                        // Share Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: shareTemplate, // Call the share function
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Share'),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onCancel,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
