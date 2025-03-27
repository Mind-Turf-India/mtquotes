import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Create_Screen/edit_screen_create.dart';

class FilesPage extends StatefulWidget {
  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isLoading = true;
  List<FileSystemEntity> _downloadedImages = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initSpeech();
    loadDownloadedImages();

    // Listen for auth state changes to reload files when user signs in/out
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        loadDownloadedImages();
      }
    });
  }

  // Get the user-specific directory path
  Future<Directory> getUserSpecificDirectory() async {
    Directory baseDir;

    // Get current user
    User? user = _auth.currentUser;
    String userDir = user != null ? _sanitizeEmail(user.email!) : 'guest';

    if (Platform.isAndroid) {
      baseDir = Directory('/storage/emulated/0/Pictures/Vaky/$userDir');
    } else {
      baseDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Vaky/$userDir');
    }

    // Create directory if it doesn't exist
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    return baseDir;
  }

  // Sanitize email for directory name (replace dots with underscores)
  String _sanitizeEmail(String email) {
    return email.replaceAll('.', '_').replaceAll('@', '_at_');
  }

  Future<void> loadDownloadedImages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check if user is logged in
      User? user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _downloadedImages = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Get user-specific directory
      Directory baseDir = await getUserSpecificDirectory();
      print('Loading images from directory: ${baseDir.path}');

      if (!await baseDir.exists()) {
        print('Directory does not exist: ${baseDir.path}');
        if (mounted) {
          setState(() {
            _downloadedImages = [];
            _isLoading = false;
          });
        }
        return;
      }

      final List<FileSystemEntity> files = await baseDir.list().toList();
      print('Found ${files.length} files in directory');

      // Filter to include only jpg, jpeg, png files
      final imageFiles = files.where((file) {
        final path = file.path.toLowerCase();
        return file is File &&
            (path.endsWith('.jpg') ||
                path.endsWith('.jpeg') ||
                path.endsWith('.png'));
      }).toList();

      print('Found ${imageFiles.length} image files');

      // Sort by modification time (newest first)
      imageFiles.sort((a, b) {
        return File(b.path).lastModifiedSync().compareTo(
            File(a.path).lastModifiedSync());
      });

      if (mounted) {
        setState(() {
          _downloadedImages = imageFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading downloaded images: $e');
      if (mounted) {
        setState(() {
          _downloadedImages = [];
          _isLoading = false;
        });
      }
    }
  }

  List<FileSystemEntity> get filteredDownloadedImages {
    if (_searchQuery.isEmpty) {
      return _downloadedImages;
    }

    return _downloadedImages.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _searchController.text = result.recognizedWords;
      _searchQuery = result.recognizedWords;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // Method to navigate to template editing
  Future<void> _navigateToTemplateSharing(File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Read the file bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Close loading indicator
      Navigator.of(context).pop();

      // Navigate to EditScreen with the selected image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            title: 'Edit Template',
            templateImageUrl: null,
            initialImageData: fileBytes,
          ),
        ),
      ).then((_) => loadDownloadedImages());
    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;
    //final isUserLoggedIn = _auth.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.loc.files,
          style: GoogleFonts.poppins(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.w600,
              color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button to reload
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              loadDownloadedImages();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                  hintText: context.loc.searchfiles,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: fontSize, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.blue : Colors.grey[600],
                    ),
                    onPressed: _toggleListening,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Downloaded Images',
              style: GoogleFonts.poppins(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _buildDownloadedImagesContent(fontSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedImagesContent(double textSize) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredDownloadedImages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No downloaded images found',
                style: GoogleFonts.poppins(
                  fontSize: textSize + 2,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredDownloadedImages.length,
      itemBuilder: (context, index) {
        final file = filteredDownloadedImages[index] as File;
        final fileName = file.path.split('/').last;

        // Get file modification date
        final DateTime modDate = file.lastModifiedSync();
        final String dateStr = "${modDate.day}/${modDate.month}/${modDate.year}";

        return InkWell(
          onTap: () {
            // Navigate to EditScreen with the selected image
            _navigateToTemplateSharing(file);
          },
          child: Padding(
            padding: EdgeInsets.only(right: 8, bottom: 8),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 3)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print("Error loading image: $error");
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // SizedBox(height: 5),
                // Text(
                //   dateStr,
                //   style: TextStyle(fontSize: 12),
                //   textAlign: TextAlign.center,
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}