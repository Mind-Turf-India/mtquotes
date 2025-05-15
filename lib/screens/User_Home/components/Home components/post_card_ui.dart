import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';
import '../../../Templates/components/template/quote_template.dart';
import '../../../Templates/components/template/template_service.dart';
import '../../../Templates/components/template/template_sharing.dart';
import '../../../Templates/unified_model.dart';
import '../../files_screen.dart';
import '../custom_share.dart';

// Update the PostCard class in post_card_ui.dart

class PostCard extends StatefulWidget {
  final UnifiedPost post;
  final VoidCallback? onEditPressed;
  final VoidCallback? onSharePressed;
  final Function(UnifiedPost)? onRatingChanged;
  final bool showFullActions;

  // Keep both parameter names for compatibility
  final String userName;
  final String userProfileUrl;

  // Add optional userProfileImageUrl parameter to match TemplateSharingPage
  final String? userProfileImageUrl;

  const PostCard({
    Key? key,
    required this.post,
    this.onEditPressed,
    this.onSharePressed,
    this.onRatingChanged,
    this.showFullActions = true,
    required this.userName,
    required this.userProfileUrl,
    this.userProfileImageUrl, // Optional parameter that matches TemplateSharingPage
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  double _aspectRatio = 1.0;
  bool _imageLoaded = false;
  final GlobalKey _cardKey = GlobalKey();
  late AnimationController _animationController;
  bool _isFavorite = false;
  static Map<String, Map<String, String>> _userProfileCache = {};

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load image dimensions to calculate aspect ratio
  Future<void> _loadImageDimensions() async {
    try {
      final image = NetworkImage(widget.post.imageUrl);
      final ImageStreamListener listener = ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
          if (mounted) {
            setState(() {
              _aspectRatio = info.image.width / info.image.height;
              _imageLoaded = true;
            });
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          print('Error loading image: $exception');
          if (mounted) {
            setState(() {
              _imageLoaded =
              true;
            });
          }
        },
      );

      image.resolve(ImageConfiguration()).addListener(listener);
    } catch (e) {
      print('Error determining image aspect ratio: $e');
      if (mounted) {
        setState(() {
          _imageLoaded = true;
        });
      }
    }
  }

  // Toggle favorite status


// Function to get Android version
  Future<int> _getAndroidVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  // Function to request Android 13+ permissions
  Future<bool> _requestAndroid13Permission() async {
    // For Android 13, we need to request photos-specific permissions
    bool photos = await Permission.photos.isGranted;
    if (!photos) {
      photos = (await Permission.photos.request()).isGranted;
    }
    return photos;
  }

  // Function to sanitize email for file path
  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

// Updated function to handle downloading images
  Future<void> _downloadImage(BuildContext context, UnifiedPost post) async {
    final _auth = FirebaseAuth.instance;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Show loading indicator
    _showLoadingIndicator(context);

    try {
      // Download the image data
      final response = await http.get(Uri.parse(post.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final imageData = response.bodyBytes;

      // Check if user is logged in
      User? user = _auth.currentUser;
      if (user == null) {
        _hideLoadingIndicator(context);
        return;
      }

      // Request proper permissions based on platform and Android version
      bool hasPermission = false;

      if (Platform.isAndroid) {
        // Request different permissions based on Android SDK version
        if (await _getAndroidVersion() >= 33) {
          // Android 13+
          hasPermission = await _requestAndroid13Permission();
        } else if (await _getAndroidVersion() >= 29) {
          // Android 10-12
          hasPermission = await Permission.storage.isGranted;
          if (!hasPermission) {
            hasPermission = (await Permission.storage.request()).isGranted;
          }
        } else {
          // Android 9 and below
          hasPermission = await Permission.storage.isGranted;
          if (!hasPermission) {
            hasPermission = (await Permission.storage.request()).isGranted;
          }
        }
      } else if (Platform.isIOS) {
        // iOS typically doesn't need explicit permission for saving to gallery
        hasPermission = true;
      }

      if (!hasPermission) {
        _hideLoadingIndicator(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Storage permission is required to save images")));
        return;
      }

      // Generate a unique filename based on timestamp
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      final fileName = "Vaky_${timestamp}.jpg";

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        imageData,
        quality: 100,
        name: fileName,
      );

      // Check if save was successful
      bool isGallerySaveSuccess = false;
      if (result is Map) {
        isGallerySaveSuccess = result['isSuccess'] ?? false;
      } else {
        isGallerySaveSuccess = result != null;
      }

      if (!isGallerySaveSuccess) {
        throw Exception("Failed to save image to gallery");
      }

      // Also save to user-specific directory for Files screen
      String userDirPath = await _getUserSpecificDirectoryPath(user);
      String filePath = '$userDirPath/$fileName';

      File file = File(filePath);
      await file.writeAsBytes(imageData);

      // Keep track of saved images in Firestore
      await _trackSavedImage(user, fileName, post.title);

      _hideLoadingIndicator(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image saved to your gallery and downloads"),
          duration: Duration(seconds: 3),
          backgroundColor: isDarkMode
              ? AppColors.primaryGreen.withOpacity(0.7)
              : AppColors.primaryGreen,
          action: SnackBarAction(
            label: 'VIEW ALL',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to FilesPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilesPage(),
                ),
              );
            },
          ),
        ),
      );

      print("Image saved to gallery and user directory: $fileName");
    } catch (e) {
      _hideLoadingIndicator(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
      print("Error saving image: $e");
    }
  }

// Get user-specific directory path
  Future<String> _getUserSpecificDirectoryPath(User user) async {
    String userDir = _sanitizeEmail(user.email!);

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Pictures/Vaky/$userDir');
    } else {
      baseDir = Directory(
          '${(await getApplicationDocumentsDirectory()).path}/Vaky/$userDir');
    }

    // Create directory if it doesn't exist
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir.path;
  }

// Track saved image in Firestore
  Future<void> _trackSavedImage(User user, String fileName,
      String title) async {
    try {
      String userEmail = user.email!.replaceAll('.', '_');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('saved_images')
          .add({
        'fileName': fileName,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'path': Platform.isAndroid
            ? '/storage/emulated/0/Pictures/Vaky/${_sanitizeEmail(
            user.email!)}/$fileName'
            : '${(await getApplicationDocumentsDirectory())
            .path}/Vaky/${_sanitizeEmail(user.email!)}/$fileName',
      });
    } catch (e) {
      print('Error tracking saved image: $e');
    }
  }

// Show loading indicator
  void _showLoadingIndicator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        );
      },
    );
  }

// Hide loading indicator
  void _hideLoadingIndicator(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

// Update the _sharePost method in the PostCard class for better debugging

  Future<void> _sharePost(BuildContext context) async {
    try {
      // Check if still mounted before setting state
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      } else {
        return; // Exit if not mounted anymore
      }

      // Check subscription status
      final templateService = TemplateService();
      bool isSubscribed = await templateService.isUserSubscribed();

      // Convert post to QuoteTemplate for compatibility with TemplateSharingPage
      QuoteTemplate template = widget.post.toQuoteTemplate();

      // Debug prints for all profile image URLs
      print("=== PROFILE IMAGE DEBUGGING ===");
      print("Widget userProfileUrl: ${widget.userProfileUrl}");
      print("Widget userProfileImageUrl: ${widget.userProfileImageUrl}");
      print("Post userProfileUrl: ${widget.post.userProfileUrl}");

      // Get the most appropriate URL
      String effectiveUrl = widget.userProfileUrl.isNotEmpty
          ? widget.userProfileUrl
          : (widget.userProfileImageUrl != null && widget.userProfileImageUrl!.isNotEmpty
          ? widget.userProfileImageUrl!
          : (widget.post.userProfileUrl.isNotEmpty
          ? widget.post.userProfileUrl
          : ''));

      print("Effective URL to be used: $effectiveUrl");

      // Update the state if mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      } else {
        return; // Exit if not mounted anymore
      }

      // Navigate to TemplateSharingPage instead of sharing directly
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateSharingPage(
            template: template,
            userName: widget.userName,
            userProfileImageUrl: effectiveUrl, // Use the effective URL
            isPaidUser: isSubscribed,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to sharing page: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Container(
        key: _cardKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 20,),

          Divider(height: 2, thickness: 2,),
          SizedBox(height: 15,),

          // Post header with title and badge ABOVE the card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.post.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                    children: [
                      if (widget.post.isPaid)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.loc.premium,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      SizedBox(width: 4),
                      // Make the download icon tappable
                      GestureDetector(
                        onTap: () => _downloadImage(context, widget.post),
                        child: SvgPicture.asset(
                            'assets/icons/download_home.svg',
                            height: 20,
                            width: 20,
                            color: iconColor
                        ),
                      ),
                    ]
                ),
              ],
            ),
          ),
          SizedBox(height: 10,),

          // Main Card (now without the title section)
          Stack(
            children: [
              Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: cardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // After the main image in the post card:
                    GestureDetector(
                      onTap: widget.onEditPressed,
                      child: AspectRatio(
                        aspectRatio: _imageLoaded ? _aspectRatio : 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Main image
                                CachedNetworkImage(
                                  imageUrl: widget.post.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(
                                        color: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[300],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: isDarkMode
                                            ? Colors.grey[800]
                                            : Colors.grey[200],
                                        child: Center(
                                          child:
                                          Icon(Icons.error, color: iconColor),
                                        ),
                                      ),
                                ),

                                // User info container at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildUserProfileContainer(
                                      widget.userName.isNotEmpty ? widget.userName : widget.post.userName,
                                      widget.userProfileUrl.isNotEmpty
                                          ? widget.userProfileUrl
                                          : (widget.userProfileImageUrl != null && widget.userProfileImageUrl!.isNotEmpty
                                          ? widget.userProfileImageUrl!
                                          : ''
                                      )
                                  )
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Rating and action row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    ),

                    // Action buttons - Simplified now
                    widget.showFullActions
                        ? _buildFullActionsRow(context, iconColor, textColor)
                        : _buildFullActionsRow(
                        context, iconColor, textColor),
                  ],
                ),
              ),

              // Loading overlay
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ]));
  }


  // Build full action buttons row (for larger screens)
  Widget _buildFullActionsRow(BuildContext context, Color iconColor,
      Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            svgPath: 'assets/icons/pen_1659682.svg',
            label: context.loc.editimage,
            onPressed: widget.onEditPressed,
            // This uses the callback from parent which should be updated to go to DetailsScreen
            textColor: textColor,
            iconColor: iconColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/share.svg',
            label: context.loc.share,
            onPressed: () => _sharePost(context),
            // Direct native share
            textColor: textColor,
            iconColor: iconColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/facebook_2111393.svg',
            label: context.loc.facebook,
            onPressed: () => _sharePost(context),
            textColor: textColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/whatsapp.svg',
            label: context.loc.whatsapp,
            onPressed: () => _sharePost(context),
            textColor: textColor,
          ),
        ],
      ),
    );
  }


  // Helper method to build action buttons
  Widget _buildActionButton({
    IconData? icon,
    String? svgPath,
    required String label,
    required VoidCallback? onPressed,
    required Color textColor,
    Color? iconColor,

  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 20)
            else
              if (svgPath != null)
                SvgPicture.asset(
                  svgPath,
                  width: 20,
                  height: 20,
                  color: iconColor,
                ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUserProfileContainer(String userName, String profileImageUrl) {
    // Add debug print to see what URL is being used
    print("Building user profile container with URL: $profileImageUrl");
    print("Widget userProfileUrl: ${widget.userProfileUrl}");
    print("Widget userProfileImageUrl: ${widget.userProfileImageUrl}");

    // Use the widget's URL if the passed one is empty
    String effectiveUrl = profileImageUrl.isNotEmpty
        ? profileImageUrl
        : (widget.userProfileUrl.isNotEmpty
        ? widget.userProfileUrl
        : (widget.userProfileImageUrl ?? ''));

    print("Effective URL being used: $effectiveUrl");

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User name on the left
          Text(
            userName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          // Profile image on the right
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: effectiveUrl.isNotEmpty
                  ? Image.network(
                effectiveUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading profile image: $error");
                  return SvgPicture.asset(
                    'assets/icons/user_profile_new.svg',
                    width: 25,
                    height: 25,
                    color: Colors.grey,
                  );
                },
              )
                  : SvgPicture.asset(
                'assets/icons/user_profile_new.svg',
                width: 25,
                height: 25,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}