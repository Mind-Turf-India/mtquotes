// import 'dart:io';
// import 'dart:typed_data';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mtquotes/utils/app_colors.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:ui' as ui;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';
// import 'package:http/http.dart' as http;

// import '../../../../utils/theme_provider.dart';

// class ImageUpscalingScreen extends StatefulWidget {
//   const ImageUpscalingScreen({Key? key}) : super(key: key);

//   @override
//   _ImageUpscalingScreenState createState() => _ImageUpscalingScreenState();
// }

// class _ImageUpscalingScreenState extends State<ImageUpscalingScreen> {
//   File? _imageFile;
//   ui.Image? _originalImage;
//   ui.Image? _processedImage;
//   bool _isProcessing = false;
//   double _quality = 2.0; // Default upscale factor
//   bool _isUpscaling = true; // Default mode is upscaling
//   final ScrollController _scrollController = ScrollController();
//   double _uploadProgress = 0.0;
//   String _processingStatus = '';

//   final ImagePicker _picker = ImagePicker();
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final FirebaseFunctions _functions = FirebaseFunctions.instance;
//   final _uuid = Uuid();

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _requestPermissions() async {
//     await Permission.storage.request();

//     if (Platform.isAndroid) {
//       try {
//         final sdkInt =
//             int.tryParse(Platform.operatingSystemVersion.split(' ').last) ?? 0;
//         if (sdkInt >= 13) {
//           await Permission.photos.request();
//         }
//       } catch (e) {
//         await Permission.photos.request();
//         debugPrint('Error checking Android version: $e');
//       }
//     }
//   }

//   Future<void> _pickImage() async {
//     final XFile? pickedFile =
//         await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       await _loadImage(File(pickedFile.path));
//     }
//   }

//   Future<void> _takePhoto() async {
//     final XFile? pickedFile =
//         await _picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       await _loadImage(File(pickedFile.path));
//     }
//   }

//   Future<void> _loadImage(File file) async {
//     try {
//       setState(() {
//         _imageFile = file;
//         _processedImage = null;
//       });

//       final bytes = await file.readAsBytes();
//       final codec = await ui.instantiateImageCodec(bytes);
//       final frameInfo = await codec.getNextFrame();

//       setState(() {
//         _originalImage = frameInfo.image;
//       });
//     } catch (e) {
//       debugPrint('Error loading image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load image')),
//       );
//     }
//   }

//   Future<void> _processImage() async {
//     if (_imageFile == null || _originalImage == null) return;

//     setState(() {
//       _isProcessing = true;
//       _uploadProgress = 0.0;
//       _processingStatus = 'Preparing to upload...';
//     });

//     try {
//       // Generate a unique ID for this processing job
//       final String jobId = _uuid.v4();
//       final String fileName = 'upscale_$jobId.jpg';
      
//       // Reference to the storage location
//       final storageRef = _storage.ref().child('upscale_jobs/$fileName');
      
//       // Upload image with progress tracking
//       final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      
//       // Track upload progress
//       uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//         final progress = snapshot.bytesTransferred / snapshot.totalBytes;
//         setState(() {
//           _uploadProgress = progress;
//           _processingStatus = 'Uploading image: ${(progress * 100).toStringAsFixed(0)}%';
//         });
//       });

//       // Wait for upload to complete
//       await uploadTask.whenComplete(() {
//         setState(() {
//           _processingStatus = 'Image uploaded, starting processing...';
//         });
//       });
      
//       // Get download URL of the uploaded image
//       final String imageUrl = await storageRef.getDownloadURL();
      
//       // Call Firebase Cloud Function to process the image
//       setState(() {
//         _processingStatus = 'Processing with ML model...';
//       });
      
//       final HttpsCallableResult result = await _functions.httpsCallable('upscaleImage').call({
//         'imageUrl': imageUrl,
//         'factor': _quality,
//         'mode': _isUpscaling ? 'upscale' : 'downscale',
//         'jobId': jobId
//       });
      
//       // Get processed image URL from function result
//       final processedImageUrl = result.data['processedImageUrl'];
      
//       setState(() {
//         _processingStatus = 'Downloading processed image...';
//       });
      
//       // Download the processed image
//       final response = await http.get(Uri.parse(processedImageUrl));
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to download processed image');
//       }
      
//       // Convert downloaded bytes to ui.Image
//       final Uint8List bytes = response.bodyBytes;
//       final codec = await ui.instantiateImageCodec(bytes);
//       final frameInfo = await codec.getNextFrame();
      
//       // Save to temporary file for sharing/saving later
//       final tempDir = await getTemporaryDirectory();
//       final tempPath = '${tempDir.path}/processed_$jobId.jpg';
//       final tempFile = File(tempPath);
//       await tempFile.writeAsBytes(bytes);
      
//       setState(() {
//         _processedImage = frameInfo.image;
//         _isProcessing = false;
//       });
      
//       // Scroll to show the processed image
//       Future.delayed(Duration(milliseconds: 300), () {
//         if (_scrollController.hasClients) {
//           _scrollController.animateTo(
//             _scrollController.position.maxScrollExtent,
//             duration: Duration(milliseconds: 500),
//             curve: Curves.easeOut,
//           );
//         }
//       });
      
//     } catch (e) {
//       setState(() {
//         _isProcessing = false;
//       });
//       debugPrint('Error processing image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error processing image: $e')),
//       );
//     }
//   }

//   Future<void> _saveImage() async {
//     if (_processedImage == null) {
//       showNoImageSelectedDialog();
//       return;
//     }

//     _showLoadingIndicator();

//     try {
//       // Convert the ui.Image to bytes
//       final bytes = await _imageToBytes(_processedImage!);

//       // Request proper permissions based on platform and Android version
//       bool hasPermission = false;

//       if (Platform.isAndroid) {
//         // Request different permissions based on Android SDK version
//         if (await _getAndroidVersion() >= 33) {
//           // Android 13+
//           hasPermission = await _requestAndroid13Permission();
//         } else if (await _getAndroidVersion() >= 29) {
//           // Android 10-12
//           hasPermission = await Permission.storage.isGranted;
//           if (!hasPermission) {
//             hasPermission = (await Permission.storage.request()).isGranted;
//           }
//         } else {
//           // Android 9 and below
//           hasPermission = await Permission.storage.isGranted;
//           if (!hasPermission) {
//             hasPermission = (await Permission.storage.request()).isGranted;
//           }
//         }
//       } else if (Platform.isIOS) {
//         // iOS typically doesn't need explicit permission for saving to gallery
//         hasPermission = true;
//       }

//       if (!hasPermission) {
//         _hideLoadingIndicator();
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//             content: Text("Storage permission is required to save images")));
//         return;
//       }

//       // Generate a unique filename based on timestamp
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final fileName = "Vaky_${timestamp}.jpg";

//       // Save to gallery
//       final result = await ImageGallerySaverPlus.saveImage(
//         bytes,
//         quality: 100,
//         name: fileName,
//       );

//       // Check if save was successful
//       bool isGallerySaveSuccess = false;
//       if (result is Map) {
//         isGallerySaveSuccess = result['isSuccess'] ?? false;
//       } else {
//         isGallerySaveSuccess = result != null;
//       }

//       if (!isGallerySaveSuccess) {
//         throw Exception("Failed to save image to gallery");
//       }

//       // Also save to downloads directory for easy access
//       final downloadsDir = await getDownloadsDirectory();
//       if (downloadsDir != null) {
//         String filePath = '${downloadsDir.path}/$fileName';
//         File file = File(filePath);
//         await file.writeAsBytes(bytes);
//       }

//       _hideLoadingIndicator();

//       // Show success message
//       final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//       final isDarkMode = themeProvider.isDarkMode;

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Image saved to your gallery and downloads"),
//           duration: Duration(seconds: 3),
//           backgroundColor: isDarkMode
//               ? AppColors.primaryGreen.withOpacity(0.7)
//               : AppColors.primaryGreen,
//         ),
//       );

//       print("Image saved to gallery and downloads: $fileName");
//     } catch (e) {
//       _hideLoadingIndicator();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error saving image: $e")),
//       );
//       print("Error saving image: $e");
//     }
//   }

//   // Get Android version as an integer (e.g., 29 for Android 10)
//   Future<int> _getAndroidVersion() async {
//     if (Platform.isAndroid) {
//       try {
//         final androidInfo = await DeviceInfoPlugin().androidInfo;
//         return androidInfo.version.sdkInt;
//       } catch (e) {
//         print('Error getting Android version: $e');
//         return 0;
//       }
//     }
//     return 0;
//   }

//   // Request permissions for Android 13+ (API level 33+)
//   Future<bool> _requestAndroid13Permission() async {
//     // Check if photos permission is already granted
//     bool photosGranted = await Permission.photos.isGranted;

//     if (!photosGranted) {
//       // Request photos permission
//       final status = await Permission.photos.request();
//       photosGranted = status.isGranted;
//     }

//     return photosGranted;
//   }

//   // Helper method to show a dialog when no image is selected
//   void showNoImageSelectedDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("No Image"),
//           content: Text("Please process an image first."),
//           actions: [
//             TextButton(
//               child: Text("OK"),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Show loading indicator dialog
//   void _showLoadingIndicator() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           content: Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(width: 20),
//               Text("Saving image...", style: TextStyle(color: Colors.blue)),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Hide loading indicator
//   void _hideLoadingIndicator() {
//     Navigator.of(context, rootNavigator: true).pop();
//   }

//   Future<Uint8List> _imageToBytes(ui.Image image) async {
//     final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//     if (byteData == null) {
//       throw Exception('Failed to convert image to byte data');
//     }
//     return byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
//   }

//   Future<void> _shareImage() async {
//     if (_processedImage == null) return;

//     try {
//       // First save the image to a temporary file
//       final bytes = await _imageToBytes(_processedImage!);

//       final tempDir = await getTemporaryDirectory();
//       final tempPath =
//           '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.png';

//       final tempFile = File(tempPath);
//       await tempFile.writeAsBytes(bytes);

//       // Then share the file
//       await Share.shareXFiles(
//         [XFile(tempPath)],
//         text:
//             'Check out this ${_isUpscaling ? 'upscaled' : 'downscaled'} image!',
//       );
//     } catch (e) {
//       debugPrint('Error sharing image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing image: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: Text('AI Image Enhancement'),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         controller: _scrollController,
//         physics: BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Image Upload Card
//               if (_originalImage == null) ...[
//                 Container(
//                   margin: EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                         color: AppColors.getDividerColor(
//                             Theme.of(context).brightness == Brightness.dark)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.upload_file,
//                           size: 40,
//                           color: Colors.grey[600],
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Select an image to enhance with our AI model',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.grey[700],
//                             fontSize: 14,
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             ElevatedButton.icon(
//                               onPressed: _pickImage,
//                               icon: Icon(Icons.photo_library),
//                               label: Text('Gallery'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.primaryBlue,
//                                 foregroundColor:
//                                     Theme.of(context).colorScheme.surface,
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 24, vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 16),
//                             ElevatedButton.icon(
//                               onPressed: _takePhoto,
//                               icon: Icon(Icons.camera_alt),
//                               label: Text('Camera'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.grey[800],
//                                 foregroundColor:
//                                     Theme.of(context).colorScheme.surface,
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 24, vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],

//               // Image Preview Area
//               if (_originalImage != null) ...[
//                 Container(
//                   margin: EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                         color: AppColors.getDividerColor(
//                             Theme.of(context).brightness == Brightness.dark)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Stack(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: AspectRatio(
//                           aspectRatio: 1.0,
//                           child: RawImage(
//                             image: _originalImage,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 8,
//                         right: 8,
//                         child: InkWell(
//                           onTap: () {
//                             setState(() {
//                               _imageFile = null;
//                               _originalImage = null;
//                               _processedImage = null;
//                             });
//                           },
//                           child: Container(
//                             padding: EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Theme.of(context).colorScheme.surface,
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   spreadRadius: 1,
//                                   blurRadius: 2,
//                                 )
//                               ],
//                             ),
//                             child: Icon(Icons.close, size: 18),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // Resolution Info
//               if (_originalImage != null) ...[
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Original Resolution:',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 12,
//                             ),
//                           ),
//                           Text(
//                             '${_originalImage!.width} x ${_originalImage!.height}',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                                  color: AppColors.getTextColor(Theme.of(context).brightness == Brightness.dark),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // Mode Toggle
//               if (_originalImage != null) ...[
//                 Container(
//                   margin: EdgeInsets.only(bottom: 16),
//                   padding: EdgeInsets.symmetric(vertical: 16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                         color: AppColors.getDividerColor(
//                             Theme.of(context).brightness == Brightness.dark)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Upscale/Downscale Toggle
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Downscale',
//                             style: TextStyle(
//                               color: !_isUpscaling
//                                   ? Theme.of(context).colorScheme.primary
//                                   : AppColors.getSecondaryTextColor(
//                                       Theme.of(context).brightness ==
//                                           Brightness.dark),
//                               fontWeight: !_isUpscaling
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                           Switch(
//                             value: _isUpscaling,
//                             onChanged: (value) {
//                               setState(() {
//                                 _isUpscaling = value;
//                                 // Adjust quality range based on mode
//                                 _quality = _isUpscaling ? 2.0 : 0.5;
//                               });
//                             },
//                             activeColor: AppColors.primaryBlue,
//                           ),
//                           Text(
//                             'Upscale',
//                             style: TextStyle(
//                               color: _isUpscaling
//                                   ? AppColors.primaryBlue
//                                   : Colors.grey[600],
//                               fontWeight: _isUpscaling
//                                   ? FontWeight.bold
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16),

//                       // AI Model selection (new)
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: Row(
//                           children: [
//                             Text(
//                               'AI Model:',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 12),
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.grey[300]!),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: DropdownButton<String>(
//                                   value: 'esrgan',
//                                   isExpanded: true,
//                                   underline: SizedBox(),
//                                   items: [
//                                     DropdownMenuItem(
//                                       value: 'esrgan',
//                                       child: Text('ESRGAN (Best Quality)'),
//                                     ),
//                                     DropdownMenuItem(
//                                       value: 'fsrcnn',
//                                       child: Text('FSRCNN (Faster)'),
//                                     ),
//                                     DropdownMenuItem(
//                                       value: 'lapsrn',
//                                       child: Text('LapSRN (Balanced)'),
//                                     ),
//                                   ],
//                                   onChanged: (value) {
//                                     // In the future, you can update the model selection
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       SizedBox(height: 16),

//                       // Quality Slider
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   '${_isUpscaling ? "Upscale" : "Downscale"} Factor:',
//                                   style: TextStyle(
//                                     color: Colors.grey[700],
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 12, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .primary
//                                         .withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     '${_quality.toStringAsFixed(1)}x',
//                                     style: TextStyle(
//                                       color: AppColors.primaryBlue,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             SizedBox(height: 8),
//                             SliderTheme(
//                               data: SliderTheme.of(context).copyWith(
//                                 activeTrackColor:
//                                     Theme.of(context).colorScheme.primary,
//                                 inactiveTrackColor: Theme.of(context)
//                                     .colorScheme
//                                     .primary
//                                     .withOpacity(0.2),
//                                 thumbColor:
//                                     Theme.of(context).colorScheme.surface,
//                                 overlayColor: Theme.of(context)
//                                     .colorScheme
//                                     .primary
//                                     .withOpacity(0.2),
//                                 thumbShape: RoundSliderThumbShape(
//                                     enabledThumbRadius: 12),
//                                 overlayShape:
//                                     RoundSliderOverlayShape(overlayRadius: 24),
//                               ),
//                               child: Slider(
//                                 value: _quality,
//                                 min: _isUpscaling ? 1.0 : 0.1,
//                                 max: _isUpscaling ? 4.0 : 0.9,
//                                 divisions: _isUpscaling ? 6 : 8,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _quality = value;
//                                   });
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       SizedBox(height: 16),

//                       // Process Button
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: ElevatedButton(
//                           onPressed: _isProcessing ? null : _processImage,
//                           child: _isProcessing
//                               ? Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .surface,
//                                         strokeWidth: 2,
//                                       ),
//                                     ),
//                                     SizedBox(width: 12),
//                                     Text('Processing...'),
//                                   ],
//                                 )
//                               : Text(
//                                   'Enhance with AI'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primaryBlue,
//                             foregroundColor:
//                                 Theme.of(context).colorScheme.surface,
//                             padding: EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             minimumSize: Size(double.infinity, 50),
//                             disabledBackgroundColor: Theme.of(context)
//                                 .colorScheme
//                                 .primary
//                                 .withOpacity(0.6),
//                             disabledForegroundColor: Colors.white70,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // Processing Indicator (Only visible when processing)
//               if (_isProcessing) ...[
//                 Container(
//                   margin: EdgeInsets.only(bottom: 16),
//                   padding: EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: AppColors.primaryBlue),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .primary
//                             .withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 48,
//                             height: 48,
//                             decoration: BoxDecoration(
//                               color: Theme.of(context)
//                                   .colorScheme
//                                   .primary
//                                   .withOpacity(0.1),
//                               shape: BoxShape.circle,
//                             ),
//                             child: Center(
//                               child: SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                   color: AppColors.primaryBlue,
//                                   strokeWidth: 2,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'AI Processing in progress...',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: AppColors.getTextColor(
//                                         Theme.of(context).brightness ==
//                                             Brightness.dark),
//                                   ),
//                                 ),
//                                 Text(
//                                   _processingStatus,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16),
//                       LinearProgressIndicator(
//                         value: _uploadProgress,
//                         backgroundColor:
//                             Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                             Theme.of(context).colorScheme.primary),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         'This may take up to 30 seconds depending on image size',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                           fontStyle: FontStyle.italic,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],

//               // Processed Image Display
//               if (_processedImage != null) ...[
//                 Container(
//                   margin: EdgeInsets.only(bottom: 16),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                         color: AppColors.getDividerColor(
//                             Theme.of(context).brightness == Brightness.dark)),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.check_circle,
//                               color: Colors.green,
//                               size: 20,
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               'Enhanced Result',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 color: AppColors.getTextColor(
//                                     Theme.of(context).brightness ==
//                                         Brightness.dark),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         child: Text(
//                           'Resolution: ${_processedImage!.width} x ${_processedImage!.height}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       AspectRatio(
//                         aspectRatio: 1.0,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           child: RawImage(
//                             image: _processedImage,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 16),
//                       Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: _saveImage,
//                                 icon: Icon(Icons.save),
//                                 label: Text('Save'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: AppColors.primaryGreen,
//                                   foregroundColor:
//                                       Theme.of(context).colorScheme.surface,
//                                   padding: EdgeInsets.symmetric(vertical: 12),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: _shareImage,
//                                 icon: Icon(Icons.share),
//                                 label: Text('Share'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: AppColors.primaryBlue,
//                                   foregroundColor:
//                                       Theme.of(context).colorScheme.surface,
//                                   padding: EdgeInsets.symmetric(vertical: 12),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Compare Button
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => Dialog(
//                         child: Container(
//                           padding: EdgeInsets.all(16),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 'Before & After Comparison',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               SizedBox(height: 16),
//                               AspectRatio(
//                                 aspectRatio: 1.0,
//                                 child: PageView(
//                                   children: [
//                                     Column(
//                                       children: [
//                                         Text('Original'),
//                                         Expanded(
//                                           child: RawImage(
//                                             image: _originalImage,
//                                             fit: BoxFit.contain,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     Column(
//                                       children: [
//                                         Text('Enhanced'),
//                                         Expanded(
//                                           child: RawImage(
//                                             image: _processedImage,
//                                             fit: BoxFit.contain,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               SizedBox(height: 16),
//                               Text(
//                                 'Swipe to compare images',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               SizedBox(height: 16),
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pop();
//                                 },
//                                 child: Text('Close'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                   icon: Icon(Icons.compare),
//                   label: Text('Compare Before & After'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[800],
//                     foregroundColor: Theme.of(context).colorScheme.surface,
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     minimumSize: Size(double.infinity, 50),
//                   ),
//                 ),
//               ],

//               // Information and FAQ
//               SizedBox(height: 24),
//               ExpansionTile(
//                 title: Text(
//                   'About Image Enhancement',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.getTextColor(
//                         Theme.of(context).brightness == Brightness.dark),
//                   ),
//                 ),
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Our AI image enhancement uses advanced deep learning models to:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         _buildInfoItem(
//                           '• Increase resolution while preserving details',
//                         ),
//                         _buildInfoItem(
//                           '• Reduce noise and artifacts from low-quality images',
//                         ),
//                         _buildInfoItem(
//                           '• Recover lost details and textures',
//                         ),
//                         _buildInfoItem(
//                           '• Optimize for different types of images',
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           'Frequently Asked Questions:',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         _buildFaqItem(
//                           'What file types are supported?',
//                           'JPEG, PNG, and most common image formats are supported.',
//                         ),
//                         _buildFaqItem(
//                           'Is there a file size limit?',
//                           'Yes, images up to 10MB can be processed.',
//                         ),
//                         _buildFaqItem(
//                           'How long does processing take?',
//                           'Processing typically takes 5-30 seconds depending on image size and server load.',
//                         ),
//                         _buildFaqItem(
//                           'Are my images stored on your servers?',
//                           'Images are only temporarily stored during processing and then automatically deleted.',
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: Colors.grey[700],
//           fontSize: 14,
//         ),
//       ),
//     );
//   }

//   Widget _buildFaqItem(String question, String answer) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             question,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//               color: AppColors.getTextColor(
//                   Theme.of(context).brightness == Brightness.dark),
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             answer,
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }