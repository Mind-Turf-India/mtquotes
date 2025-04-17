import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    if (Platform.isAndroid && int.parse(Platform.operatingSystemVersion[0]) >= 13) {
      await Permission.photos.request();
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

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
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(pngBytes));
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _processedImage = frameInfo.image;
        _isProcessing = false;
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

      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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
    return byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }

  Future<void> _shareImage() async {
    if (_processedImage == null) return;

    try {
      // First save the image to a temporary file
      final bytes = await _imageToBytes(_processedImage!);

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      // Then share the file
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Check out this ${_isUpscaling ? 'upscaled' : 'downscaled'} image!',
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
      appBar: AppBar(
        title: Text('Image Upscaler'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Selection Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Selected Image Preview
              if (_originalImage != null) ...[
                Text(
                  'Original Image:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RawImage(
                    image: _originalImage,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Upscale/Downscale Toggle
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text('Downscale'),
              //     Switch(
              //       value: _isUpscaling,
              //       onChanged: (value) {
              //         setState(() {
              //           _isUpscaling = value;
              //           // Adjust quality range based on mode
              //           _quality = _isUpscaling ? 2.0 : 0.5;
              //         });
              //       },
              //     ),
              //     Text('Upscale'),
              //   ],
              // ),

              // Quality Slider
              Text(
                '${_isUpscaling ? "Upscale" : "Downscale"} Quality: ${_quality.toStringAsFixed(1)}x',
                textAlign: TextAlign.center,
              ),
              Slider(
                value: _quality,
                min: _isUpscaling ? 1.0 : 0.1,
                max: _isUpscaling ? 4.0 : 0.9,
                divisions: _isUpscaling ? 3 : 8,
                label: '${_quality.toStringAsFixed(1)}x',
                onChanged: (value) {
                  setState(() {
                    _quality = value;
                  });
                },
              ),

              // Process Button
              ElevatedButton.icon(
                onPressed: _originalImage == null || _isProcessing
                    ? null
                    : _processImage,
                icon: Icon(Icons.production_quantity_limits),
                label: Text(_isProcessing
                    ? 'Processing...'
                    : '${_isUpscaling ? "Upscale" : "Downscale"} Image'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              SizedBox(height: 20),

              // Processed Image Preview
              if (_processedImage != null) ...[
                Text(
                  'Processed Image:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RawImage(
                    image: _processedImage,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 16),

                // Save and Share Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveImage,
                      icon: Icon(Icons.download),
                      label: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _shareImage,
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}