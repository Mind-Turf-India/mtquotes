import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../../../providers/text_size_provider.dart';
import '../recent/recent_service.dart';

class TemplateSharingPage extends StatefulWidget {
  final QuoteTemplate template;
  final String userName;
  final String userProfileImageUrl;
  final bool isPaidUser;
  final Uint8List? customImageData; // Add this to handle custom image data

  const TemplateSharingPage({
    super.key,
    required this.template,
    required this.userName,
    required this.userProfileImageUrl,
    required this.isPaidUser,
    this.customImageData, // Optional parameter for custom image data
  });

  @override
  _TemplateSharingPageState createState() => _TemplateSharingPageState();
}

class _TemplateSharingPageState extends State<TemplateSharingPage> {
  final GlobalKey _brandedImageKey = GlobalKey();
  ui.Image? _originalImage;
  double _aspectRatio = 16 / 9; // Default aspect ratio until image loads
  bool _imageLoaded = false;
  String _currentImageUrl = '';
  bool _isLoading = true;
  Uint8List? _customImageData;
  bool _isImageLoading = true;

  @override
  void initState() {
    super.initState();
    print(
        'TemplateSharingPage initState with template: ${widget.template.id}, imageUrl: ${widget.template.imageUrl}');
    _currentImageUrl = widget.template.imageUrl;
    _customImageData = widget.customImageData; // Store the custom image data
    _loadOriginalImage();
    _addToRecentTemplates();
  }

  @override
  void didUpdateWidget(TemplateSharingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the template, image URL, or custom image data has changed
    if (oldWidget.template.id != widget.template.id ||
        oldWidget.template.imageUrl != widget.template.imageUrl ||
        oldWidget.customImageData != widget.customImageData) {
      print(
          'Template changed: Old: ${oldWidget.template.id}, ${oldWidget.template.imageUrl}');
      print(
          'Template changed: New: ${widget.template.id}, ${widget.template.imageUrl}');

      setState(() {
        _currentImageUrl = widget.template.imageUrl;
        _customImageData = widget.customImageData;
        _imageLoaded = false;
        _isLoading = true;
      });
      _loadOriginalImage();
      _addToRecentTemplates();
    }
  }

  Future<void> _addToRecentTemplates() async {
    try {
      await RecentTemplateService.addRecentTemplate(widget.template);
      print(
          'Added template to recents from sharing page: ${widget.template.id}');
    } catch (e) {
      print('Error adding template to recents from sharing page: $e');
    }
  }

  // Load the image based on whether we have custom image data or need to fetch from URL
  Future<void> _loadOriginalImage() async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final http.Response response =
          await http.get(Uri.parse(widget.template.imageUrl));
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

  // Helper function to create properly sized image
  Widget _buildTrendingImage({
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
          image: NetworkImage(widget.template.imageUrl),
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

  // Helper method to get image provider
  ImageProvider _getImageProvider() {
    if (_customImageData != null) {
      // Use the custom image data if available
      return MemoryImage(_customImageData!);
    } else if (widget.template.imageUrl.startsWith('file:/')) {
      // For local files, remove the file:/ prefix and use FileImage
      String filePath = widget.template.imageUrl.replaceFirst('file:/', '');
      return FileImage(File(filePath));
    } else {
      // For network images, use NetworkImage
      return NetworkImage(widget.template.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme and determine if we're in dark mode
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);

    // Theme colors
    final Color backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final Color cardColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final Color textColor =
        isDarkMode ? AppColors.darkText : AppColors.lightText;
    final Color secondaryTextColor =
        isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final Color dividerColor =
        isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
    final Color iconColor =
        isDarkMode ? AppColors.darkIcon : AppColors.lightIcon;
    final Color cardBackgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

    // Force rebuild when template changes by using these in widget tree
    final String currentTemplateId = widget.template.id;
    final String currentImageUrl = widget.template.imageUrl;
    final bool hasCustomImage = _customImageData != null;
    double fontSize = textSizeProvider.fontSize;

    print(
        'Building sharing UI with template: $currentTemplateId, imageUrl: $currentImageUrl, hasCustomImage: $hasCustomImage');

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

                      // Preview of template without branding but with watermark - FIXED
                      _buildTrendingImage(showWatermark: true),

                      SizedBox(height: 16),
                      // Free share button only
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _shareTemplate(
                            context,
                            isPaid: false,
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/share.svg',
                            colorFilter:
                                ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            width: 24, // Adjust size as needed
                            height: 24, // Adjust size as needed
                          ),
                          label: Text(context.loc.shareBasic),
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

                      // If we have custom image data, show just the image for paid users
                      if (_customImageData != null && widget.isPaidUser)
                        Column(
                          children: [
                            // Just the image - this part will be captured
                            RepaintBoundary(
                              key: _brandedImageKey,
                              child: _buildImageContainer(
                                aspectRatio: _aspectRatio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: _getImageProvider(),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Share button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _shareTemplate(context, isPaid: true),
                                icon: Icon(Icons.share, color: Colors.white),
                                label: Text(context.loc.shareNow),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      // Otherwise show the template with user info box for both paid and unpaid users
                      else
                        FutureBuilder<DocumentSnapshot>(
                          key: ValueKey(
                              "premium_preview_${currentTemplateId}_${currentImageUrl}"),
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.email
                                  ?.replaceAll('.', '_'))
                              .get(),
                          builder: (context, snapshot) {
                            String userName = '';
                            String userProfileUrl = '';
                            String userLocation = '';
                            String userDescription = '';
                            String userSocialMedia = '';
                            String companyName = '';
                            bool isBusinessProfile = false;

                            // Extract user data if available
                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.exists) {
                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              userName = userData['name'] ?? '';

                              // Only override profile URL if the passed one is empty
                              if (widget.userProfileImageUrl.isEmpty) {
                                userProfileUrl = userData['profileImage'] ?? '';
                              }

                              // Get additional user info - these will only be used for paid users
                              if (widget.isPaidUser) {
                                userLocation = userData['location'] ?? '';
                                userDescription = userData['description'] ?? '';
                                userSocialMedia = userData['socialMedia'] ?? '';
                                companyName = userData['companyName'] ?? '';
                                isBusinessProfile =
                                    userData['lastActiveProfileTab'] ==
                                        'business';
                              }
                            }

                            return Column(
                              children: [
                                // Image and info box together in one RepaintBoundary for capture
                                RepaintBoundary(
                                  key: _brandedImageKey,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: dividerColor),
                                    ),
                                    child: Column(
                                      children: [
                                        // Template image with proper aspect ratio
                                        _isImageLoading
                                            ? _buildImageContainer(
                                                aspectRatio: _aspectRatio,
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(8)),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color:
                                                        AppColors.primaryBlue,
                                                    backgroundColor: isDarkMode
                                                        ? AppColors.darkSurface
                                                        : AppColors
                                                            .lightSurface,
                                                  ),
                                                ),
                                              )
                                            : AspectRatio(
                                                aspectRatio: _aspectRatio,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                    8)),
                                                    image: DecorationImage(
                                                      image: NetworkImage(widget
                                                          .template.imageUrl),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                        // Info box with basic or detailed user info based on paid status
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cardColor,
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
                                                    ? NetworkImage(
                                                        userProfileUrl)
                                                    : AssetImage(
                                                            'assets/profile_placeholder.png')
                                                        as ImageProvider,
                                              ),
                                              SizedBox(width: 12),

                                              // User details - simplified for unpaid users
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: widget.isPaidUser
                                                      ? [
                                                          // Show Company Name first if business profile (paid users only)
                                                          if (isBusinessProfile &&
                                                              companyName
                                                                  .isNotEmpty)
                                                            Text(
                                                              companyName,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    fontSize,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),

                                                          // Show user name
                                                          Text(
                                                            userName.isNotEmpty
                                                                ? userName
                                                                : widget
                                                                    .userName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  isBusinessProfile
                                                                      ? FontWeight
                                                                          .normal
                                                                      : FontWeight
                                                                          .bold,
                                                              fontSize:
                                                                  isBusinessProfile
                                                                      ? 14
                                                                      : 16,
                                                              color: textColor,
                                                            ),
                                                          ),

                                                          // Show location if available (paid users only)
                                                          if (userLocation
                                                              .isNotEmpty)
                                                            Text(
                                                              userLocation,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    fontSize,
                                                                color:
                                                                    secondaryTextColor,
                                                              ),
                                                            ),

                                                          // Show social media for business profiles (paid users only)
                                                          if (isBusinessProfile &&
                                                              userSocialMedia
                                                                  .isNotEmpty)
                                                            Text(
                                                              userSocialMedia,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    fontSize,
                                                                color: AppColors
                                                                    .primaryBlue,
                                                              ),
                                                            ),

                                                          // Show description for business profiles (paid users only)
                                                          if (isBusinessProfile &&
                                                              userDescription
                                                                  .isNotEmpty)
                                                            Text(
                                                              userDescription,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    fontSize,
                                                                color:
                                                                    secondaryTextColor,
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                        ]
                                                      : [
                                                          // Basic info for unpaid users - just the name
                                                          Text(
                                                            userName.isNotEmpty
                                                                ? userName
                                                                : widget
                                                                    .userName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize:
                                                                  fontSize,
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
                                ),

                                SizedBox(height: 16),
                                // Share button - different based on paid status
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: widget.isPaidUser
                                        ? () => _shareTemplate(context,
                                            isPaid: true)
                                        : () => Navigator.pushNamed(
                                            context, '/subscription'),
                                    icon: widget.isPaidUser
                                        ? SvgPicture.asset(
                                            'assets/icons/share.svg',
                                            colorFilter:
                                ColorFilter.mode(Colors.white, BlendMode.srcIn),)
                                        : SvgPicture.asset(
                                            'assets/icons/premium_1659060.svg'),
                                    label: Text(widget.isPaidUser
                                        ? 'Share Now'
                                        : 'Upgrade to Pro'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        )
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
      // Make sure UI is fully rendered before capture
      await Future.delayed(Duration(milliseconds: 100));

      // Create a separate key for the image-only part that we want to capture
      final RenderRepaintBoundary boundary = _brandedImageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

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

      // Create a recorder and canvas with the ORIGINAL image dimensions
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw the original image with its full dimensions
      canvas.drawImage(originalImage, Offset.zero, Paint());

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

      // Create branding container background
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();
      final double brandingWidth = width * 0.4;
      final double brandingHeight = height * 0.06;
      final double brandingX = width - brandingWidth - 10;
      final double brandingY = height - brandingHeight - 10;

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

        // Draw the profile image in a circle
        canvas.save(); // Save the canvas state before clipping
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
        ..layout(ui.ParagraphConstraints(
            width: brandingWidth -
                (profileImage != null ? brandingHeight * 0.8 + 12 : 8)));

      canvas.drawParagraph(
          paragraph, Offset(textX, textY - paragraph.height / 2));

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
      final ByteData logoData = await rootBundle.load('assets/logo.png');
      final ui.Image logo =
          await decodeImageFromList(logoData.buffer.asUint8List());

      // Calculate size and position for the watermark in top right corner
      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();
      final double watermarkSize =
          width * 0.2; // 20% of the image width (smaller than before)
      final double watermarkX =
          width - watermarkSize - 16; // Position from right edge with padding
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
      final ByteData? byteData =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error adding watermark to image: $e');
      return null;
    }
  }

  // Integrated sharing functionality with proper branding for paid users and watermark for free users
  Future<void> _shareTemplate(BuildContext context,
      {required bool isPaid}) async {
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
      Uint8List originalImageBytes;

      // Get the image bytes based on what's available
      if (_customImageData != null) {
        originalImageBytes = _customImageData!;
      } else if (widget.template.imageUrl.startsWith('file:/')) {
        // Load from local file
        final String filePath =
            widget.template.imageUrl.replaceFirst('file:/', '');
        final File imageFile = File(filePath);
        if (await imageFile.exists()) {
          originalImageBytes = await imageFile.readAsBytes();
        } else {
          throw Exception('Local image file does not exist');
        }
      } else {
        // Download from network
        final response = await http.get(Uri.parse(widget.template.imageUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to load image');
        }
        originalImageBytes = response.bodyBytes;
      }

      if (isPaid) {
        // For paid users, capture with branding
        try {
          // Make sure UI is fully rendered before capture
          await Future.delayed(Duration(milliseconds: 100));

          // First try to capture the branded template widget directly
          imageBytes = await _captureBrandedImage();

          // Fallback to original image with programmatic branding if direct capture fails
          if (imageBytes == null) {
            print('Direct capture returned null, trying programmatic branding');
            imageBytes = await _addBrandingToImage(originalImageBytes);
          }

          // Final fallback to original image
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
        // For free users, add watermark
        try {
          imageBytes = await _addWatermarkToImage(originalImageBytes);

          // Fallback to original image if watermarking fails
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

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_template.png');

      // Save image as file
      await tempFile.writeAsBytes(imageBytes!);

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
                child: Text(context.loc.skip),
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
        _submitRating(value, widget.template);

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

  static Future<void> _updateCategoryTemplateRating(
      String templateId, String category, double newRating) async {
    try {
      // Path to the category template document
      final templateRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(category.toLowerCase())
          .collection('templates')
          .doc(templateId);

      // Run this as a transaction to ensure data consistency
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get the current template data
        final templateSnapshot = await transaction.get(templateRef);

        if (templateSnapshot.exists) {
          final data = templateSnapshot.data() as Map<String, dynamic>;

          // Calculate the new average rating
          double currentAvgRating = data['avgRatings']?.toDouble() ?? 0.0;
          int ratingCount = data['ratingCount'] ?? 0;

          int newRatingCount = ratingCount + 1;
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

          // Update the template with the new average rating
          transaction.update(templateRef, {
            'avgRatings': newAvgRating,
            'ratingCount': newRatingCount,
            'lastRated': FieldValue.serverTimestamp(),
          });

          print('Updated category template average rating successfully');
        } else {
          print('Template not found in category collection');
        }
      });
    } catch (e) {
      print('Error updating category template average rating: $e');
    }
  }

  // Submit rating - this calls the TemplateHandler version
  static Future<void> _submitRating(
      double rating, QuoteTemplate template) async {
    try {
      final DateTime now = DateTime.now();
      final User? currentUser = FirebaseAuth.instance.currentUser;

      // Create a rating object
      final Map<String, dynamic> ratingData = {
        'templateId': template.id,
        'rating': rating,
        'category': template.category,
        'createdAt': now,
        'imageUrl': template.imageUrl,
        'isPaid': template.isPaid,
        'title': template.title,
        'userId': currentUser?.uid ?? 'anonymous',
        'userEmail': currentUser?.email ?? 'anonymous',
      };

      // Add to ratings collection
      DocumentReference ratingRef = await FirebaseFirestore.instance
          .collection('ratings')
          .add(ratingData);

      print(
          'Rating submitted: $rating for template ${template.title} (ID: ${template.id})');

      // Determine if this is a category template based on non-empty category field
      if (template.category.isNotEmpty) {
        // Update the category template's rating
        await _updateCategoryTemplateRating(
            template.id, template.category, rating);
      } else {
        // Use the original method for regular templates
        await _updateTemplateAverageRating(template.id, rating);
      }
    } catch (e) {
      print('Error submitting rating: $e');
    }
  }

  static Future<void> _updateTemplateAverageRating(
      String templateId, double newRating) async {
    try {
      // Get reference to the template document
      final templateRef =
          FirebaseFirestore.instance.collection('templates').doc(templateId);

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
          double newAvgRating =
              ((currentAvgRating * ratingCount) + newRating) / newRatingCount;

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
