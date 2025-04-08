import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_service.dart';
import 'package:mtquotes/screens/Templates/components/totd/totd_handler.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../Create_Screen/components/details_screen.dart';
import '../../../Create_Screen/edit_screen_create.dart';
import '../recent/recent_service.dart';
import 'package:transparent_image/transparent_image.dart';

class TOTDSharingPage extends StatefulWidget {
  final TimeOfDayPost post;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;
  final GlobalKey _brandedImageKey;

  TOTDSharingPage({
    Key? key,
    required this.post,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
    GlobalKey? brandedImageKey,
  })  : _brandedImageKey = brandedImageKey ?? GlobalKey(),
        super(key: key);

  @override
  _TOTDSharingPageState createState() => _TOTDSharingPageState();
}

class _TOTDSharingPageState extends State<TOTDSharingPage> {
  ui.Image? _originalImage;
  double _aspectRatio = 16 / 9; // Default aspect ratio until image loads
  bool _imageLoaded = false;
  bool _isImageLoading = true; // Add loading state tracker

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
    _addToRecentTemplates();
  }

  // Add this method to add the TOTD post to recent templates
  Future<void> _addToRecentTemplates() async {
    try {
      // Convert TOTD post to quote template format for recent templates
      QuoteTemplate template = QuoteTemplate(
        id: widget.post.id,
        title: widget.post.title,
        imageUrl: widget.post.imageUrl,
        isPaid: widget.post.isPaid,
        category: "Time of Day", // Use a standard category for TOTD posts
        createdAt: DateTime.now(),
      );

      await RecentTemplateService.addRecentTemplate(template);
      print('Added TOTD post to recents from sharing page: ${widget.post.id}');
    } catch (e) {
      print('Error adding TOTD post to recents from sharing page: $e');
    }
  }

  // Load the original image to get its dimensions
  Future<void> _loadOriginalImage() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final http.Response response = await http.get(Uri.parse(widget.post.imageUrl));
      if (response.statusCode == 200) {
        final decodedImage = await decodeImageFromList(response.bodyBytes);

        if (mounted) {
          setState(() {
            _originalImage = decodedImage;
            _aspectRatio = decodedImage.width / decodedImage.height;
            _imageLoaded = true;
            _isImageLoading = false;
          });
        }
      } else {
        // Handle error case
        print('Failed to load image: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isImageLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading original image: $e');
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  // Helper method to build consistent image containers
  Widget _buildImageContainer({
    required Widget child,
    required double aspectRatio,
    BorderRadius? borderRadius,
  }) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final Color cardBackgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor = isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final Color dividerColor = isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
    final Color iconColor = isDarkMode ? AppColors.darkIcon : AppColors.lightIcon;

    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          context.loc.shareContent,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Free sharing option (moved to the top)
              Text(
                context.loc.freeSharing,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: cardBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.basicSharing,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.shareWithoutPersonalBranding,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.noPersonalBranding,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.standardQualityExport,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Preview of content without branding but with watermark - FIXED
                      _buildImageContainer(
                        aspectRatio: _aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image with proper sizing
                            FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: NetworkImage(widget.post.imageUrl),
                              fit: BoxFit.contain,
                              fadeInDuration: Duration(milliseconds: 300),
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    'Error loading image',
                                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                                  ),
                                );
                              },
                            ),

                            // Watermark in top right
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Opacity(
                                opacity: 0.6,
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),
                      // Free share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePost(
                            context,
                            isPaid: false,
                          ),
                          icon: Icon(Icons.share),
                          label: Text( context.loc.shareBasic,
                            ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
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
                    Expanded(child: Divider(color: dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        context.loc.or,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize - 2,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: dividerColor)),
                  ],
                ),
              ),

              // Premium sharing option
              Text(
                context.loc.premiumSharing,
                style: TextStyle(
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: cardBackgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: widget.isPaidUser ? AppColors.primaryBlue : dividerColor,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.shareWithYourBranding,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.includename,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.personalizedSharingMessage,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.noWatermarkCleanLook,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.loc.highQualityExport,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Premium template preview with info box - FIXED
                      FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.email?.replaceAll('.', '_'))
                              .get(),
                          builder: (context, snapshot) {
                            String userName = '';
                            String userProfileUrl = '';
                            String userLocation = '';

                            // Extract user data if available
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              userName = userData['name'] ?? '';
                              userProfileUrl = userData['profileImage'] ?? '';
                              userLocation = userData['location'] ?? '';
                            }

                            return RepaintBoundary(
                              key: widget._brandedImageKey,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.getDividerColor(isDarkMode)),
                                ),
                                child: Column(
                                  children: [
                                    // Template image with proper aspect ratio - FIXED
                                    _buildImageContainer(
                                      aspectRatio: _aspectRatio,
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                          image: DecorationImage(
                                            image: NetworkImage(widget.post.imageUrl),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Info box at the bottom
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.getSurfaceColor(isDarkMode),
                                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                                      ),
                                      child: Row(
                                        children: [
                                          // Profile image
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundImage: userProfileUrl.isNotEmpty
                                                ? NetworkImage(userProfileUrl)
                                                : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                                            onBackgroundImageError: (exception, stackTrace) {
                                              print('Error loading profile image: $exception');
                                              // Optionally log the error or handle it gracefully
                                            },
                                          ),
                                          SizedBox(width: 12),

                                          // User details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName.isNotEmpty ? userName : widget.userName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: fontSize,
                                                    color: AppColors.getTextColor(isDarkMode),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                      SizedBox(height: 16),
                      // Premium share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.isPaidUser
                              ? () => _sharePost(
                            context,
                            isPaid: true,
                          )
                              : () => Navigator.pushNamed(context, '/subscription'),
                          icon: Icon(widget.isPaidUser ? Icons.share : Icons.lock),
                          label: Text(widget.isPaidUser ? context.loc.shareNow
                              : context.loc.upgradeToPro,),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
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

  // Info box component for the TOTD sharing page
  Widget _buildInfoBox({
    required String title,
    required VoidCallback onCreatePressed,
    required VoidCallback onSharePressed,
    required VoidCallback onCancelPressed,
    required Widget contentWidget,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content widget (TOTD image with branding)
            contentWidget,
            SizedBox(height: 24),

            // Title if provided
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDarkMode),
              ),
            ),
            // SizedBox(height: 8),
            //
            // Text(
            //   context.loc.doYouWishToContinue,
            //   style: TextStyle(
            //     fontSize: fontSize,
            //     fontWeight: FontWeight.w500,
            //     color: AppColors.getTextColor(isDarkMode),
            //   ),
            // ),
            // SizedBox(height: 16),

            // Buttons
            // Column(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         SizedBox(
            //           width: 100,
            //           child: ElevatedButton(
            //             onPressed: onCreatePressed,
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: AppColors.primaryBlue,
            //               foregroundColor: Colors.white,
            //               elevation: 0,
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(24),
            //               ),
            //             ),
            //             child: Text(context.loc.create),
            //           ),
            //         ),
            //         SizedBox(width: 40),
            //         SizedBox(
            //           width: 100,
            //           child: ElevatedButton(
            //             onPressed: onCancelPressed,
            //             style: ElevatedButton.styleFrom(
            //               backgroundColor: AppColors.getSurfaceColor(isDarkMode),
            //               foregroundColor: AppColors.getTextColor(isDarkMode),
            //               elevation: 0,
            //               side: BorderSide(color: AppColors.getDividerColor(isDarkMode)),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(24),
            //               ),
            //               padding: EdgeInsets.symmetric(vertical: 12),
            //             ),
            //             child: Text(context.loc.cancel),
            //           ),
            //         ),
            //       ],
            //     ),
            //     SizedBox(height: 12),
            //     // Share Button
            //     Center(
            //       child: SizedBox(
            //         width: 140,
            //         child: ElevatedButton.icon(
            //           onPressed: onSharePressed,
            //           icon: Icon(Icons.share),
            //           label: Text(context.loc.share),
            //           style: ElevatedButton.styleFrom(
            //             backgroundColor: AppColors.primaryBlue,
            //             foregroundColor: Colors.white,
            //             elevation: 0,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(24),
            //             ),
            //             padding: EdgeInsets.symmetric(vertical: 12),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  // Method to show the info box dialog
  void showTOTDInfoBox(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
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
              child: _buildInfoBox(
                title: widget.post.title,
                onCreatePressed: () {
                  Navigator.of(context).pop();
                  // Convert TimeOfDayPost to QuoteTemplate for compatibility with DetailsScreen
                  QuoteTemplate template = QuoteTemplate(
                    id: widget.post.id,
                    title: widget.post.title,
                    imageUrl: widget.post.imageUrl,
                    isPaid: widget.post.isPaid,
                    category: "Time of Day",
                    createdAt: DateTime.fromMillisecondsSinceEpoch(
                        widget.post.createdAt.millisecondsSinceEpoch),
                  );

                  // Navigate to DetailsScreen instead of directly to EditScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsScreen(
                        template: template,
                        isPaidUser: widget.isPaidUser,
                      ),
                    ),
                  );
                },
                onSharePressed: () {
                  Navigator.of(context).pop();
                  _sharePost(context, isPaid: widget.isPaidUser);
                },
                onCancelPressed: () => Navigator.of(context).pop(),
                contentWidget: _buildImageContainer(
                  aspectRatio: _aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(widget.post.imageUrl),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      if (widget.isPaidUser)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundImage: widget
                                        .userProfileImageUrl.isNotEmpty
                                        ? NetworkImage(
                                        widget.userProfileImageUrl)
                                        : AssetImage(
                                        'assets/profile_placeholder.png')
                                    as ImageProvider,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.userName,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to capture widget as image with branding
  Future<Uint8List?> _captureBrandedImage() async {
    try {
      final RenderRepaintBoundary boundary = widget._brandedImageKey.currentContext!
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

      // Create a recorder and canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the original image - use the full size
      final Rect originalRect = Rect.fromLTWH(0, 0,
          originalImage.width.toDouble(), originalImage.height.toDouble());
      canvas.drawImageRect(
        originalImage,
        originalRect,
        originalRect,
        Paint(),
      );

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

      // Create branding container background - scale appropriately to the original image
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();

      // Make branding proportional to image size
      final double brandingWidth = width * 0.4;
      final double brandingHeight = height * 0.06;
      final double brandingX = width - brandingWidth - width * 0.025; // 2.5% padding
      final double brandingY = height - brandingHeight - height * 0.025; // 2.5% padding

      // Draw branding background
      final Paint bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
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
        final Paint circlePaint = Paint()..color = Colors.white;
        canvas.drawCircle(
          Offset(profileX + profileSize / 2, profileY + profileSize / 2),
          profileSize / 2,
          circlePaint,
        );

        // Save canvas state before clipping
        canvas.save();

        // Draw the profile image in a circle
        final Path clipPath = Path()
          ..addOval(Rect.fromLTWH(profileX, profileY, profileSize, profileSize));
        canvas.clipPath(clipPath);

        canvas.drawImageRect(
          profileImage,
          Rect.fromLTWH(0, 0, profileImage.width.toDouble(),
              profileImage.height.toDouble()),
          Rect.fromLTWH(profileX, profileY, profileSize, profileSize),
          Paint(),
        );

        // Restore canvas state after clipping
        canvas.restore();
      }

      // Draw username text
      final double textX = profileImage != null
          ? brandingX + 8 + brandingHeight * 0.8 + 4
          : brandingX + 8;
      final double textY = brandingY + brandingHeight / 2;

      // Calculate font size based on image dimensions
      final double fontSize = brandingHeight * 0.4;

      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontSize: fontSize,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white))
        ..addText(widget.userName);

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(
            width: brandingWidth - (profileImage != null ? brandingHeight * 0.8 + 12 : 8)));

      canvas.drawParagraph(paragraph, Offset(textX, textY - paragraph.height / 2));

      // Convert canvas to image - use the original dimensions
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
      final double watermarkSize = width * 0.2; // 20% of the image width
      final double watermarkX = width - watermarkSize - 16; // Position from right edge with padding
      final double watermarkY = 16; // Position from top with padding

      // Draw the watermark
      final Paint watermarkPaint = Paint();
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
      print ('Error adding watermark to image: $e');
      return null;
    }
  }

  // Integrated sharing functionality
  Future<void> _sharePost(BuildContext context, {required bool isPaid}) async {
    try {
      // Add to recent templates again to ensure it's captured when sharing
      await _addToRecentTemplates();

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

      // Download the original image first
      final response = await http.get(Uri.parse(widget.post.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      final originalImageBytes = response.bodyBytes;
      Uint8List? imageBytes;

      if (isPaid) {
        try {
          // For premium users, we want to capture the UI exactly as it appears in the preview
          // Make sure UI is fully rendered before capture
          await Future.delayed(Duration(milliseconds: 200));

          // Use the repaint boundary to capture the branded preview as-is
          imageBytes = await _captureBrandedImage();

          // Only if that fails, fall back to programmatic approach
          if (imageBytes == null) {
            print('Direct capture returned null, trying programmatic branding');
            imageBytes = await _addBrandingToImage(originalImageBytes);
          }

          if (imageBytes == null) {
            print('Both branding approaches failed, falling back to direct download');
            imageBytes = originalImageBytes;
          }
        } catch (e) {
          print('Error in premium capture: $e, falling back to direct download');
          imageBytes = originalImageBytes;
        }
      } else {
        // For free users, we need to render the watermark exactly as in the preview
        try {
          imageBytes = await _addWatermarkToImage(originalImageBytes);

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
      final tempFile = File('${tempDir.path}/shared_content.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaid) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing content by ${widget.userName}!',
        );
      } else {
        // For free users, share with watermark
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing content!',
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

      print('Error sharing content: $e');

      // Show error message
      if (context.mounted) {
        // Close loading dialog if open
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }
  }

  // Rating dialog implementation
  Future<void> _showRatingDialog(BuildContext context) async {
    double rating = 0;
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor = isDarkMode ? AppColors.darkText : AppColors.lightText;

    // Get font size from TextSizeProvider
    final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
    final fontSize = textSizeProvider.fontSize;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(context.loc.rateThisContent,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.loc.howWouldYouRateExperience,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: textColor,
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
                child: Text(
                  context.loc.skip,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(rating); // Close the dialog
                  Navigator.of(context).pushReplacementNamed('/nav_bar');
                },
                child: Text(context.loc.submit),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Submit rating
        _submitRating(value, widget.post);

        // Show thank you message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.loc.thanksForYourRating),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  // Submit rating
  static Future<void> _submitRating(double rating, TimeOfDayPost post) async {
    try {
      final DateTime now = DateTime.now();

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'postId': post.id,
        'rating': rating,
        'createdAt': now, // Firestore will convert this to Timestamp
        'imageUrl': post.imageUrl,
        'title': post.title,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // Get user ID if logged in
      };

      await FirebaseFirestore.instance
          .collection('totd_ratings')
          .add(ratingData);

      print('Rating submitted: $rating for post ${post.title}');

      // Update the post's average rating
      await _updatePostAverageRating(post.id, rating);
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  static Future<void> _updatePostAverageRating(
      String postId, double newRating) async {
    try {
      // Get reference to the post document
      final postRef = FirebaseFirestore.instance
          .collection('time_of_day_posts')
          .doc(postId);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current post data
        final postSnapshot = await transaction.get(postRef);

        if (postSnapshot.exists) {
          final data = postSnapshot.data() as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = data['averageRating']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

          // Update the post with the new average rating
          transaction.update(postRef, {
            'averageRating': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('Updated post average rating successfully');
    } catch (e) {
      print('Error updating post average rating: $e');
    }
  }
}