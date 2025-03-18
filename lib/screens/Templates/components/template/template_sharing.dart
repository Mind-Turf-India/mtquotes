import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class TemplateSharingPage extends StatefulWidget {
  final QuoteTemplate template;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;

  TemplateSharingPage({
    Key? key,
    required this.template,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
  }) : super(key: key);

  @override
  _TemplateSharingPageState createState() => _TemplateSharingPageState();
}

class _TemplateSharingPageState extends State<TemplateSharingPage> {
  final GlobalKey _brandedImageKey = GlobalKey();
  ui.Image? _originalImage;
  double _aspectRatio = 16 / 9; // Default aspect ratio until image loads
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
  }

  // Load the original image to get its dimensions
  Future<void> _loadOriginalImage() async {
    try {
      final http.Response response = await http.get(Uri.parse(widget.template.imageUrl));
      if (response.statusCode == 200) {
        final decodedImage = await decodeImageFromList(response.bodyBytes);
        setState(() {
          _originalImage = decodedImage;
          _aspectRatio = decodedImage.width / decodedImage.height;
          _imageLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading original image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Template'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                            child: Text('Share the template without personal branding'),
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
                      // Preview of template without branding but with watermark
                      AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(widget.template.imageUrl),
                              fit: BoxFit.contain, // Changed to contain to avoid cropping
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Preview of watermark
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.2,
                                  child: Center(
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Free share button only
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _shareTemplate(
                            context,
                            isPaid: false,
                          ),
                          icon: Icon(Icons.share),
                          label: Text('Share Basic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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


              // Premium sharing option (moved to the bottom)
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
                    color: widget.isPaidUser ? Colors.blue : Colors.grey.shade300,
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
                            child: Text('Include your name and profile picture on the template'),
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
                            child: Text('No watermark - clean professional look'),
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
                      // Premium template preview with branding (used for capturing)
                      // This is where we fix the cropping issue
                      RepaintBoundary(
                        key: _brandedImageKey,
                        child: AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(widget.template.imageUrl),
                                fit: BoxFit.contain, // Changed to contain to avoid cropping
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
                                          backgroundImage: widget.userProfileImageUrl.isNotEmpty
                                              ? NetworkImage(widget.userProfileImageUrl)
                                              : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          widget.userName,
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
                        ),
                      ),
                      SizedBox(height: 16),
                      // Share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.isPaidUser
                              ? () => _shareTemplate(
                            context,
                            isPaid: true,
                          )
                              : () => Navigator.pushNamed(context, '/subscription'),
                          icon: Icon(widget.isPaidUser ? Icons.share : Icons.lock),
                          label: Text(widget.isPaidUser ? 'Share Now' : 'Upgrade to Pro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isPaidUser ? Colors.blue : Colors.blue,
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
            ],
          ),
        ),
      ),
    );
  }

  // Method to capture widget as image with branding
  Future<Uint8List?> _captureBrandedImage() async {
    try {
      final RenderRepaintBoundary boundary = _brandedImageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Use a higher pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing branded image: $e');
      return null;
    }
  }

  // Method to add branding to image programmatically for paid users
  Future<Uint8List?> _addBrandingToImage(Uint8List originalImageBytes) async {
    try {
      // Decode the original image
      final ui.Image originalImage = await decodeImageFromList(originalImageBytes);

      // Create a recorder and canvas with the ORIGINAL image dimensions
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the original image with its full dimensions
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Download profile image if available
      ui.Image? profileImage;
      if (widget.userProfileImageUrl.isNotEmpty) {
        try {
          final http.Response response = await http.get(Uri.parse(widget.userProfileImageUrl));
          if (response.statusCode == 200) {
            profileImage = await decodeImageFromList(response.bodyBytes);
          }
        } catch (e) {
          print('Error loading profile image: $e');
        }
      }

      // Create branding container background
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();
      final double brandingWidth = width * 0.4;
      final double brandingHeight = height * 0.06;
      final double brandingX = width - brandingWidth - 10;
      final double brandingY = height - brandingHeight - 10;

      // Draw branding background
      final Paint bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(brandingX, brandingY, brandingWidth, brandingHeight),
          Radius.circular(12),
        ),
        bgPaint,
      );

      // Draw profile image if available
      if (profileImage != null) {
        final double profileSize = brandingHeight * 0.8;
        final double profileX = brandingX + 8;
        final double profileY = brandingY + (brandingHeight - profileSize) / 2;

        // Draw circle for profile image
        final Paint circlePaint = Paint()
          ..color = Colors.white;
        canvas.drawCircle(
          Offset(profileX + profileSize / 2, profileY + profileSize / 2),
          profileSize / 2,
          circlePaint,
        );

        // Draw the profile image in a circle
        canvas.save(); // Save the canvas state before clipping
        final Path clipPath = Path()
          ..addOval(Rect.fromLTWH(profileX, profileY, profileSize, profileSize));
        canvas.clipPath(clipPath);
        canvas.drawImageRect(
          profileImage,
          Rect.fromLTWH(0, 0, profileImage.width.toDouble(), profileImage.height.toDouble()),
          Rect.fromLTWH(profileX, profileY, profileSize, profileSize),
          Paint(),
        );
        canvas.restore(); // Restore canvas state after clipping
      }

      // Draw username text
      final double textX = profileImage != null
          ? brandingX + 8 + brandingHeight * 0.8 + 4
          : brandingX + 8;
      final double textY = brandingY + brandingHeight / 2;

      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: brandingHeight * 0.4,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(widget.userName);

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: brandingWidth - (profileImage != null ? brandingHeight * 0.8 + 12 : 8)));

      canvas.drawParagraph(paragraph, Offset(textX, textY - paragraph.height / 2));

      // Convert canvas to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image renderedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert image to bytes
      final ByteData? byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error adding branding to image: $e');
      return null;
    }
  }

  // Method to add watermark to image for free users
  Future<Uint8List?> _addWatermarkToImage(Uint8List originalImageBytes) async {
    try {
      // Decode the original image
      final ui.Image originalImage = await decodeImageFromList(originalImageBytes);

      // Create a recorder and canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Load the logo watermark
      final ByteData logoData = await rootBundle.load('assets/logo.png');
      final ui.Image logo = await decodeImageFromList(logoData.buffer.asUint8List());

      // Calculate size and position for the watermark in top right corner
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();
      final double watermarkSize = width * 0.2; // 20% of the image width (smaller than before)
      final double watermarkX = width - watermarkSize - 16;  // Position from right edge with padding
      final double watermarkY = 16; // Position from top with padding

      // Apply semi-transparent effect to the watermark
      final Paint watermarkPaint = Paint();

      // Draw the watermark
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(watermarkX, watermarkY, watermarkSize, watermarkSize),
        watermarkPaint,
      );

      // Convert canvas to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image renderedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert image to bytes
      final ByteData? byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error adding watermark to image: $e');
      return null;
    }
  }

  // Integrated sharing functionality with proper branding for paid users and watermark for free users
  Future<void> _shareTemplate(BuildContext context, {required bool isPaid}) async {
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

      // Download the original template image first
      final response = await http.get(Uri.parse(widget.template.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      final originalImageBytes = response.bodyBytes;

      if (isPaid) {
        try {
          // Make sure UI is fully rendered before capture
          await Future.delayed(Duration(milliseconds: 100));

          // First try to capture the branded template widget directly
          imageBytes = await _captureBrandedImage();

          // If direct widget capture fails, try programmatic branding approach
          if (imageBytes == null) {
            print('Direct capture returned null, trying programmatic branding');
            imageBytes = await _addBrandingToImage(originalImageBytes);
          }

          // If both approaches fail, fall back to the original image
          if (imageBytes == null) {
            print('Both branding approaches failed, falling back to direct download');
            imageBytes = originalImageBytes;
          }
        } catch (e) {
          print('Error in premium capture: $e, falling back to direct download');
          imageBytes = originalImageBytes;
        }
      } else {
        // For free users, add the watermark to the template image
        try {
          imageBytes = await _addWatermarkToImage(originalImageBytes);

          // If watermarking fails, fall back to the original image
          if (imageBytes == null) {
            print('Watermark failed, falling back to direct download');
            imageBytes = originalImageBytes;
          }
        } catch (e) {
          print('Error adding watermark: $e, falling back to direct download');
          imageBytes = originalImageBytes;
        }
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
     final tempFile = File('${tempDir.path}/shared_template.png');


     // Save image as file
     await tempFile.writeAsBytes(imageBytes);


      // Share directly based on user type
      if (isPaid) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing quote template by ${widget.userName}!',
        );
      } else {
        // For free users, share with watermark
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing quote template!',
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


     print('Error sharing template: $e');


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
        _submitRating(value, widget.template);

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


 // Submit rating - this calls the TemplateHandler version
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
}


