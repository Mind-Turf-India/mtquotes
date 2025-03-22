import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:mtquotes/screens/Create_Screen/components/drafts_service.dart';
import 'package:mtquotes/screens/Create_Screen/components/imageEditDraft.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageEditorWithDrafts extends StatefulWidget {
  final String? imagePath;
  final String? draftId;

  const ImageEditorWithDrafts({Key? key, this.imagePath, this.draftId}) : super(key: key);

  @override
  _ImageEditorWithDraftsState createState() => _ImageEditorWithDraftsState();
}

class _ImageEditorWithDraftsState extends State<ImageEditorWithDrafts> {
  final DraftService _draftService = DraftService();
  late File _imageFile;
  bool _isLoading = true;
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.draftId != null) {
      await _loadDraft(widget.draftId!);
    } else if (widget.imagePath != null) {
      _imageFile = File(widget.imagePath!);
    } else {
      // Handle the case where neither draft nor image is provided
      throw Exception('Either draftId or imagePath must be provided');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDraft(String draftId) async {
    final draft = await _draftService.getDraft(draftId);
    _imageFile = File(draft!.editedImagePath);
  }

  Future<void> _saveDraft() async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final savedImagePath = '${tempDir.path}/${uuid.v4()}.jpg';

    // Save the current state of the image
    await _imageFile.copy(savedImagePath);

    String originalPath = widget.imagePath ?? '';
    String draftId = widget.draftId ?? uuid.v4();

    if (widget.draftId != null) {
      final existingDraft = await _draftService.getDraft(widget.draftId!);
      originalPath = existingDraft!.originalImagePath;
    }

    final draft = ImageEditDraft(
      id: draftId,
      originalImagePath: originalPath,
      editedImagePath: savedImagePath,
      createdAt: widget.draftId != null
          ? (await _draftService.getDraft(widget.draftId!))!.createdAt
          : now,
      updatedAt: now,
    );

    await _draftService.saveDraft(draft);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: _saveDraft,
            tooltip: 'Save as Draft',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openEditor(),
              child: Center(
                child: Image.file(_imageFile),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _openEditor,
                  child: Text('Edit'),
                ),
                ElevatedButton(
                  onPressed: _saveDraft,
                  child: Text('Save Draft'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Code to post or share the final image
                  },
                  child: Text('Post'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor() async {
    final editedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: _imageFile.readAsBytesSync(),
        ),
      ),
    );

    if (editedImage != null) {
      // Save edited image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${uuid.v4()}.jpg');
      await tempFile.writeAsBytes(editedImage);

      setState(() {
        _imageFile = tempFile;
      });
    }
  }
}