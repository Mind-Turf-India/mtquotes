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

  Future<void> scanDocumentUri() async {
    setState(() {
      _isLoading = true;
      _savedFilePath = null;
      _savedImagePaths = null;
    });

    // This feature is only supported for Android
    dynamic scannedDocuments;
    try {
      scannedDocuments =
          await FlutterDocScanner().getScanDocumentsUri(page: 4) ??
              'Unknown platform documents';

      print('Raw scan result URI: $scannedDocuments');

      // If we got a URI, save a copy to our vaky folder
      if (scannedDocuments is String && scannedDocuments.isNotEmpty) {
        final filename = 'scanned_document_uri_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = await _getVakyFile(filename);

        try {
          // Handle file:// prefix if present
          String filePath = scannedDocuments;
          if (filePath.startsWith('file://')) {
            filePath = filePath.replaceFirst('file://', '');
          }

          if (await File(filePath).exists()) {
            await File(filePath).copy(file.path);
            _savedFilePath = file.path;
            print('URI document saved to: ${file.path}');
            
            // Show options
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _scannedDocuments = scannedDocuments;
            });
            _showScanResultOptions(file.path);
            return;
          }
        } catch (e) {
          print('Error saving URI document: $e');
        }
      }
    } on PlatformException catch (e) {
      scannedDocuments = 'Failed to get scanned documents URI: ${e.message}';
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
      appBar: AppBar(
        title: const Text('Document Scanner'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                )
              else if (_savedFilePath != null)
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Document Saved:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _savedFilePath!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _openFile(_savedFilePath!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Open Document'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfSignatureScreen(pdfPath: _savedFilePath!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Fill & Sign'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (_savedImagePaths != null && _savedImagePaths!.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Images Saved:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _savedImagePaths!.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Text(
                                  'Image ${index + 1}:',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Image.file(
                                  File(_savedImagePaths![index]),
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _savedImagePaths![index],
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _openFile(_savedImagePaths![index]),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Open Image'),
                                ),
                                const Divider(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else if (_scannedDocuments != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'Scan Result:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _scannedDocuments.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  "No Documents Scanned",
                  style: TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 20),
              const Text(
                'Select a scanning option:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildScanButton(
                "Scan Documents",
                scanDocument,
                Colors.blue,
              ),
              const SizedBox(height: 10),
              _buildScanButton(
                "Scan Documents As PDF",
                scanDocumentAsPdf,
                Colors.orange,
              ),
              const SizedBox(height: 10),
              _buildScanButton(
                "Get Scan Documents URI (Android Only)",
                scanDocumentUri,
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(String title, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}