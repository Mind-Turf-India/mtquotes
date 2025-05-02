import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:mtquotes/screens/Templates/components/festivals/festival_post.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/utils/app_colors.dart';
import '../../../Create_Screen/components/details_screen.dart';
import '../recent/recent_service.dart';
import 'package:transparent_image/transparent_image.dart';

import 'festival_service.dart';

class FestivalSharingPage extends StatefulWidget {
  final FestivalPost festival;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;
  final GlobalKey _brandedImageKey;

  FestivalSharingPage({
    Key? key,
    required this.festival,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
    GlobalKey? brandedImageKey,
  })  : _brandedImageKey = brandedImageKey ?? GlobalKey(),
        super(key: key);

  @override
  _FestivalSharingPageState createState() => _FestivalSharingPageState();
}

class _FestivalSharingPageState extends State<FestivalSharingPage> {
  ui.Image? _originalImage;
  double _aspectRatio = 16 / 9; // Default aspect ratio until image loads
  bool _imageLoaded = false;
  bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
    _addToRecentTemplates();
  }

  // Add this method to add the festival to recent templates
  Future<void> _addToRecentTemplates() async {
    try {
      // Convert festival to quote template format for recent templates
      QuoteTemplate template = QuoteTemplate(
        id: widget.festival.id,
        title: widget.festival.name,
        imageUrl: widget.festival.imageUrl,
        isPaid: widget.festival.isPaid,
        category: widget.festival.category,
        createdAt: DateTime.now(),
      );

      await RecentTemplateService.addRecentTemplate(template);
      print(
          'Added festival to recents from sharing page: ${widget.festival.id}');
    } catch (e) {
      print('Error adding festival to recents from sharing page: $e');
    }
  }

  // Load the original image to get its dimensions
  Future<void> _loadOriginalImage() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final http.Response response =
          await http.get(Uri.parse(widget.festival.imageUrl));
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
        setState(() {
          _isImageLoading = false;
        });
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

  // Helper function to create image container with proper sizing
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

  // Helper function to create properly sized image
  Widget _buildFestivalImage({
    bool showWatermark = false,
    BorderRadius? borderRadius,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color loadingColor = AppColors.primaryBlue;
    final Color loadingBackground =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

    if (_isImageLoading) {
      return _buildImageContainer(
        aspectRatio: _aspectRatio,
        borderRadius: borderRadius,
        child: Center(
          child: CircularProgressIndicator(
            color: loadingColor,
            backgroundColor: loadingBackground,
          ),
        ),
      );
    }

    // Image with proper sizing based on calculated aspect ratio
    Widget imageWidget = Stack(
      fit: StackFit.expand,
      children: [
        // FadeInImage with proper sizing
        FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: NetworkImage(widget.festival.imageUrl),
          fit: BoxFit.contain,
          fadeInDuration: Duration(milliseconds: 300),
          imageErrorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Error loading image',
                style: TextStyle(
                  color: isDarkMode ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            );
          },
        ),

        // Watermark if needed
        if (showWatermark)
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
    );

    return _buildImageContainer(
      aspectRatio: _aspectRatio,
      borderRadius: borderRadius,
      child: imageWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final Color cardBackgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor =
        isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final Color dividerColor =
        isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
    final Color iconColor =
        isDarkMode ? AppColors.darkIcon : AppColors.lightIcon;

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
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
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
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen),
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

                      // Preview of festival with watermark
                      _buildFestivalImage(showWatermark: true),

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
                          label: Text(
                            context.loc.shareBasic,
                            style: TextStyle(fontSize: fontSize - 2),
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
                    color: widget.isPaidUser
                        ? AppColors.primaryBlue
                        : dividerColor,
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
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen),
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
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen),
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
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen),
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
                          Icon(Icons.check_circle,
                              color: AppColors.primaryGreen),
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

                      // Premium festival preview with info box
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.email
                                ?.replaceAll('.', '_'))
                            .get(),
                        builder: (context, snapshot) {
                          String userName = '';
                          String userProfileUrl = '';

                          // Extract user data if available
                          if (snapshot.hasData &&
                              snapshot.data != null &&
                              snapshot.data!.exists) {
                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            userName = userData['name'] ?? '';
                            userProfileUrl = userData['profileImage'] ?? '';
                          }

                          return RepaintBoundary(
                            key: widget._brandedImageKey,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: dividerColor),
                              ),
                              child: Column(
                                children: [
                                  // Festival image with proper aspect ratio
                                  _isImageLoading
                                      ? _buildImageContainer(
                                          aspectRatio: _aspectRatio,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(8)),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryBlue,
                                              backgroundColor: isDarkMode
                                                  ? AppColors.darkSurface
                                                  : AppColors.lightSurface,
                                            ),
                                          ),
                                        )
                                      : AspectRatio(
                                          aspectRatio: _aspectRatio,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(8)),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    widget.festival.imageUrl),
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
                                      color: isDarkMode
                                          ? AppColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(8)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Profile image
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: userProfileUrl
                                                  .isNotEmpty
                                              ? NetworkImage(userProfileUrl)
                                              : AssetImage(
                                                      'assets/profile_placeholder.png')
                                                  as ImageProvider,
                                        ),
                                        SizedBox(width: 12),

                                        // User details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName.isEmpty
                                                    ? widget.userName
                                                    : userName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: fontSize - 1,
                                                  color: textColor,
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
                        },
                      ),
                      SizedBox(height: 16),
                      // Premium share button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.isPaidUser
                              ? () => _shareFestival(
                                    context,
                                    isPaid: true,
                                  )
                              : () =>
                                  Navigator.pushNamed(context, '/subscription'),
                          icon: widget.isPaidUser
                                        ? SvgPicture.asset(
                                            'assets/icons/share.svg',
                                            colorFilter:
                                ColorFilter.mode(Colors.white, BlendMode.srcIn),)
                                        : SvgPicture.asset(
                                            'assets/icons/premium_1659060.svg',width: 25,
                            height: 25,
                            color: Colors.white,),
                          label: Text(
                            widget.isPaidUser
                                ? context.loc.shareNow
                                : context.loc.upgradeToPro,
                            style: TextStyle(fontSize: fontSize - 2),
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
            ],
          ),
        ),
      ),
    );
  }

  // Method to capture widget as image with branding
  Future<Uint8List?> _captureBrandedImage() async {
    try {
      final RenderRepaintBoundary boundary =
          widget._brandedImageKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Use a higher pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
      final ui.Image originalImage =
          await decodeImageFromList(originalImageBytes);

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
          final http.Response response =
              await http.get(Uri.parse(widget.userProfileImageUrl));
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
      final double brandingX =
          width - brandingWidth - width * 0.025; // 2.5% padding
      final double brandingY =
          height - brandingHeight - height * 0.025; // 2.5% padding

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
          ..addOval(
              Rect.fromLTWH(profileX, profileY, profileSize, profileSize));
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
            width: brandingWidth -
                (profileImage != null ? brandingHeight * 0.8 + 12 : 8)));

      canvas.drawParagraph(
          paragraph, Offset(textX, textY - paragraph.height / 2));

      // Convert canvas to image - use the original dimensions
      final ui.Picture picture = recorder.endRecording();
      final ui.Image renderedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert image to bytes
      final ByteData? byteData =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
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
      final ui.Image originalImage =
          await decodeImageFromList(originalImageBytes);

      // Create a recorder and canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Load the logo watermark
      final ByteData logoData = await rootBundle.load('assets/Vaky_bnw.png');
      final ui.Image logo =
          await decodeImageFromList(logoData.buffer.asUint8List());

      // Calculate size and position for the watermark in center (same as template sharing)
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();
      final double watermarkSize = width * 0.2; // 20% of the image width

      // Draw watermark in center
      final Paint watermarkPaint = Paint()
        ..color = Colors.white.withOpacity(0.3);

      // Draw the watermark in center
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH((width - watermarkSize) / 2, (height - watermarkSize) / 2,
            watermarkSize, watermarkSize),
        watermarkPaint,
      );

      // Convert canvas to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image renderedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert image to bytes
      final ByteData? byteData =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error adding watermark to image: $e');
      return null;
    }
  }

  // Sharing implementation with fixes
  Future<void> _shareFestival(BuildContext context,
      {required bool isPaid}) async {
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
      final response = await http.get(Uri.parse(widget.festival.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      final originalImageBytes = response.bodyBytes;
      Uint8List? imageBytes;

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
            print(
                'Both branding approaches failed, falling back to direct download');
            imageBytes = originalImageBytes;
          }
        } catch (e) {
          print(
              'Error in premium capture: $e, falling back to direct download');
          imageBytes = originalImageBytes;
        }
      } else {
        // For free users, add the watermark to the image
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
      final tempFile = File('${tempDir.path}/shared_festival.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes);

      // Share directly based on user type
      if (isPaid) {
        // For paid users, share with full branding
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Check out this amazing festival post by ${widget.userName}!',
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

  // Info box component for the festival sharing page
  Widget _buildInfoBox({
    required String title,
    required VoidCallback onCreatePressed,
    required VoidCallback onSharePressed,
    required VoidCallback onCancelPressed,
    required Widget contentWidget,
  }) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content widget (festival image with branding)
            contentWidget,
            SizedBox(height: 24),

            // Title if provided
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),

            Text(
              context.loc.doYouWishToContinue,
              style: TextStyle(
                fontSize: fontSize - 1,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            SizedBox(height: 16),

            // Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: onCreatePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          context.loc.create,
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                      ),
                    ),
                    SizedBox(width: 40),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: onCancelPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? AppColors.darkSurface : Colors.white,
                          foregroundColor: textColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          context.loc.cancel,
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
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
                      onPressed: onSharePressed,
                      icon: SvgPicture.asset(
                        'assets/icons/share.svg',
                        colorFilter:
                            ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        width: 24, // Adjust size as needed
                        height: 24, // Adjust size as needed
                      ),
                      label: Text(
                        context.loc.share,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
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
    );
  }

  // Add this method to show the info box dialog
  void showFestivalInfoBox(BuildContext context) {
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
                title: widget.festival.name,
                onCreatePressed: () {
                  Navigator.of(context).pop();
                  // Navigate to details screen instead of directly to edit screen
                  QuoteTemplate template = QuoteTemplate(
                    id: widget.festival.id,
                    title: widget.festival.name,
                    imageUrl: widget.festival.imageUrl,
                    isPaid: widget.festival.isPaid,
                    category: widget.festival.category,
                    createdAt: widget.festival.createdAt,
                  );

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
                  _shareFestival(context, isPaid: widget.isPaidUser);
                },
                onCancelPressed: () => Navigator.of(context).pop(),
                contentWidget: RepaintBoundary(
                  key: widget._brandedImageKey,
                  child: AspectRatio(
                    aspectRatio: _aspectRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(widget.festival.imageUrl),
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: widget.isPaidUser
                          ? Align(
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
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

// Rating dialog implementation
  Future<void> _showRatingDialog(BuildContext context) async {
    double rating = 0;
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;

    // Get font size from TextSizeProvider
    final textSizeProvider =
        Provider.of<TextSizeProvider>(context, listen: false);
    final fontSize = textSizeProvider.fontSize;

    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              context.loc.rateThisContent,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
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
                  Navigator.of(dialogContext).pop(rating);
                  Navigator.of(context).pushReplacementNamed('/nav_bar');
                },
                child: Text(
                  context.loc.submit,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          );
        });
      },
    ).then((value) {
      if (value != null && value > 0) {
        // Submit rating
        _submitRating(value, widget.festival);

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

// Submit rating function
  static Future<void> _submitRating(double rating, FestivalPost festival) async {
    try {
      // 1. Get the festival ID and template ID
      String festivalId = "festival_id_1";
      String templateId = festival.templateId;

      // 2. Log what we're doing
      print('NEW RATING: Submitting rating $rating for festival $festivalId and template $templateId');

      // 3. Get reference to the festival document
      final festivalRef = FirebaseFirestore.instance.collection('festivals').doc(festivalId);

      // 4. Get the document data first to find the template
      DocumentSnapshot docSnapshot = await festivalRef.get();

      if (!docSnapshot.exists) {
        print('NEW RATING: Document not found: $festivalId');
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      List<dynamic> templatesArray = List.from(data['templates'] ?? []);

      // 5. Find the template index
      int templateIndex = -1;
      for (int i = 0; i < templatesArray.length; i++) {
        if (templatesArray[i]['id'] == templateId) {
          templateIndex = i;
          break;
        }
      }

      if (templateIndex == -1) {
        print('NEW RATING: Template not found with ID: $templateId');
        for (var template in templatesArray) {
          print('NEW RATING: Available template ID: ${template['id']}');
        }
        return;
      }

      // 6. Update the template data
      Map<String, dynamic> templateData = Map<String, dynamic>.from(templatesArray[templateIndex]);

      // Calculate the new rating
      double currentAvgRating = (templateData['avgRating'] as num?)?.toDouble() ?? 0.0;
      int ratingCount = (templateData['ratingCount'] as int?) ?? 0;

      int newRatingCount = ratingCount + 1;
      double newAvgRating = ((currentAvgRating * ratingCount) + rating) / newRatingCount;

      print('NEW RATING: Old rating: $currentAvgRating, count: $ratingCount');
      print('NEW RATING: New rating: $newAvgRating, count: $newRatingCount');

      // Update the template data
      templateData['avgRating'] = newAvgRating;
      templateData['ratingCount'] = newRatingCount;

      // Update the array
      templatesArray[templateIndex] = templateData;

      // 7. Update the document - simplified approach without transaction
      await festivalRef.update({
        'templates': templatesArray,
      });

      print('NEW RATING: Successfully updated rating!');
    } catch (e) {
      print('NEW RATING ERROR: $e');
      print('NEW RATING STACK: ${StackTrace.current}');
    }
  }

  static Future<void> _updateFestivalAverageRating(
      String festivalId, double newRating) async {
    try {
      // Get reference to the festival document
      final festivalRef = FirebaseFirestore.instance
          .collection('festivals')
          .doc(festivalId.split('_')[0]);

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
    }
  }
}
