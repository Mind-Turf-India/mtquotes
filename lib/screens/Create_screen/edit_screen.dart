import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditScreen extends StatefulWidget {
  EditScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Uint8List? imageData;
  final ImagePicker _picker = ImagePicker();
  bool defaultImageLoaded = true;

  @override
  void initState() {
    // We'll not load the default asset immediately to show the upload UI first
    super.initState();
  }

  void loadAsset(String name) async {
    var data = await rootBundle.load('assets/$name');
    setState(() {
      imageData = data.buffer.asUint8List();
    });
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File file = File(image.path);
      final Uint8List bytes = await file.readAsBytes();

      setState(() {
        imageData = bytes;
        defaultImageLoaded = false;
      });
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
        title: Text('Image editor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            imageData == null
                ? GestureDetector(
              onTap: pickImageFromGallery,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
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
                        color: Colors.grey.shade200,
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
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: pickImageFromGallery,
                  icon: Icon(Icons.photo_library),
                  label: Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (imageData == null) {
                      showNoImageSelectedDialog();
                    } else {
                      var editedImage = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageEditor(image: imageData),
                        ),
                      );
                      if (editedImage != null) {
                        setState(() {
                          imageData = editedImage;
                        });
                      }
                    }
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Edit Image'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}