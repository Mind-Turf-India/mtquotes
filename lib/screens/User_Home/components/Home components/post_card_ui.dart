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
import '../../../Templates/unified_model.dart';
import '../../files_screen.dart';
import '../custom_share.dart';

class PostCard extends StatefulWidget {
  final UnifiedPost post;
  final VoidCallback? onEditPressed;
  final Function(UnifiedPost)? onRatingChanged;
  final bool showFullActions;
  final String userName; // Add this
  final String userProfileUrl; // Add this

  const PostCard({
    Key? key,
    required this.post,
    this.onEditPressed,
    this.onRatingChanged,
    this.showFullActions = true,
    required this.userName, // Add this
    required this.userProfileUrl, // Add this
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  double _aspectRatio = 1.0; // Default aspect ratio
  bool _imageLoaded = false;
  final GlobalKey _cardKey = GlobalKey();
  late AnimationController _animationController;
  bool _showActionMenu = false;
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

  // Cache for user profile data to avoid multiple Firestore calls

// Get user profile image
  Future<String> _getUserProfileImage(String userEmail) async {
    if (userEmail.isEmpty) return '';

    // Check cache first
    if (_userProfileCache.containsKey(userEmail) &&
        _userProfileCache[userEmail]!.containsKey('profileImage')) {
      return _userProfileCache[userEmail]!['profileImage'] ?? '';
    }

    try {
      // Convert email format for Firestore (replace . with _)
      String docId = userEmail.replaceAll('.', '_');

      // Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(docId).get();

      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final profileImage = userData['profileImage'] ?? '';

        // Cache the result
        if (!_userProfileCache.containsKey(userEmail)) {
          _userProfileCache[userEmail] = {};
        }
        _userProfileCache[userEmail]!['profileImage'] = profileImage;

        return profileImage;
      }

      return '';
    } catch (e) {
      print('Error fetching user profile image: $e');
      return '';
    }
  }

// Get user name
  Future<String> _getUserName(String userEmail) async {
    if (userEmail.isEmpty) return 'User';

    // Check cache first
    if (_userProfileCache.containsKey(userEmail) &&
        _userProfileCache[userEmail]!.containsKey('name')) {
      return _userProfileCache[userEmail]!['name'] ?? 'User';
    }

    try {
      // Convert email format for Firestore (replace . with _)
      String docId = userEmail.replaceAll('.', '_');

      // Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(docId).get();

      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final name = userData['name'] ?? 'User';

        // Cache the result
        if (!_userProfileCache.containsKey(userEmail)) {
          _userProfileCache[userEmail] = {};
        }
        _userProfileCache[userEmail]!['name'] = name;

        return name;
      }

      return 'User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'User';
    }
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
                  true; // Still mark as loaded to avoid infinite loading
            });
          }
        },
      );

      image.resolve(ImageConfiguration()).addListener(listener);
    } catch (e) {
      print('Error determining image aspect ratio: $e');
      if (mounted) {
        setState(() {
          _imageLoaded = true; // Mark as loaded even on error
        });
      }
    }
  }

  // Toggle favorite status
  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Toggle action menu
  void _toggleActionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomShareBottomSheet(
        imageUrl: widget.post.imageUrl,
        title: widget.post.title,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
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
  Future<void> _trackSavedImage(
      User user, String fileName, String title) async {
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
            ? '/storage/emulated/0/Pictures/Vaky/${_sanitizeEmail(user.email!)}/$fileName'
            : '${(await getApplicationDocumentsDirectory()).path}/Vaky/${_sanitizeEmail(user.email!)}/$fileName',
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

  // For WhatsApp sharing
  Future<void> _shareToWhatsApp(BuildContext context, UnifiedPost post) async {
    _showLoadingIndicator(context);

    try {
      // Download the image
      final response = await http.get(Uri.parse(post.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/whatsapp_share.jpg');
      await file.writeAsBytes(response.bodyBytes);

      _hideLoadingIndicator(context);

      // For Android - Direct sharing to WhatsApp
      if (Platform.isAndroid) {
        try {
          // Instead of using whatsapp:// URI, use the Share method with a package selector
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
            subject: 'Check out this quote!',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
          );
        } catch (e) {
          print("Error sharing to WhatsApp: $e");
          // If that fails, try a more generic share approach
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
          );
        }
      }
      // For iOS
      else if (Platform.isIOS) {
        try {
          // Use the standard iOS sharing mechanism
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
            subject: 'Check out this quote!',
          );
        } catch (e) {
          print("Error sharing on iOS: $e");
          // Fallback
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
          );
        }
      }
      // For other platforms
      else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: post.title,
        );
      }
    } catch (e) {
      _hideLoadingIndicator(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing to WhatsApp: $e')),
      );
    }
  }

// For Facebook sharing
  Future<void> _shareToFacebook(BuildContext context, UnifiedPost post) async {
    _showLoadingIndicator(context);

    try {
      // Download the image
      final response = await http.get(Uri.parse(post.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/facebook_share.jpg');
      await file.writeAsBytes(response.bodyBytes);

      _hideLoadingIndicator(context);

      // For Android
      if (Platform.isAndroid) {
        try {
          // Launch Facebook app directly
          final fbUri = Uri.parse("fb://feed");
          bool launched = await launchUrl(
            fbUri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            // Allow Facebook to open
            await Future.delayed(Duration(milliseconds: 500));

            // Now share to it
            await Share.shareXFiles(
              [XFile(file.path)],
              text: post.title,
            );
          } else {
            // Facebook not installed, try web fallback or standard share
            final facebookWebUrl =
                'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://vakyapp.com')}&quote=${Uri.encodeComponent(post.title)}';

            bool webLaunched = await launchUrl(
              Uri.parse(facebookWebUrl),
              mode: LaunchMode.externalApplication,
            );

            if (!webLaunched) {
              // If web share fails too, fall back to standard sharing
              await Share.shareXFiles(
                [XFile(file.path)],
                text: post.title,
              );
            }
          }
        } catch (e) {
          print("Error with Facebook sharing: $e");
          // Fallback to standard sharing
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
          );
        }
      }
      // For iOS
      else if (Platform.isIOS) {
        try {
          // Launch Facebook app directly
          final fbUri = Uri.parse("fb://feed");
          bool launched = await launchUrl(
            fbUri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            // Allow Facebook to open
            await Future.delayed(Duration(milliseconds: 500));

            // Now share to it
            await Share.shareXFiles(
              [XFile(file.path)],
              text: post.title,
            );
          } else {
            // Facebook not installed, try web fallback or standard share
            final facebookWebUrl =
                'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://vakyapp.com')}&quote=${Uri.encodeComponent(post.title)}';

            bool webLaunched = await launchUrl(
              Uri.parse(facebookWebUrl),
              mode: LaunchMode.externalApplication,
            );

            if (!webLaunched) {
              // If web share fails too, fall back to standard sharing
              await Share.shareXFiles(
                [XFile(file.path)],
                text: post.title,
              );
            }
          }
        } catch (e) {
          // Fallback to standard sharing
          await Share.shareXFiles(
            [XFile(file.path)],
            text: post.title,
          );
        }
      }
      // For other platforms
      else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: post.title,
        );
      }
    } catch (e) {
      _hideLoadingIndicator(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing to Facebook: $e')),
      );
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Premium',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
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
                // Reduced vertical margin
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
                      onDoubleTap: _toggleFavorite,
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
                                  placeholder: (context, url) => Container(
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
                                      widget.post.userName,
                                      widget.post.userProfileUrl),
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

                    // Action buttons
                    widget.showFullActions
                        ? _buildFullActionsRow(context, iconColor, textColor)
                        : _buildCompactActionsRow(
                            context, iconColor, textColor),
                  ],
                ),
              ),

              // Overlay action menu (when expanded)
              if (_showActionMenu)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleActionMenu, // Close menu on tap outside
                    child: Container(
                      color: Colors.black54,
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Center(
                          child: Card(
                            color: cardColor,
                            elevation: 8,
                            margin: EdgeInsets.all(32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.loc.share,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildShareOption(
                                        context: context,
                                        icon: Icons.share,
                                        label: context.loc.share,
                                        onTap: () {
                                          _toggleActionMenu();
                                          _sharePost(context);
                                        },
                                        color: Colors.blue,
                                      ),
                                      _buildShareOption(
                                        context: context,
                                        svgAsset: 'assets/icons/whatsapp.svg',
                                        label: 'WhatsApp',
                                        onTap: () {
                                          _toggleActionMenu();
                                          _shareToWhatsApp(
                                              context, widget.post);
                                        },
                                        color:
                                            Color(0xFF25D366), // WhatsApp green
                                      ),
                                      _buildShareOption(
                                        context: context,
                                        svgAsset:
                                            'assets/icons/facebook_2111393.svg',
                                        label: 'Facebook',
                                        onTap: () {
                                          _toggleActionMenu();
                                          _shareToFacebook(
                                              context, widget.post);
                                        },
                                        color:
                                            Color(0xFF1877F2), // Facebook blue
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildShareOption(
                                        context: context,
                                        icon: Icons.download,
                                        label: context.loc.save,
                                        onTap: () {
                                          _toggleActionMenu();
                                          _downloadImage(context, widget.post);
                                        },
                                        color: Colors.green,
                                      ),
                                      _buildShareOption(
                                        context: context,
                                        svgAsset: 'assets/icons/instagram.svg',
                                        label: 'Instagram',
                                        onTap: () {
                                          _toggleActionMenu();
                                          _sharePost(
                                              context); // Use regular share for Instagram
                                        },
                                        color: Color(
                                            0xFFE1306C), // Instagram gradient approximation
                                      ),
                                      _buildShareOption(
                                        context: context,
                                        icon: Icons.copy,
                                        label: 'context.loc.copy',
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text: widget.post.title));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Text copied to clipboard')),
                                          );
                                          _toggleActionMenu();
                                        },
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24),
                                  TextButton(
                                    onPressed: _toggleActionMenu,
                                    child: Text(
                                      context.loc.cancel,
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

  // Regular sharing function (used for universal share and fallbacks)
  Future<void> _sharePost(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Download the image
      final response = await http.get(Uri.parse(widget.post.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/shared_post.jpg');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _isLoading = false;
      });

      // Universal share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.post.title,
        subject: 'Check out this quote!',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  // Build full action buttons row (for larger screens)
  Widget _buildFullActionsRow(
      BuildContext context, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            svgPath: 'assets/icons/pen_1659682.svg',
            label: context.loc.editimage,
            onPressed: widget.onEditPressed,
            //iconColor: iconColor,
            textColor: textColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/share.svg',
            label: context.loc.share,
            onPressed: _toggleActionMenu,
            //iconColor: iconColor,
            textColor: textColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/facebook_2111393.svg',
            label: 'Facebook',
            onPressed: () => _shareToFacebook(context, widget.post),
            //iconColor: iconColor,
            textColor: textColor,
          ),
          _buildActionButton(
            svgPath: 'assets/icons/whatsapp.svg',
            label: 'WhatsApp',
            onPressed: () => _shareToWhatsApp(context, widget.post),
            //iconColor: iconColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  // Build compact action buttons row (for smaller screens)
  Widget _buildCompactActionsRow(
      BuildContext context, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share,
            label: context.loc.share,
            onPressed: _toggleActionMenu,
            //iconColor: iconColor,
            textColor: textColor,
          ),
          _buildActionButton(
            icon: Icons.edit,
            label: context.loc.editimage,
            onPressed: widget.onEditPressed,
            //iconColor: iconColor,
            textColor: textColor,
          ),
          _buildActionButton(
            icon: Icons.download,
            label: context.loc.save,
            onPressed: () => _downloadImage(context, widget.post),
            //iconColor: iconColor,
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
    // required Color iconColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // if (icon != null)
            //   Icon(icon, color: iconColor, size: 20)
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 20,
                height: 20,
                // For Flutter 3.0+
                // colorFilter: ColorFilter.mode(
                //    // iconColor,
                //     BlendMode.srcIn
                // ),
                // For older Flutter versions, remove the colorFilter and uncomment this:
                // color: iconColor,
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

  // Helper method to build share options in the expanded menu
  Widget _buildShareOption({
    required BuildContext context,
    IconData? icon,
    String? svgAsset,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                // Light background that contrasts with both dark and light themes
                color: color.withOpacity(0.1),
                // Very light tint of the icon color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        color: color,
                        // This makes the icon appear in its proper color
                        size: 30,
                      )
                    : svgAsset != null
                        ? SvgPicture.asset(
                            svgAsset,
                            width: 30,
                            height: 30,
                            // For Flutter 3.0 and above:
                            colorFilter: ColorFilter.mode(
                              color,
                              BlendMode.srcIn,
                            ),
                            // For older Flutter versions:
                            // color: color,
                          )
                        : SizedBox(),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileContainer(String userName, String profileImageUrl) {
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
              child: profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 24,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
