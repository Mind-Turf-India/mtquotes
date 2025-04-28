import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:mtquotes/screens/User_Home/components/Doc%20Scanner/pdf_signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

import 'gallery_selection.dart';

class DocScanner extends StatefulWidget {
  const DocScanner({Key? key}) : super(key: key);

  @override
  State<DocScanner> createState() => _DocScannerState();
}

class _DocScannerState extends State<DocScanner> {
  dynamic _scannedDocuments;
  bool _isLoading = false;
  String? _savedFilePath;
  List<String>? _savedImagePaths;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _createVakyFolder();
  }

  Future<void> _requestPermissions() async {
    // Request basic permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
    ].request();

    // For Android 11+, handle MANAGE_EXTERNAL_STORAGE separately
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.isGranted) {
        // Show a dialog explaining why you need this permission
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Storage Permission Required'),
            content: Text('To save documents to external storage, please grant "All Files Access" permission in the next screen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Continue'),
              ),
            ],
          ),
        );

        if (result == true) {
          await Permission.manageExternalStorage.request();

          // If still not granted, open app settings
          if (!await Permission.manageExternalStorage.isGranted) {
            final settingsOpened = await openAppSettings();
            if (!settingsOpened) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please open app settings and grant "All Files Access" permission')),
              );
            }
          }
        }
      }
    }

    // Check final status
    if (statuses[Permission.storage]!.isDenied ||
        statuses[Permission.camera]!.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions are required to use the document scanner'),
        ),
      );
    }
  }

  Future<void> _createVakyFolder() async {
    try {
      final directory = await _vakyDirectory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created vaky directory at: ${directory.path}');
      }
    } catch (e) {
      print('Error creating vaky directory: $e');
    }
  }

  // Get the "vaky" directory
  Future<Directory> get _vakyDirectory async {
    if (Platform.isAndroid) {
      // For Android 10+ (API level 29+), use app-specific external storage
      Directory? directory;

      if (await Permission.manageExternalStorage.isGranted) {
        // If we have all file access permission (Android 11+)
        try {
          directory = Directory('/storage/emulated/0/Vaky');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        } catch (e) {
          print('Error accessing external storage: $e');
          // Fall back to app-specific storage
        }
      }

      // Use app-specific external storage as fallback
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        final vakyDir = Directory('${directory.path}/vaky');
        if (!await vakyDir.exists()) {
          await vakyDir.create(recursive: true);
        }
        return vakyDir;
      }

      // Last resort: use internal storage
      final appDir = await getApplicationDocumentsDirectory();
      final vakyDir = Directory('${appDir.path}/vaky');
      if (!await vakyDir.exists()) {
        await vakyDir.create(recursive: true);
      }
      return vakyDir;
    } else {
      // For iOS, use the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final vakyDir = Directory('${directory.path}/vaky');
      if (!await vakyDir.exists()) {
        await vakyDir.create(recursive: true);
      }
      return vakyDir;
    }
  }

  Future<String> get _vakyPath async {
    final directory = await _vakyDirectory;
    return directory.path;
  }

  Future<File> _getVakyFile(String filename) async {
    final path = await _vakyPath;
    return File('$path/$filename');
  }

  // Add this method to show options after scanning
  void _showScanResultOptions(String filePath) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Document Scanned Successfully',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.download, color: Colors.blue),
                title: Text('Download PDF'),
                onTap: () {
                  Navigator.pop(context);
                  // Show the downloaded file path
                  setState(() {
                    _savedFilePath = filePath;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.green),
                title: Text('Fill & Sign PDF'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfSignatureScreen(pdfPath: filePath),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Replace the current _pickImageFromGallery method with this one
  // Future<void> _pickImageFromGallery() async {
  //   try {
  //     final List<XFile>? pickedFiles = await _picker.pickMultiImage();
  //
  //     if (pickedFiles != null && pickedFiles.isNotEmpty) {
  //       // Navigate to the gallery selection page
  //       final result = await Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => GallerySelectionPage(selectedImages: pickedFiles),
  //         ),
  //       );
  //
  //       // Check if result is a Map (new format) or List (old format)
  //       if (result != null) {
  //         bool shouldLaunchScanner = false;
  //         List<XFile> selectedImages = [];
  //
  //         if (result is Map) {
  //           // New format with launchScanner flag
  //           selectedImages = result['images'] as List<XFile>;
  //           shouldLaunchScanner = result['launchScanner'] ?? false;
  //         } else if (result is List<XFile>) {
  //           // Old format for backward compatibility
  //           selectedImages = result;
  //         }
  //
  //         if (selectedImages.isNotEmpty) {
  //           setState(() {
  //             _isLoading = true;
  //             _savedFilePath = null;
  //             _savedImagePaths = null;
  //           });
  //
  //           _savedImagePaths = [];
  //
  //           // Process each selected image
  //           for (int i = 0; i < selectedImages.length; i++) {
  //             final filename = 'gallery_doc_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
  //             final file = await _getVakyFile(filename);
  //
  //             // Copy the image file to our vaky folder
  //             final bytes = await File(selectedImages[i].path).readAsBytes();
  //             await file.writeAsBytes(bytes);
  //             _savedImagePaths!.add(file.path);
  //             print('Gallery image saved to: ${file.path}');
  //           }
  //
  //           // If should launch scanner and there are images, launch the document scanner
  //           if (shouldLaunchScanner) {
  //             // Call the scanDocument method to open the scanner
  //             // First finish the current operation
  //             setState(() {
  //               _isLoading = false;
  //             });
  //
  //             // Then launch the scanner
  //             await scanDocument();
  //             return;
  //           }
  //
  //           // If not launching scanner, continue with normal flow
  //           // If there's only one image, consider converting it to PDF
  //           if (_savedImagePaths!.length == 1) {
  //             final imagePath = _savedImagePaths![0];
  //             setState(() {
  //               _isLoading = false;
  //               _scannedDocuments = 'Imported from gallery';
  //             });
  //             // Show options dialog for the single image
  //             _showSingleImageOptions(imagePath);
  //           } else {
  //             setState(() {
  //               _isLoading = false;
  //               _scannedDocuments = 'Imported multiple images from gallery';
  //             });
  //           }
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     print('Error picking images from gallery: $e');
  //     setState(() {
  //       _isLoading = false;
  //       _scannedDocuments = 'Error: ${e.toString()}';
  //     });
  //   }
  // }

  // Show options for a single imported image
  // void _showSingleImageOptions(String imagePath) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Image Imported Successfully',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //             ListTile(
  //               leading: Icon(Icons.image, color: Colors.blue),
  //               title: Text('View Image'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _openFile(imagePath);
  //               },
  //             ),
  //             ListTile(
  //               leading: Icon(Icons.picture_as_pdf, color: Colors.red),
  //               title: Text('Convert to PDF'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text('PDF conversion will be implemented soon')),
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> scanDocument() async {
    setState(() {
      _isLoading = true;
      _savedFilePath = null;
      _savedImagePaths = null;
    });

    dynamic scannedDocuments;
    try {
      scannedDocuments = await FlutterDocScanner().getScanDocuments(page: 4) ??
          'Unknown platform documents';

      print('Raw scan result: $scannedDocuments');

      if (scannedDocuments is Map && scannedDocuments.containsKey('pdfUri')) {
        // If we have a PDF URI, get the PDF
        final pdfUri = scannedDocuments['pdfUri'] as String;
        final filename = 'scanned_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = await _getVakyFile(filename);

        try {
          // Handle file URI correctly
          String filePath = pdfUri;
          if (filePath.startsWith('file://')) {
            filePath = filePath.replaceFirst('file://', '');
          }

          final sourceFile = File(filePath);
          if (await sourceFile.exists()) {
            // Read and write bytes instead of using copy
            final bytes = await sourceFile.readAsBytes();
            await file.writeAsBytes(bytes);
            _savedFilePath = file.path;
            print('PDF saved to: ${file.path}');

            // Show options for the saved PDF
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _scannedDocuments = scannedDocuments;
            });
            _showScanResultOptions(file.path);
            return;
          } else {
            print('Source file does not exist: $filePath');
          }
        } catch (e) {
          print('Error copying PDF: $e');
        }
      } else if (scannedDocuments is List && scannedDocuments.isNotEmpty) {
        _savedImagePaths = [];

        for (int i = 0; i < scannedDocuments.length; i++) {
          final filename = 'scanned_doc_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final file = await _getVakyFile(filename);

          // Convert base64 string to file if needed
          if (scannedDocuments[i] is String) {
            try {
              final bytes = base64Decode(scannedDocuments[i]);
              await file.writeAsBytes(bytes);
              _savedImagePaths!.add(file.path);
              print('Image saved to: ${file.path}');
            } catch (e) {
              print('Error converting document to file: $e');
            }
          } else if (scannedDocuments[i] is File) {
            final savedFile = await scannedDocuments[i].copy(file.path);
            _savedImagePaths!.add(savedFile.path);
            print('Image saved to: ${savedFile.path}');
          }
        }
      }
    } on PlatformException catch (e) {
      scannedDocuments = 'Failed to get scanned documents: ${e.message}';
      print(scannedDocuments);
    } catch (e) {
      scannedDocuments = 'Error: ${e.toString()}';
      print(scannedDocuments);
    }

    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
      _isLoading = false;
    });
  }

  Future<void> scanDocumentAsPdf() async {
    setState(() {
      _isLoading = true;
      _savedFilePath = null;
      _savedImagePaths = null;
    });

    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScannedDocumentAsPdf(page: 4) ??
              'Unknown platform documents';

      print('Raw scan result as PDF: $scannedDocuments');

      // Handle PDF result
      if (scannedDocuments is Map && scannedDocuments.containsKey('pdfUri')) {
        // If we have a PDF URI from the scanner
        final pdfUri = scannedDocuments['pdfUri'] as String;
        final filename = 'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = await _getVakyFile(filename);

        try {
          // Copy the PDF file from the URI to our vaky folder
          if (await File(pdfUri.replaceFirst('file://', '')).exists()) {
            final inputFile = File(pdfUri.replaceFirst('file://', ''));
            await inputFile.copy(file.path);
            _savedFilePath = file.path;
            print('PDF saved to: ${file.path}');

            // Show options instead of just setting state
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _scannedDocuments = scannedDocuments;
            });
            _showScanResultOptions(file.path);
            return;
          }
        } catch (e) {
          print('Error copying PDF: $e');
        }
      } else if (scannedDocuments is String && scannedDocuments.isNotEmpty) {
        // Direct path or base64 string
        final filename = 'scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = await _getVakyFile(filename);

        try {
          // Check if it's a file path or base64 data
          if (scannedDocuments.startsWith('file://')) {
            // It's a URI, clean it up and copy it
            final cleanPath = scannedDocuments.replaceFirst('file://', '');
            if (await File(cleanPath).exists()) {
              await File(cleanPath).copy(file.path);
              _savedFilePath = file.path;
              print('PDF saved to: ${file.path}');

              // Show options
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _scannedDocuments = scannedDocuments;
              });
              _showScanResultOptions(file.path);
              return;
            }
          } else if (await File(scannedDocuments).exists()) {
            // It's a file path, copy it
            await File(scannedDocuments).copy(file.path);
            _savedFilePath = file.path;
            print('PDF saved to: ${file.path}');

            // Show options
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _scannedDocuments = scannedDocuments;
            });
            _showScanResultOptions(file.path);
            return;
          } else {
            // Try to decode as base64
            try {
              final bytes = base64Decode(scannedDocuments);
              await file.writeAsBytes(bytes);
              _savedFilePath = file.path;
              print('PDF saved to: ${file.path}');

              // Show options
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _scannedDocuments = scannedDocuments;
              });
              _showScanResultOptions(file.path);
              return;
            } catch (e) {
              print('Could not decode as base64: $e');
            }
          }
        } catch (e) {
          print('Error saving PDF: $e');
        }
      }
    } on PlatformException catch (e) {
      scannedDocuments = 'Failed to get scanned documents as PDF: ${e.message}';
      print(scannedDocuments);
    } catch (e) {
      scannedDocuments = 'Error: ${e.toString()}';
      print(scannedDocuments);
    }

    if (!mounted) return;
    setState(() {
      _scannedDocuments = scannedDocuments;
      _isLoading = false;
    });
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // If we have a saved file or images, show them
    if (_savedFilePath != null || (_savedImagePaths != null && _savedImagePaths!.isNotEmpty)) {
      return _buildScanResults();
    }

    // Otherwise show the main scanner interface
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Scan Your',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Documents Here...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                // Document scanning illustration
                Image.asset(
                  'assets/icons/scandoc.png', // Make sure to add this image to your assets
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
        // Bottom action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              // Camera button
              Expanded(
                child: GestureDetector(
                  onTap: scanDocument,
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Gallery button
              // Expanded(
              //   child: GestureDetector(
              //     onTap: _pickImageFromGallery,
              //     child: Container(
              //       height: 50,
              //       margin: const EdgeInsets.only(left: 8),
              //       decoration: BoxDecoration(
              //         color: Colors.blue,
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: const [
              //           Icon(Icons.image, color: Colors.white),
              //           SizedBox(width: 8),
              //           Text(
              //             'Gallery',
              //             style: TextStyle(
              //               color: Colors.white,
              //               fontSize: 16,
              //               fontWeight: FontWeight.w500,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanResults() {
    if (_savedFilePath != null) {
      // Show PDF result
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Document Saved',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 80,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'PDF Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _savedFilePath!.split('/').last,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('View'),
                    onPressed: () => _openFile(_savedFilePath!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Fill & Sign document'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfSignatureScreen(pdfPath: _savedFilePath!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Scan New Document'),
              onPressed: () {
                setState(() {
                  _savedFilePath = null;
                  _savedImagePaths = null;
                  _scannedDocuments = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      );
    } else if (_savedImagePaths != null && _savedImagePaths!.isNotEmpty) {
      // Show image results
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  _savedImagePaths!.length > 1
                      ? '${_savedImagePaths!.length} Images Saved'
                      : 'Image Saved',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _savedImagePaths!.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.file(
                            File(_savedImagePaths![index]),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Image ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.visibility, color: Colors.blue),
                                onPressed: () => _openFile(_savedImagePaths![index]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Scan New Document'),
              onPressed: () {
                setState(() {
                  _savedFilePath = null;
                  _savedImagePaths = null;
                  _scannedDocuments = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback - should not reach here
    return Center(
      child: Text('Something went wrong. Please try again.'),
    );
  }
}