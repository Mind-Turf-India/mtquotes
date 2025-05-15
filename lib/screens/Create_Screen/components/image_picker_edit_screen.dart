import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../edit_screen_create.dart';

class ImagePickerScreen extends StatefulWidget {
  final String? templateImageUrl;
  final Uint8List? initialImageData;

  // Add InfoBox related parameters
  final String? name;
  final String? mobile;
  final String? location;
  final String? description;
  final String? companyName;
  final String? socialMedia;
  final String? profileImageUrl;
  final bool showInfoBox;
  final String infoBoxBackground;
  final bool isPersonal; // To distinguish between personal and business modes
  final bool isPaidUser; // Add this parameter to determine if the user is paid

  const ImagePickerScreen({
    super.key,
    this.templateImageUrl,
    this.initialImageData,
    // InfoBox parameters with default values
    this.name,
    this.mobile,
    this.location,
    this.description,
    this.companyName,
    this.socialMedia,
    this.profileImageUrl,
    this.showInfoBox = true,
    this.infoBoxBackground = 'white',
    this.isPersonal = true,
    this.isPaidUser = true, // Default to free user
  });

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  Uint8List? _templateImageData; // To store template image data
  File? _profileImageFile; // To store profile image as a File
  final GlobalKey _brandedImageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    print("ImagePickerScreen initState called");
    print("Received templateImageUrl: ${widget.templateImageUrl}");

    // Log InfoBox data to verify it's received
    print("Received InfoBox data - Name: ${widget.name}, Company: ${widget.companyName}");

    // If the URL is received, check if it's valid
    if (widget.templateImageUrl != null && widget.templateImageUrl!.isNotEmpty) {
      print("URL is valid, will load template from: ${widget.templateImageUrl}");
      _loadTemplateFromUrl(widget.templateImageUrl!);
    } else {
      print("No valid URL received in ImagePickerScreen");
    }

    // If there's a profile image URL, load it
    if (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty) {
      _loadProfileImageFromUrl(widget.profileImageUrl!);
    }
  }

  // New method to load profile image
  Future<void> _loadProfileImageFromUrl(String url) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'profile_${url.hashCode}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _profileImageFile = file;
        });
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Convert Uint8List to File
  Future<void> _convertBytesToFile(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/template_image.png');
      await file.writeAsBytes(bytes);

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      print('Error converting bytes to file: $e');
      // Show error if needed
    }
  }

  // Load template image from URL
  Future<void> _loadTemplateFromUrl(String url) async {
    if (url.isEmpty) {
      print("Empty URL provided to _loadTemplateFromUrl");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("Starting HTTP request to URL: $url");
      final http.Response response = await http.get(Uri.parse(url));

      print("HTTP response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        // Alternative unique filename approach
        final fileName = 'template_${url.hashCode}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        print("Template image saved to: ${file.path}");

        setState(() {
          _selectedImage = file;
          _templateImageData = response.bodyBytes;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading template image: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading template image: $e'))
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _templateImageData = null; // Clear template data when user picks new image
      });
    }
  }

  // Method to capture branded image (image with infobox)
  // Fix for the _captureBrandedImage method
  Future<Uint8List?> _captureBrandedImage() async {
    try {
      // Make sure UI is fully rendered before capture
      // Increase the delay to ensure complete rendering
      await Future.delayed(Duration(milliseconds: 300));

      // Get the RenderRepaintBoundary object from the global key
      final RenderRepaintBoundary? boundary =
      _brandedImageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        print('Error: RenderRepaintBoundary is null');
        return null;
      }

      // Check if the render object is ready for capture
      if (!boundary.debugNeedsPaint) {
        // Use a higher pixel ratio for better quality
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          print('Successfully captured branded image with size: ${byteData.lengthInBytes} bytes');
          return byteData.buffer.asUint8List();
        } else {
          print('Error: ByteData is null after capture');
          return null;
        }
      } else {
        print('Error: RenderRepaintBoundary is not ready for capture');
        return null;
      }
    } catch (e) {
      print('Error capturing branded image: $e');
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

      // You would normally load the logo from assets
      // For now, we'll create a simple text watermark
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.right,
          fontSize: 24,
        ),
      )
        ..pushStyle(ui.TextStyle(color: Colors.white.withOpacity(0.7)))
        ..addText('VakyApp');

      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: 200));

      // Draw watermark text at the bottom right corner
      canvas.drawParagraph(
          paragraph,
          Offset(originalImage.width - 200 - 16, originalImage.height - paragraph.height - 16)
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

  Future<void> _shareImage() async {
    if (_selectedImage == null) {
      _showNoImageSelectedDialog();
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      Uint8List? imageBytes;

      print("Is Paid User: ${widget.isPaidUser}, ShowInfoBox: ${widget.showInfoBox}");

      if (widget.isPaidUser && widget.showInfoBox) {
        // For paid users with InfoBox, capture the complete branded image
        // Ensure the UI state is properly initialized
        setState(() {});

        // Wait for next frame to ensure everything is rendered
        await WidgetsBinding.instance.endOfFrame;

        // Capture the widget that contains both image and infobox
        imageBytes = await _captureBrandedImage();

        print('Branded image capture result: ${imageBytes != null ? 'Success' : 'Failed'}');

        // If capture fails, fall back to original image
        if (imageBytes == null) {
          print('Capture failed, falling back to original image');
          imageBytes = await _selectedImage!.readAsBytes();
        }
      } else {
        // For free users or when InfoBox is not shown, add a watermark to the original image
        final originalBytes = await _selectedImage!.readAsBytes();

        if (widget.isPaidUser) {
          // Paid users without InfoBox get original image without watermark
          imageBytes = originalBytes;
        } else {
          // Free users get watermark
          imageBytes = await _addWatermarkToImage(originalBytes);

          // If watermarking fails, fall back to original image
          if (imageBytes == null) {
            print('Watermarking failed, falling back to original image');
            imageBytes = originalBytes;
          }
        }
      }

      // Close loading dialog
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Create temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shared_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(imageBytes!);
      print('Shared image saved to: ${tempFile.path}');

      // Share the image
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: widget.isPaidUser ? 'Check out this amazing image!' : 'Check out this amazing image!',
      );
      print('Image shared successfully');

    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error sharing image: $e');
      _showErrorDialog('Failed to share image: $e');
    }
  }

  // Navigate to edit screen with all the InfoBox data
  void _navigateToEditScreen() {
    if (_selectedImage != null) {
      print("Navigating to edit screen with selected image: ${_selectedImage!.path}");
      // Pass all InfoBox data to EditScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            imageFile: _selectedImage!,
            templateImageUrl: widget.templateImageUrl,
            // Pass InfoBox data
            name: widget.name,
            mobile: widget.mobile,
            location: widget.location,
            description: widget.description,
            companyName: widget.companyName,
            socialMedia: widget.socialMedia,
            profileImageFile: _profileImageFile,
            profileImageUrl: widget.profileImageUrl,
            showInfoBox: widget.showInfoBox,
            infoBoxBackground: widget.infoBoxBackground,
            isPersonal: widget.isPersonal,
            isPaidUser: widget.isPaidUser, // Pass the isPaidUser parameter
          ),
        ),
      ).then((_) {
        // Optional: Refresh state when returning from edit screen
        setState(() {});
      });
    } else {
      _pickImageFromGallery();
    }
  }

  // Download image to gallery
  Future<void> _downloadImage() async {
    if (_selectedImage == null) {
      _showNoImageSelectedDialog();
      return;
    }

    try {
      // Check permissions
      bool hasPermission = await _checkAndRequestPermissions();

      if (!hasPermission) {
        _showErrorDialog('Storage permission is required to save images');
        return;
      }

      // Just navigate to edit screen - from there you can download
      _navigateToEditScreen();

    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  // Permission handling
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // Check Android version
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 33) {
        // Android 13+ requires Photos permission
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // Older Android versions use storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS typically doesn't need explicit permission
      return true;
    }

    return false;
  }

  // Get Android version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        // This would use device_info_plus in a real implementation
        // Simplified for this example
        return 33; // Assume Android 13 by default
      } catch (e) {
        print('Error getting Android version: $e');
      }
    }
    return 0;
  }

  // Dialog helpers
  void _showNoImageSelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Image Selected'),
          content: const Text('Please select an image from gallery first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to get background color
  Color _getBackgroundColor() {
    switch (widget.infoBoxBackground) {
      case 'lightGray':
        return Colors.grey[200]!;
      case 'lightBlue':
        return Colors.blue[100]!;
      case 'lightGreen':
        return Colors.green[100]!;
      case 'white':
      default:
        return Colors.white;
    }
  }

  // Build profile image widget
  Widget _buildProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
        image: _profileImageFile != null
            ? DecorationImage(
          image: FileImage(_profileImageFile!),
          fit: BoxFit.cover,
        )
            : widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(widget.profileImageUrl!),
          fit: BoxFit.cover,
        )
            : null,
        color: Colors.grey[200],
      ),
      child: (_profileImageFile == null &&
          (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty))
          ? Icon(
        Icons.person,
        color: Colors.grey[400],
        size: size / 2,
      )
          : null,
    );
  }

  // Build the InfoBox widget
  Widget _buildInfoBox() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Colors.black; // Info box text is always black
    final fontSize = 14.0; // Default font size

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // Profile image or logo
          _buildProfileImage(50),
          SizedBox(width: 12),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPersonal)
                  Text(
                    widget.name?.isNotEmpty == true
                        ? widget.name!
                        : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company name first for business cards
                      Text(
                        widget.companyName?.isNotEmpty == true
                            ? widget.companyName!
                            : 'Company Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      // Then person's name
                      Text(
                        widget.name?.isNotEmpty == true
                            ? widget.name!
                            : 'Your Name',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                if (widget.location?.isNotEmpty == true)
                  Text(
                    widget.location!,
                    style: TextStyle(fontSize: fontSize - 2, color: textColor),
                  ),
                if (widget.mobile?.isNotEmpty == true)
                  Text(
                    widget.mobile!,
                    style: TextStyle(fontSize: fontSize - 2, color: textColor),
                  ),
                // Only show social media and description in business profile
                if (!widget.isPersonal) ...[
                  if (widget.socialMedia?.isNotEmpty == true)
                    Text(
                      widget.socialMedia!,
                      style: TextStyle(
                          fontSize: fontSize - 2,
                          color: Colors.blue),
                    ),
                  if (widget.description?.isNotEmpty == true)
                    Text(
                      widget.description!,
                      style: TextStyle(fontSize: fontSize - 2, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button - left side
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(color: Colors.black),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ),

                  Spacer(),

                  // Middle action icons
                  IconButton(
                    icon: SvgPicture.asset("assets/icons/share.svg"),
                    onPressed: _shareImage,
                    color: textColor.withOpacity(0.7),
                    iconSize: 20,
                  ),

                  // Download button - right side
                  ElevatedButton(
                    onPressed: _selectedImage != null ? _downloadImage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Download'),
                  ),
                ],
              ),
            ),

            // Image preview area with RepaintBoundary for capture
            Expanded(
              child: GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor!,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RepaintBoundary(
                    key: _brandedImageKey,
                    child: Column(
                      children: [
                        // Main image container
                        Expanded(
                          child: isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _selectedImage != null
                              ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          )
                              : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Circle with plus icon
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 40,
                                    color: isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to upload from gallery',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Info box at the isPaidUserbottom (only if showInfoBox is true)
                        if (widget.showInfoBox && _selectedImage != null)
                          _buildInfoBox(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom toolbar with Tools button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tools button
                  OutlinedButton(
                    onPressed: _selectedImage != null ? _navigateToEditScreen : _pickImageFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(100, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Tools'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}