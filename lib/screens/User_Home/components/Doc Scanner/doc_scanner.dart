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
import '../../../../utils/app_colors.dart';

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
    // Request camera and storage permissions with native dialogs
    final statuses = await [
      Permission.storage,
      Permission.camera,
      if (Platform.isAndroid) Permission.manageExternalStorage, // Optional for Android 11+
    ].request();

    // Check if any permission is denied
    if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions are required to use the document scanner'),
        ),
      );
      // Optionally open settings for permanently denied
      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        openAppSettings();
      }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurfaceColor(isDarkMode),
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
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.download, color: AppColors.primaryBlue),
                title: Text(
                  'Download PDF',
                  style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show the downloaded file path
                  setState(() {
                    _savedFilePath = filePath;
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primaryGreen),
                title: Text(
                  'Fill & Sign PDF',
                  style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
        title: Text(
          'Document Scanner',
          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: AppColors.getIconColor(isDarkMode)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _buildContent(isDarkMode),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    // If we have a saved file or images, show them
    if (_savedFilePath != null || (_savedImagePaths != null && _savedImagePaths!.isNotEmpty)) {
      return _buildScanResults(isDarkMode);
    }

    // Otherwise show the main scanner interface
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scan Your',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                Text(
                  'Documents Here...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 40),
                // Document scanning illustration - Consider having light/dark versions
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? Colors.white.withOpacity(0.8) : Colors.transparent,
                    isDarkMode ? BlendMode.srcATop : BlendMode.dst,
                  ),
                  child: Image.asset(
                    'assets/icons/scandoc.png',
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
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
                      border: Border.all(color: isDarkMode ? AppColors.darkDivider : AppColors.lightDivider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.getIconColor(isDarkMode)),
                        SizedBox(width: 8),
                        Text(
                          'Camera',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanResults(bool isDarkMode) {
    if (_savedFilePath != null) {
      // Show PDF result
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _savedFilePath!.split('/').last,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(isDarkMode),
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
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Fill & Sign'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfSignatureScreen(pdfPath: _savedFilePath!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
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
                  backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.grey[300],
                  foregroundColor: AppColors.getTextColor(isDarkMode),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
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
                Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  _savedImagePaths!.length > 1
                      ? '${_savedImagePaths!.length} Images Saved'
                      : 'Image Saved',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDarkMode),
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
                    color: AppColors.getSurfaceColor(isDarkMode),
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
                                    color: AppColors.getTextColor(isDarkMode),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.visibility, color: AppColors.primaryBlue),
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
                backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.grey[300],
                foregroundColor: AppColors.getTextColor(isDarkMode),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback - should not reach here
    return Center(
      child: Text(
        'Something went wrong. Please try again.',
        style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
      ),
    );
  }
}