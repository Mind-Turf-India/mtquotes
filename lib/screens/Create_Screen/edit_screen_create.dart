import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:mtquotes/screens/Create_Screen/components/drafts_service.dart';
import 'package:mtquotes/screens/Create_Screen/components/imageEditDraft.dart';

import '../User_Home/files_screen.dart';

class EditScreen extends StatefulWidget {
  EditScreen({
    Key? key,
    required this.title,
    this.templateImageUrl,
    this.initialImageData,
    this.draftId,  // Add draftId parameter
  }) : super(key: key);

  final String title;
  final String? templateImageUrl;
  final Uint8List? initialImageData;
  final String? draftId;  // To track if we're editing an existing draft

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Uint8List? imageData;
  final ImagePicker _picker = ImagePicker();
  bool defaultImageLoaded = true;
  bool isLoading = false;
  final uuid = Uuid();
  final DraftService _draftService = DraftService();
  String? currentDraftId;  // Track the current draft ID
  String? originalImagePath;  // Track the original image path

  @override
  void initState() {
    super.initState();
    currentDraftId = widget.draftId;

    if (widget.draftId != null) {
      _loadDraft(widget.draftId!);
    } else if (widget.templateImageUrl != null) {
      loadTemplateImage(widget.templateImageUrl!);
    } else if (widget.initialImageData != null) {
      setState(() {
        imageData = widget.initialImageData;
        defaultImageLoaded = false;
      });
    }
  }

  // Load draft from DraftService
  Future<void> _loadDraft(String draftId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final draft = await _draftService.getDraft(draftId);
      if (draft != null) {
        // Load the edited image from the path
        final File imageFile = File(draft.editedImagePath);
        final bytes = await imageFile.readAsBytes();

        setState(() {
          imageData = bytes;
          defaultImageLoaded = false;
          originalImagePath = draft.originalImagePath;
          isLoading = false;
        });
      } else {
        throw Exception('Draft not found');
      }
    } catch (e) {
      print('Error loading draft: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading draft")),
        );
      }
    }
  }

  // Save to drafts
  Future<void> saveToDrafts({String? title}) async {
    if (imageData == null) {
      showNoImageSelectedDialog();
      return;
    }

    _showLoadingIndicator();

    try {
      // Get a temporary directory to store the edited image
      final tempDir = await getTemporaryDirectory();
      final draftImagePath = '${tempDir.path}/draft_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Save the current image to the path
      final File draftImageFile = File(draftImagePath);
      await draftImageFile.writeAsBytes(imageData!);

      // Determine original image path
      String origPath = originalImagePath ?? '';
      if (origPath.isEmpty && widget.templateImageUrl != null) {
        origPath = widget.templateImageUrl!;
      }

      // Create or update a draft
      final draftId = currentDraftId ?? uuid.v4();
      final now = DateTime.now();

      DateTime createdAt = now;
      if (currentDraftId != null) {
        final existingDraft = await _draftService.getDraft(currentDraftId!);
        if (existingDraft != null) {
          createdAt = existingDraft.createdAt;
        }
      }

      final draft = ImageEditDraft(
        id: draftId,
        originalImagePath: origPath,
        editedImagePath: draftImagePath,
        createdAt: createdAt,
        updatedAt: now,
        title: title,
      );

      await _draftService.saveDraft(draft);

      // Update current draft ID
      setState(() {
        currentDraftId = draftId;
      });

      _hideLoadingIndicator();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image saved to drafts"),
          action: SnackBarAction(
            label: 'VIEW DRAFTS',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilesPage(initialTabIndex: 1), // Go to Drafts tab
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to drafts: $e")),
      );
    }
  }

  // Show dialog to name draft
  void _showSaveToDraftsDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save to Drafts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Draft name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                saveToDrafts(title: titleController.text.isNotEmpty ? titleController.text : null);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  void showNoImageSelectedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Image Selected'),
          content: Text('Please select an image from gallery first.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to show loading indicator
  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  // Helper method to hide loading indicator
  void _hideLoadingIndicator() {
    Navigator.of(context).pop();
  }

  Future<void> loadTemplateImage(String imageUrl) async {
    setState(() {
      isLoading = true;
    });

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          imageData = response.bodyBytes;
          defaultImageLoaded = false;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error loading template image: $e');
      setState(() {
        isLoading = false;
      });

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading template image")),
        );
      }
    }
  }

  Future<void> shareImage() async {
    // Check if there's an image to share
    if (imageData == null) {
      showNoImageSelectedDialog();
      return;
    }

    _showLoadingIndicator();

    try {
      // Save the edited image to a temporary file
      final temp = await getTemporaryDirectory();
      final path = "${temp.path}/edited_image.jpg";
      File(path).writeAsBytesSync(imageData!);

      _hideLoadingIndicator();

      // Share the image
      await Share.shareXFiles(
        [XFile(path)],
        text: 'here the url of the app will come along with the referral code deets',
      );
    } catch (e) {
      _hideLoadingIndicator();

      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to share image: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> downloadImage() async {
    if (imageData == null) {
      showNoImageSelectedDialog();
      return;
    }

    _showLoadingIndicator();

    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0/Pictures/Vaky');
      } else {
        baseDir = Directory('${(await getApplicationDocumentsDirectory()).path}/Vaky');
      }

      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true); // Create the folder if it doesn't exist
      }

      // Use a more descriptive filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filePath = "${baseDir.path}/edited_image_$timestamp.jpg";
      File file = File(filePath);
      await file.writeAsBytes(imageData!);

      _hideLoadingIndicator();

      // Show a more informative message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image saved to downloads"),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () {
              // Navigate to FilesPage with Downloads tab selected
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
    } catch (e) {
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    _showLoadingIndicator();

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      _hideLoadingIndicator();

      if (image != null) {
        // Show loading indicator for file reading
        _showLoadingIndicator();

        try {
          final File file = File(image.path);
          final Uint8List bytes = await file.readAsBytes();

          // Store the original image path
          originalImagePath = image.path;

          _hideLoadingIndicator();

          setState(() {
            imageData = bytes;
            defaultImageLoaded = false;
          });
        } catch (e) {
          _hideLoadingIndicator();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error reading image: $e")),
          );
        }
      }
    } catch (e) {
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // Other existing methods...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                if (imageData != null && !defaultImageLoaded) {
                  // Show save to drafts dialog when canceling with changes
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Discard Changes?'),
                        content: Text('Do you want to save your changes to drafts before leaving?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(); // Exit screen
                            },
                            child: Text('Discard'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showSaveToDraftsDialog();
                            },
                            child: Text('Save to Drafts'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(color: Colors.grey),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.save_outlined, color: Colors.blue),
              onPressed: _showSaveToDraftsDialog,
              tooltip: 'Save to Drafts',
            ),

            IconButton(
              icon: Icon(Icons.share, color: Colors.blue),
              onPressed: shareImage,
            ),
            TextButton(
              onPressed: downloadImage,
              child: Text("Download", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isLoading)
                Container(
                  height: 400,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                imageData == null
                    ? GestureDetector(
                  onTap: pickImageFromGallery,
                  child: Container(
                    height: 400,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade400,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tap to upload from gallery',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Image.memory(imageData!),
              SizedBox(height: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (imageData == null) {
                        showNoImageSelectedDialog();
                      } else {
                        _showLoadingIndicator();

                        try {
                          var editedImage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageEditor(image: imageData),
                            ),
                          );

                          _hideLoadingIndicator();

                          if (editedImage != null) {
                            setState(() {
                              imageData = editedImage;
                            });
                          }
                        } catch (e) {
                          _hideLoadingIndicator();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error editing image: $e")),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Image'),
                    style: ElevatedButton.styleFrom(
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}