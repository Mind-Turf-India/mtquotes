import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../edit_screen_create.dart';

class ImagePickerScreen extends StatefulWidget {
  final String? templateImageUrl;
  final Uint8List? initialImageData;

  const ImagePickerScreen({
    super.key,
    this.templateImageUrl,
    this.initialImageData,
  });

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  Uint8List? _templateImageData; // To store template image data

  @override
  void initState() {
    super.initState();
    print("ImagePickerScreen initState called");
    print("Received templateImageUrl: ${widget.templateImageUrl}");

    // If the URL is received, check if it's valid
    if (widget.templateImageUrl != null && widget.templateImageUrl!.isNotEmpty) {
      print("URL is valid, will load template from: ${widget.templateImageUrl}");
      _loadTemplateFromUrl(widget.templateImageUrl!);
    } else {
      print("No valid URL received in ImagePickerScreen");
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

  // Navigate to edit screen
  void _navigateToEditScreen() {
    if (_selectedImage != null) {
      // Use the new EditScreen2 instead of EditScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            imageFile: _selectedImage!,
            templateImageUrl: widget.templateImageUrl, // Pass the template URL
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

  // Share image
  Future<void> _shareImage() async {
    if (_selectedImage == null) {
      _showNoImageSelectedDialog();
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_selectedImage!.path)],
        text: 'Check out this image!',
      );
    } catch (e) {
      _showErrorDialog('Error sharing image: $e');
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
                    icon: const Icon(Icons.share),
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

            // Image preview area
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