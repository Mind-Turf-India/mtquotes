import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class ImageUpscalingScreen extends StatefulWidget {
  const ImageUpscalingScreen({Key? key}) : super(key: key);

  @override
  _ImageUpscalingScreenState createState() => _ImageUpscalingScreenState();
}

class _ImageUpscalingScreenState extends State<ImageUpscalingScreen> {
  File? _imageFile;
  ui.Image? _originalImage;
  ui.Image? _processedImage;
  bool _isProcessing = false;
  double _quality = 2.0; // Default upscale factor
  bool _isUpscaling = true; // Default mode is upscaling
  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();

    // Fixed the Android API level check
    if (Platform.isAndroid) {
      try {
        // A safer way to check Android SDK version
        final sdkInt =
            int.tryParse(Platform.operatingSystemVersion.split(' ').last) ?? 0;
        if (sdkInt >= 13) {
          await Permission.photos.request();
        }
      } catch (e) {
        // Fallback - just request photos permission if we can't determine version
        await Permission.photos.request();
        debugPrint('Error checking Android version: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _loadImage(File file) async {
    try {
      setState(() {
        _imageFile = file;
        _processedImage = null;
      });

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _originalImage = frameInfo.image;
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load image')),
      );
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null || _originalImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Using the image package for basic image processing
      // (instead of relying on the ONNX model)
      final bytes = await _imageFile!.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      img.Image processedImage;

      if (_isUpscaling) {
        // Upscale the image using resize
        final scaleFactor = _quality.toInt();
        processedImage = img.copyResize(
          image,
          width: image.width * scaleFactor,
          height: image.height * scaleFactor,
          interpolation: img.Interpolation.cubic,
        );
      } else {
        // Downscale the image
        final scaleFactor = _quality;
        processedImage = img.copyResize(
          image,
          width: (image.width * scaleFactor).toInt(),
          height: (image.height * scaleFactor).toInt(),
          interpolation: img.Interpolation.average,
        );
      }

      // Convert processed image back to ui.Image
      final pngBytes = img.encodePng(processedImage);
      final codec =
          await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _processedImage = frameInfo.image;
        _isProcessing = false;
      });

      // Scroll to bottom to show the processed image after a short delay
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Error processing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    try {
      // Convert the ui.Image to bytes
      final bytes = await _imageToBytes(_processedImage!);

      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savePath = '${directory.path}/processed_image_$timestamp.png';

      final file = File(savePath);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to $savePath')),
      );
    } catch (e) {
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to byte data');
    }
    return byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }

  Future<void> _shareImage() async {
    if (_processedImage == null) return;

    try {
      // First save the image to a temporary file
      final bytes = await _imageToBytes(_processedImage!);

      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      // Then share the file
      await Share.shareXFiles(
        [XFile(tempPath)],
        text:
            'Check out this ${_isUpscaling ? 'upscaled' : 'downscaled'} image!',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Upload Image'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Card
              if (_originalImage == null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getDividerColor(
                            Theme.of(context).brightness == Brightness.dark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Drop or select multiple files from your device',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: Text('Select image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor:
                                Theme.of(context).colorScheme.surface,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Image Preview Area
              if (_originalImage != null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getDividerColor(
                            Theme.of(context).brightness == Brightness.dark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: RawImage(
                            image: _originalImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _imageFile = null;
                              _originalImage = null;
                              _processedImage = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                )
                              ],
                            ),
                            child: Icon(Icons.close, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Resolution Info
              if (_originalImage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original Resolution:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_originalImage!.width} x ${_originalImage!.height}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                                 color: AppColors.getTextColor(Theme.of(context).brightness == Brightness.dark),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Edit button functionality
                        },
                        child: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor:
                              Theme.of(context).colorScheme.surface,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Mode Toggle
              if (_originalImage != null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.getDividerColor(
                            Theme.of(context).brightness == Brightness.dark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Upscale/Downscale Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Downscale',
                            style: TextStyle(
                              color: !_isUpscaling
                                  ? Theme.of(context).colorScheme.primary
                                  : AppColors.getSecondaryTextColor(
                                      Theme.of(context).brightness ==
                                          Brightness.dark),
                              fontWeight: !_isUpscaling
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Switch(
                            value: _isUpscaling,
                            onChanged: (value) {
                              setState(() {
                                _isUpscaling = value;
                                // Adjust quality range based on mode
                                _quality = _isUpscaling ? 2.0 : 0.5;
                              });
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          Text(
                            'Upscale',
                            style: TextStyle(
                              color: _isUpscaling
                                  ? AppColors.primaryBlue
                                  : Colors.grey[600],
                              fontWeight: _isUpscaling
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Quality Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_isUpscaling ? "Upscale" : "Downscale"} Factor:',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_quality.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor:
                                    Theme.of(context).colorScheme.primary,
                                inactiveTrackColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                thumbColor:
                                    Theme.of(context).colorScheme.surface,
                                overlayColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 12),
                                overlayShape:
                                    RoundSliderOverlayShape(overlayRadius: 24),
                              ),
                              child: Slider(
                                value: _quality,
                                min: _isUpscaling ? 1.0 : 0.1,
                                max: _isUpscaling ? 4.0 : 0.9,
                                divisions: _isUpscaling ? 3 : 8,
                                onChanged: (value) {
                                  setState(() {
                                    _quality = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Process Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _processImage,
                          child: _isProcessing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Processing...'),
                                  ],
                                )
                              : Text(
                                  '${_isUpscaling ? "Upscale" : "Downscale"} Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor:
                                Theme.of(context).colorScheme.surface,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(double.infinity, 50),
                            disabledBackgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.6),
                            disabledForegroundColor: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Processing Indicator (Only visible when processing)
              if (_isProcessing) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBlue,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_isUpscaling ? "Upscaling" : "Downscaling"} in progress...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                   color: AppColors.getTextColor(Theme.of(context).brightness == Brightness.dark),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Please wait while we enhance your image with ${_quality.toStringAsFixed(1)}x factor.',
                              style: TextStyle(
                                // color: Colors.grey[600],
                                fontSize: 14,
                                   color: AppColors.getTextColor(Theme.of(context).brightness == Brightness.dark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Processed Image Preview with animated appearance
              if (_processedImage != null && !_isProcessing) ...[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Enhanced Image Ready!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Your image has been successfully ${_isUpscaling ? "upscaled" : "downscaled"} with ${_quality.toStringAsFixed(1)}x factor.',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.getDividerColor(
                                      Theme.of(context).brightness ==
                                          Brightness.dark)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: RawImage(
                                  image: _processedImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveImage,
                                  icon: Icon(Icons.download),
                                  label: Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareImage,
                                  icon: Icon(Icons.share),
                                  label: Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black87,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}






