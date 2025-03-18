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

class EditScreen extends StatefulWidget {
  EditScreen({Key? key, required this.title, this.templateImageUrl}) : super(key: key);
  final String title;
  final String? templateImageUrl;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Uint8List? imageData;
  final ImagePicker _picker = ImagePicker();
  bool defaultImageLoaded = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.templateImageUrl != null) {
      loadTemplateImage(widget.templateImageUrl!);
    }
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

      String filePath = "${baseDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.jpg";
      File file = File(filePath);
      await file.writeAsBytes(imageData!);

      _hideLoadingIndicator();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image saved to ${baseDir.path}")),
      );
    } catch (e) {
      _hideLoadingIndicator();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  imageData = null; // Remove the image
                  defaultImageLoaded = true; // Reset default state
                });
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
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.share, color: Colors.grey),
              onPressed: shareImage,
            ),
            TextButton(
              onPressed: downloadImage,
              child: Text("Download", style: TextStyle(color: Colors.blue)),
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