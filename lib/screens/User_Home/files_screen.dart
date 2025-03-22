import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:mtquotes/screens/Create_Screen/components/imageEditDraft.dart';
import 'package:mtquotes/screens/Create_Screen/components/drafts_service.dart';
import '../Create_Screen/edit_screen_create.dart';

class FilesPage extends StatefulWidget {
  final int initialTabIndex;

  FilesPage({this.initialTabIndex = 0});

  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  int selectedTab = 0;
  final List<String> tabs = ["Download", "Drafts"];
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isLoading = true;
  List<FileSystemEntity> _downloadedImages = [];
  List<ImageEditDraft> _drafts = [];
  String _searchQuery = '';
  final DraftService _draftService = DraftService();

  @override
  void initState() {
    super.initState();
    initSpeech();
    // Set the selected tab based on initialTabIndex
    selectedTab = widget.initialTabIndex;
    loadDownloadedImages();
    loadDrafts();
  }

  Future<void> loadDownloadedImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Directory? baseDir;

      if (Platform.isAndroid) {
        baseDir = Directory('/storage/emulated/0/Pictures/Vaky');
      } else {
        baseDir = Directory(
            '${(await getApplicationDocumentsDirectory()).path}/Vaky');
      }

      // Create directory if it doesn't exist
      if (!await baseDir.exists()) {
        await baseDir.create(recursive: true);
      }

      final List<FileSystemEntity> files = await baseDir.list().toList();
      // Filter to include only jpg, jpeg, png files
      final imageFiles = files.where((file) {
        final path = file.path.toLowerCase();
        return file is File &&
            (path.endsWith('.jpg') ||
                path.endsWith('.jpeg') ||
                path.endsWith('.png'));
      }).toList();

      setState(() {
        _downloadedImages = imageFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading downloaded images: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loadDrafts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drafts = await _draftService.getAllDrafts();
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading drafts: $e');
      setState(() {
        _isLoading = false;
      });
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

  List<ImageEditDraft> get filteredDrafts {
    if (_searchQuery.isEmpty) {
      return _drafts;
    }

    return _drafts.where((draft) {
      final draftTitle = (draft.title ?? 'Untitled Draft').toLowerCase();
      return draftTitle.contains(_searchQuery.toLowerCase());
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
            // Pass null for templateImageUrl since we're directly providing the image data
            templateImageUrl: null,
            // Pass the image bytes as a parameter
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

  // Method to navigate to draft editing
  Future<void> _navigateToDraftEditing(ImageEditDraft draft) async {
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
      final File editedFile = File(draft.editedImagePath);
      final Uint8List fileBytes = await editedFile.readAsBytes();

      // Close loading indicator
      Navigator.of(context).pop();

      // Navigate to EditScreen with the draft
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(
            title: draft.title ?? 'Edit Draft',
            initialImageData: fileBytes,
            draftId: draft.id,
          ),
        ),
      ).then((_) => loadDrafts());
    } catch (e) {
      // Close loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening draft: $e")),
      );
    }
  }

  Future<void> _deleteDraft(String draftId) async {
    try {
      await _draftService.deleteDraft(draftId);
      loadDrafts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Draft deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting draft: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;

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
              loadDrafts();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(tabs.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      tabs[index],
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        color: selectedTab == index
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                    selected: selectedTab == index,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blueAccent),
                    showCheckmark: false,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                  ),
                );
              }),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: _buildTabContent(selectedTab, fontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int index, double textSize) {
    if (index == 0) {
      // Downloads tab
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
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredDownloadedImages.length,
        itemBuilder: (context, index) {
          final file = filteredDownloadedImages[index] as File;
          final fileName = file.path.split('/').last;

          return InkWell(
            onTap: () {
              // Navigate to EditScreen with the selected image
              _navigateToTemplateSharing(file);
            },
            child: Padding(
              padding: EdgeInsets.only(right: 8, bottom: 8),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Drafts tab
      if (_isLoading) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (filteredDrafts.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_document, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No drafts available',
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

      return ListView.builder(
        padding: EdgeInsets.all(10),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredDrafts.length,
        itemBuilder: (context, index) {
          final draft = filteredDrafts[index];
          final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
          final lastEditedDate = dateFormat.format(draft.updatedAt);

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              onTap: () => _navigateToDraftEditing(draft),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Draft thumbnail
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List>(
                          future: File(draft.editedImagePath).readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Center(
                                child: snapshot.hasError
                                    ? Icon(Icons.error, color: Colors.red)
                                    : CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Draft info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.title ?? 'Untitled Draft',
                            style: GoogleFonts.poppins(
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Last edited: $lastEditedDate',
                            style: GoogleFonts.poppins(
                              fontSize: textSize - 2,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Options
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _navigateToDraftEditing(draft);
                        } else if (value == 'delete') {
                          // Show confirmation dialog
                          final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Draft'),
                                  content: Text(
                                      'Are you sure you want to delete this draft?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (shouldDelete) {
                            _deleteDraft(draft.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
