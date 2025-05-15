import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:css_filter/css_filter.dart'; // Import the CSS Filter package
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_svg/svg.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img; // Add this package to your pubspec.yaml

class EditScreen extends StatefulWidget {
  final File imageFile;
  final String? templateImageUrl; // Add this to track where the image came from
  final String? name;
  final String? mobile;
  final String? location;
  final String? description;
  final String? companyName;
  final String? socialMedia;
  final File? profileImageFile;
  final String? profileImageUrl;
  final bool showInfoBox;
  final String infoBoxBackground;
  final bool isPersonal;
  final bool isPaidUser;

  const EditScreen({
    Key? key,
    required this.imageFile,
    this.templateImageUrl,
    this.name,
    this.mobile,
    this.location,
    this.description,
    this.companyName,
    this.socialMedia,
    this.profileImageFile,
    this.profileImageUrl,
    this.showInfoBox = true,
    this.infoBoxBackground = 'white',
    this.isPersonal = true,
    this.isPaidUser = true,
  }) : super(key: key);

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late PainterController _painterController;
  late quill.QuillController _quillController;

  // Image data
  ui.Image? _image;
  Uint8List? _imageBytes;
  Uint8List? _originalImageBytes; // Store original for reset functionality
  Size? _imageSize;
  bool _imageLoaded = false;

  // Transformation tracking
  bool _isImageFlippedHorizontally = false;
  bool _isImageFlippedVertically = false;
  int _rotationDegrees = 0;

  // Tab controller for different editing modes
  late TabController _tabController;

  // Current editing mode
  EditingMode _currentMode = EditingMode.filter;

  // Filter values using CSS Filter parameters
  double _brightnessValue = 1.0; // 1.0 is normal
  double _contrastValue = 1.0; // 1.0 is normal
  double _saturationValue = 1.0; // 1.0 is normal
  double _sepiaValue = 0.0; // 0.0 to 1.0
  double _hueRotateValue = 0.0; // 0.0 to 360.0
  double _invertValue = 0.0; // 0.0 to 1.0
  double _opacityValue = 1.0; // 1.0 is fully opaque
  double _blurValue = 0.0; // 0.0 is no blur

  // Selected filter preset
  String _selectedPreset = 'None';

  // GlobalKey for capturing filtered image
  final GlobalKey _filterPreviewKey = GlobalKey();

  // Create a custom key for quill editor
  final _quillEditorKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize painter controller
    _painterController = PainterController();

    // Set up painter settings
    _painterController.freeStyleSettings = const FreeStyleSettings(
      color: Colors.red,
      strokeWidth: 5,
      mode: FreeStyleMode.draw,
    );

    // Use concrete shape factories instead of the abstract ShapeFactory
    _painterController.shapeSettings = ShapeSettings(
      paint: Paint()
        ..color = Colors.blue
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke,
      factory: LineFactory(), // Use LineFactory as the default
    );

    // Initialize quill controller
    _quillController = quill.QuillController.basic();

    // Load the selected image
    _loadImageFromFile(widget.imageFile);
  }

  Future<void> _loadImageFromFile(File file) async {
    try {
      // Read file as bytes
      final bytes = await file.readAsBytes();

      // Keep original for reset
      _originalImageBytes = Uint8List.fromList(bytes);

      // Decode image
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      setState(() {
        _image = image;
        _imageBytes = bytes;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _imageLoaded = true;
      });

      // Set the image as background for painter
      _painterController.background = image.backgroundDrawable;
    } catch (e) {
      print('Error loading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }
  }

  void _handleTabChange() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentMode = EditingMode.filter;
          break;
        case 1:
          _currentMode = EditingMode.draw;
          break;
        case 2:
          _currentMode = EditingMode.text;
          break;
        case 3:
          _currentMode = EditingMode.crop;
          break;
      }
    });
  }



  Widget _buildInfoBox({
    required bool isDarkMode,
    required double fontSize
  }) {
    final textColor = Colors.black; // Info box text is always black

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // Profile image or logo
          _buildProfileImage(50),
          SizedBox(width: 12),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isPersonal)
                  Text(
                    widget.name?.isNotEmpty == true
                        ? widget.name!
                        : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: textColor,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company name first for business cards
                      Text(
                        widget.companyName?.isNotEmpty == true
                            ? widget.companyName!
                            : 'Company Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      // Then person's name
                      Text(
                        widget.name?.isNotEmpty == true
                            ? widget.name!
                            : 'Your Name',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                if (widget.location?.isNotEmpty == true)
                  Text(
                    widget.location!,
                    style: TextStyle(fontSize: fontSize - 2, color: textColor),
                  ),
                if (widget.mobile?.isNotEmpty == true)
                  Text(
                    widget.mobile!,
                    style: TextStyle(fontSize: fontSize - 2, color: textColor),
                  ),
                // Only show social media and description in business profile
                if (!widget.isPersonal) ...[
                  if (widget.socialMedia?.isNotEmpty == true)
                    Text(
                      widget.socialMedia!,
                      style: TextStyle(
                          fontSize: fontSize - 2,
                          color: Colors.blue),
                    ),
                  if (widget.description?.isNotEmpty == true)
                    Text(
                      widget.description!,
                      style: TextStyle(fontSize: fontSize - 2, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get background color
  Color _getBackgroundColor() {
    switch (widget.infoBoxBackground) {
      case 'lightGray':
        return Colors.grey[200]!;
      case 'lightBlue':
        return Colors.blue[100]!;
      case 'lightGreen':
        return Colors.green[100]!;
      case 'white':
      default:
        return Colors.white;
    }
  }

  Widget _buildProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey),
        image: widget.profileImageFile != null
            ? DecorationImage(
          image: FileImage(widget.profileImageFile!),
          fit: BoxFit.cover,
        )
            : widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(widget.profileImageUrl!),
          fit: BoxFit.cover,
        )
            : null,
        color: Colors.grey[200],
      ),
      child: (widget.profileImageFile == null &&
          (widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty))
          ? Icon(
        Icons.person,
        color: Colors.grey[400],
        size: size / 2,
      )
          : null,
    );
  }

  // Capture the current filtered image
  Future<Uint8List?> _captureFilteredImage() async {
    try {
      final RenderRepaintBoundary boundary = _filterPreviewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
      return null;
    } catch (e) {
      print('Error capturing filtered image: $e');
      return null;
    }
  }

  CSSFilterMatrix _getCurrentFilterMatrix() {
    return CSSFilterMatrix()
        .brightness(_brightnessValue)
        .contrast(_contrastValue)
        .saturate(_saturationValue)
        .sepia(_sepiaValue)
        .hueRotate(_hueRotateValue)
        .invert(_invertValue)
        .opacity(_opacityValue)
        .blur(_blurValue);
  }

  // Apply preset filter
  Widget _applyPresetFilter(Widget child) {
    switch (_selectedPreset) {
      case 'None':
        return child;
      case '1977':
        return CSSFilterPresets.ins1977(child: child);
      case 'Aden':
        return CSSFilterPresets.insAden(child: child);
      case 'Amaro':
        return CSSFilterPresets.insAmaro(child: child);
      case 'Brannan':
        return CSSFilterPresets.insBrannan(child: child);
      case 'Clarendon':
        return CSSFilterPresets.insClarendon(child: child);
      case 'Gingham':
        return CSSFilterPresets.insGingham(child: child);
      case 'Hudson':
        return CSSFilterPresets.insHudson(child: child);
      case 'Inkwell':
        return CSSFilterPresets.insInkwell(child: child);
      case 'Lark':
        return CSSFilterPresets.insLark(child: child);
      case 'Lofi':
        return CSSFilterPresets.insLofi(child: child);
      case 'Nashville':
        return CSSFilterPresets.insNashville(child: child);
      case 'Rise':
        return CSSFilterPresets.insRise(child: child);
      case 'Toaster':
        return CSSFilterPresets.insToaster(child: child);
      case 'Willow':
        return CSSFilterPresets.insWillow(child: child);
      case 'Xpro2':
        return CSSFilterPresets.insXpro2(child: child);
      default:
      // Custom filter using sliders
        return CSSFilter.apply(
          child: child,
          value: _getCurrentFilterMatrix(),
        );
    }
  }

  Future<void> _exportImage() async {
    if (!_imageLoaded || _image == null) return;

    try {
      // Show loading indicator
      _showLoadingDialog();

      Uint8List? finalImageBytes;

      if (_currentMode == EditingMode.filter) {
        // For filter mode, capture the filtered image from the UI
        finalImageBytes = await _captureFilteredImage();

        if (finalImageBytes == null) {
          throw Exception('Failed to capture filtered image');
        }
      } else {
        // For other modes, render using painter controller
        final size = _imageSize!;
        final painterImage = await _painterController.renderImage(size);
        finalImageBytes = await painterImage.pngBytes;
      }

      if (finalImageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/edited_image.png');
        await file.writeAsBytes(finalImageBytes);

        // Hide loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Share the image
        await Share.shareXFiles([XFile(file.path)], text: 'Edited image');
      } else {
        throw Exception('Failed to get image data');
      }
    } catch (e) {
      print('Error exporting image: $e');

      // Hide loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting image: $e')),
        );
      }
    }
  }

  // Show loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _saveImage() async {
    if (!_imageLoaded || _image == null) return;

    try {
      // Show loading indicator
      _showLoadingDialog();

      Uint8List? finalImageBytes;

      if (_currentMode == EditingMode.filter) {
        // For filter mode, capture the filtered image from the UI
        finalImageBytes = await _captureFilteredImage();

        if (finalImageBytes == null) {
          throw Exception('Failed to capture filtered image');
        }
      } else {
        // For other modes, render using painter controller
        final size = _imageSize!;
        final painterImage = await _painterController.renderImage(size);
        finalImageBytes = await painterImage.pngBytes;
      }

      if (finalImageBytes != null) {
        // Create a temporary file for both gallery saving and returning
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/edited_image.png');
        await file.writeAsBytes(finalImageBytes);

        // Request permissions before saving to gallery
        bool hasPermission = false;

        if (Platform.isAndroid) {
          // Request different permissions based on Android SDK version
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkVersion = androidInfo.version.sdkInt;

          if (sdkVersion >= 33) {
            // Android 13+
            hasPermission = await Permission.photos.isGranted;
            if (!hasPermission) {
              final status = await Permission.photos.request();
              hasPermission = status.isGranted;
            }
          } else {
            // Android 10-12 and below
            hasPermission = await Permission.storage.isGranted;
            if (!hasPermission) {
              hasPermission = (await Permission.storage.request()).isGranted;
            }
          }
        } else if (Platform.isIOS) {
          // iOS typically doesn't need explicit permission for saving to gallery
          hasPermission = true;
        }

        if (!hasPermission) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading dialog
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                  Text("Storage permission is required to save images")),
            );
          }
          return;
        }

        // Generate a unique filename based on timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "Edited_${timestamp}.png";

        // Save to gallery using ImageGallerySaverPlus
        final result = await ImageGallerySaverPlus.saveImage(
          finalImageBytes,
          quality: 100,
          name: fileName,
        );

        // Check if save was successful
        bool isGallerySaveSuccess = false;
        if (result is Map) {
          isGallerySaveSuccess = result['isSuccess'] ?? false;
        } else {
          isGallerySaveSuccess = result != null;
        }

        // Hide loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (isGallerySaveSuccess) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Image saved to gallery successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save image to gallery')),
            );
          }
        }

        // Return to previous screen with the edited image
        if (mounted) {
          Navigator.pop(context, file); // Return the file to previous screen
        }
      }
    } catch (e) {
      print('Error saving image: $e');

      // Hide loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSize = 14.0; // or get from your text size provider

    return WillPopScope(
      onWillPop: () async {
        _cleanupQuillResources();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Image'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              // Clean up before navigating back
              _cleanupQuillResources();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _saveImage,
              tooltip: 'Download',
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/share.svg',
                height: 24,
                width: 24,
              ),
              onPressed: _exportImage,
              tooltip: 'Share',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.filter), text: 'Filters'),
              Tab(icon: Icon(Icons.brush), text: 'Draw'),
              Tab(icon: Icon(Icons.text_fields), text: 'Text'),
              Tab(icon: Icon(Icons.crop), text: 'Adjust'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Image preview area
            Expanded(
              flex: 3,
              child: _buildImagePreview(),
            ),
            if (widget.showInfoBox)
              _buildInfoBox(isDarkMode: isDarkMode, fontSize: fontSize),

            // Editing controls
            Expanded(
              flex: 1,
              child: _buildControlsForCurrentMode(),
            ),

          ],
        ),
      ),
    );
  }

  // Helper method to clean up Quill resources
  void _cleanupQuillResources() {
    try {
      // Dispose of any Quill resources if needed
      _quillController.dispose();

      // Create a fresh controller for next time
      _quillController = quill.QuillController.basic();
    } catch (e) {
      print('Error cleaning up Quill resources: $e');
    }
  }

  Widget _buildImagePreview() {
    if (!_imageLoaded || _image == null || _imageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentMode) {
      case EditingMode.filter:
      // For filter mode, use CSS Filter with RepaintBoundary for capturing
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: RepaintBoundary(
            key: _filterPreviewKey,
            child: _selectedPreset == 'None' && _areDefaultFilterValues()
                ? Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,
            )
                : _applyPresetFilter(
              Image.memory(
                _imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      case EditingMode.draw:
      case EditingMode.text:
      case EditingMode.crop:
      // For drawing, text, and crop modes, use FlutterPainter
        return ClipRect(
          child: FlutterPainter(
            controller: _painterController,
            onDrawableCreated: (drawable) {
              // Drawable created callback
            },
            onSelectedObjectDrawableChanged: (selectedDrawable) {
              // Selected drawable changed callback
            },
          ),
        );
    }
  }

  // Check if all filter values are at their defaults
  bool _areDefaultFilterValues() {
    return _brightnessValue == 1.0 &&
        _contrastValue == 1.0 &&
        _saturationValue == 1.0 &&
        _sepiaValue == 0.0 &&
        _hueRotateValue == 0.0 &&
        _invertValue == 0.0 &&
        _opacityValue == 1.0 &&
        _blurValue == 0.0;
  }

  Widget _buildControlsForCurrentMode() {
    switch (_currentMode) {
      case EditingMode.filter:
        return _buildFilterControls();
      case EditingMode.draw:
        return _buildDrawControls();
      case EditingMode.text:
        return _buildTextControls();
      case EditingMode.crop:
        return _buildCropControls();
    }
  }

  Widget _buildFilterControls() {
    // First, show preset filters in a horizontal scrollable list
    return Column(
      children: [
        // Preset filters
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPresetFilterOption('None'),
              _buildPresetFilterOption('1977'),
              _buildPresetFilterOption('Aden'),
              _buildPresetFilterOption('Amaro'),
              _buildPresetFilterOption('Brannan'),
              _buildPresetFilterOption('Clarendon'),
              _buildPresetFilterOption('Gingham'),
              _buildPresetFilterOption('Hudson'),
              _buildPresetFilterOption('Inkwell'),
              _buildPresetFilterOption('Lark'),
              _buildPresetFilterOption('Lofi'),
              _buildPresetFilterOption('Nashville'),
              _buildPresetFilterOption('Rise'),
              _buildPresetFilterOption('Toaster'),
              _buildPresetFilterOption('Willow'),
              _buildPresetFilterOption('Xpro2'),
            ],
          ),
        ),

        // Manual filter controls
        Expanded(
          child: _selectedPreset == 'None'
              ? Center(
    child: Text(
    'No Presets applied.'),)
              : Center(
            child: Text(
                'Preset filter applied. Select "None" to use manual controls.'),
          ),
        ),
      ],
    );
  }


  Widget _buildPresetFilterOption(String presetName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ChoiceChip(
        label: Text(presetName),
        selected: _selectedPreset == presetName,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedPreset = presetName;

              // Reset manual filter values when selecting a preset
              if (presetName != 'None') {
                // _brightnessValue = 1.0;
                // _contrastValue = 1.0;
                // _saturationValue = 1.0;
                // _sepiaValue = 0.0;
                // _hueRotateValue = 0.0;
                // _invertValue = 0.0;
                // _opacityValue = 1.0;
                // _blurValue = 0.0;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildDrawControls() {
    final freeStyleSettings = _painterController.freeStyleSettings;
    final shapeSettings = _painterController.shapeSettings;

    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        // Color picker
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: freeStyleSettings.color ?? Colors.red,
            child: IconButton(
              icon: const Icon(Icons.color_lens, color: Colors.white),
              onPressed: () {
                // Show color picker
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Pick a color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: freeStyleSettings.color ?? Colors.red,
                        onColorChanged: (color) {
                          setState(() {
                            _painterController.freeStyleSettings =
                                freeStyleSettings.copyWith(
                                  color: color,
                                );

                            // Also update shape color
                            final paint = shapeSettings.paint!.copyWith()
                              ..color = color;
                            _painterController.shapeSettings =
                                shapeSettings.copyWith(
                                  paint: paint,
                                );
                          });
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Controls column with width and mode
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Width label and slider
              const Text('Width'),
              SizedBox(
                width: 200, // Adjust width as needed
                child: Slider(
                  value: freeStyleSettings.strokeWidth,
                  min: 1,
                  max: 20,
                  onChanged: (value) {
                    setState(() {
                      _painterController.freeStyleSettings =
                          freeStyleSettings.copyWith(
                            strokeWidth: value,
                          );

                      // Also update shape stroke width
                      final paint = shapeSettings.paint!.copyWith()
                        ..strokeWidth = value;
                      _painterController.shapeSettings = shapeSettings.copyWith(
                        paint: paint,
                      );
                    });
                  },
                ),
              ),

              // Small space between slider and modes
              const SizedBox(height: 8),

              // Modes label
              const Text('Mode'),

              // Drawing mode row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.rectangle_outlined),
                    color: _painterController.shapeSettings.factory
                    is RectangleFactory
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: () {
                      setState(() {
                        _painterController.freeStyleSettings =
                            freeStyleSettings.copyWith(
                              mode: FreeStyleMode.none,
                            );
                        _painterController.shapeSettings =
                            shapeSettings.copyWith(
                              factory: RectangleFactory(),
                            );
                      });
                    },
                    tooltip: 'Rectangle',
                  ),
                  IconButton(
                    icon: const Icon(Icons.circle_outlined),
                    color:
                    _painterController.shapeSettings.factory is OvalFactory
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: () {
                      setState(() {
                        _painterController.freeStyleSettings =
                            freeStyleSettings.copyWith(
                              mode: FreeStyleMode.none,
                            );
                        _painterController.shapeSettings =
                            shapeSettings.copyWith(
                              factory: OvalFactory(),
                            );
                      });
                    },
                    tooltip: 'Oval',
                  ),
                  IconButton(
                    icon: const Icon(Icons.brush),
                    color: freeStyleSettings.mode == FreeStyleMode.draw
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: () {
                      setState(() {
                        _painterController.freeStyleSettings =
                            freeStyleSettings.copyWith(
                              mode: FreeStyleMode.draw,
                            );
                      });
                    },
                    tooltip: 'Free Draw',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    color:
                    _painterController.shapeSettings.factory is ArrowFactory
                        ? Colors.blue
                        : Colors.grey,
                    onPressed: () {
                      setState(() {
                        _painterController.freeStyleSettings =
                            freeStyleSettings.copyWith(
                              mode: FreeStyleMode.none,
                            );
                        _painterController.shapeSettings =
                            shapeSettings.copyWith(
                              factory: ArrowFactory(),
                            );
                      });
                    },
                    tooltip: 'Arrow',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Eraser
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24), // Align with other controls
              IconButton(
                icon: const Icon(Icons.auto_fix_normal),
                iconSize: 28,
                color: freeStyleSettings.mode == FreeStyleMode.erase
                    ? Colors.red
                    : Colors.grey,
                onPressed: () {
                  setState(() {
                    _painterController.freeStyleSettings =
                        freeStyleSettings.copyWith(
                          mode: FreeStyleMode.erase,
                        );
                  });
                },
                tooltip: 'Eraser',
              ),
              const Text('Eraser', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
      Expanded(
      child: Center(
      child: Text(
        'Advanced text editing available',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    ),

    // Button to launch the text editor
    ElevatedButton.icon(
    onPressed: () async {
    // If we don't have an image, we can't add text
    if (_image == null || _imageBytes == null) return;

    try {
    // Show loading indicator
    _showLoadingDialog();

    Uint8List? imageToEdit;

    if (_currentMode == EditingMode.filter &&
        (_selectedPreset != 'None' || !_areDefaultFilterValues())) {
      // For filter mode with active filters, capture the filtered image
      imageToEdit = await _captureFilteredImage();
      if (imageToEdit == null) {
        throw Exception(
            'Failed to capture filtered image for text editing');
      }
    } else {
      // For other modes or no filter applied, use the current image
      final size = _imageSize!;
      final renderedImage =
      await _painterController.renderImage(size);
      imageToEdit = await renderedImage.pngBytes;

      if (imageToEdit == null) {
        throw Exception('Failed to get image data for text editor');
      }
    }

    // Close the loading dialog
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Launch the image editor with only text editing enabled
    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: imageToEdit,
          // Disable other features by setting their options to null
          blurOption: null,
          flipOption: null,
          brushOption: null,
          rotateOption: null,
          filtersOption: null,
        ),
      ),
    );

    // If the user edited the image, update it
    if (editedImageBytes != null) {
      // Show loading indicator again
      _showLoadingDialog();

      // Decode the edited image
      final codec =
      await ui.instantiateImageCodec(editedImageBytes);
      final frameInfo = await codec.getNextFrame();
      final editedImage = frameInfo.image;

      // Update the state
      setState(() {
        _image = editedImage;
        _imageBytes = editedImageBytes;
        _imageSize = Size(editedImage.width.toDouble(),
            editedImage.height.toDouble());
        _painterController.background =
            editedImage.backgroundDrawable;

        // Reset filters since they're now baked into the image
        if (_currentMode == EditingMode.filter) {
          _selectedPreset = 'None';
          _brightnessValue = 1.0;
          _contrastValue = 1.0;
          _saturationValue = 1.0;
          _sepiaValue = 0.0;
          _hueRotateValue = 0.0;
          _invertValue = 0.0;
          _opacityValue = 1.0;
          _blurValue = 0.0;
        }
      });

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text added successfully')),
        );
      }
    }
    } catch (e) {
      print('Error using text editor: $e');

      // Make sure the loading dialog is closed
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding text: $e')),
        );
      }
    }
    },
      icon: const Icon(Icons.text_fields),
      label: const Text('Add Text with Advanced Editor'),
    ),
        ],
      ),
    );
  }

  // Crop controls with actual working rotate and flip functions
  Widget _buildCropControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rotate left
        IconButton(
          icon: const Icon(Icons.rotate_left),
          onPressed: () => _rotateImage(-90),
          tooltip: 'Rotate Left',
        ),

        // Rotate right
        IconButton(
          icon: const Icon(Icons.rotate_right),
          onPressed: () => _rotateImage(90),
          tooltip: 'Rotate Right',
        ),

        // Flip horizontally
        IconButton(
          icon: const Icon(Icons.flip),
          onPressed: () => _flipImage(FlipDirection.horizontal),
          tooltip: 'Flip Horizontally',
        ),

        // Flip vertically
        IconButton(
          icon: Transform.rotate(
            angle: 1.5708, // 90 degrees in radians
            child: const Icon(Icons.flip),
          ),
          onPressed: () => _flipImage(FlipDirection.vertical),
          tooltip: 'Flip Vertically',
        ),

        // Reset transformations
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
          onPressed: _resetTransformations,
        ),
      ],
    );
  }

  // Actual image rotation function
  void _rotateImage(double degrees) async {
    if (_image == null || _imageBytes == null) return;

    try {
      // Show loading indicator
      _showLoadingDialog();

      // Update rotation state
      setState(() {
        _rotationDegrees = (_rotationDegrees + degrees.toInt()) % 360;
        if (_rotationDegrees < 0) _rotationDegrees += 360;
      });

      // Decode the image
      final img.Image? decodedImage = img.decodeImage(_imageBytes!);
      if (decodedImage == null) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        throw Exception('Failed to decode image for rotation');
      }

      // Apply rotation
      img.Image rotatedImage;
      if (degrees == 90) {
        rotatedImage = img.copyRotate(decodedImage, angle: 90);
      } else if (degrees == -90) {
        rotatedImage = img.copyRotate(decodedImage, angle: 270);
      } else {
        rotatedImage = decodedImage;
      }

      // Apply existing flip transformations if any
      if (_isImageFlippedHorizontally) {
        rotatedImage = img.flipHorizontal(rotatedImage);
      }
      if (_isImageFlippedVertically) {
        rotatedImage = img.flipVertical(rotatedImage);
      }

      // Convert back to bytes
      final Uint8List rotatedBytes =
      Uint8List.fromList(img.encodePng(rotatedImage));

      // Update the image
      final codec = await ui.instantiateImageCodec(rotatedBytes);
      final frameInfo = await codec.getNextFrame();
      final rotatedUiImage = frameInfo.image;

      // Update state
      setState(() {
        _image = rotatedUiImage;
        _imageBytes = rotatedBytes;
        _imageSize = Size(
            rotatedUiImage.width.toDouble(), rotatedUiImage.height.toDouble());
      });

      // Update painter background
      _painterController.background = rotatedUiImage.backgroundDrawable;

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Image rotated by ${degrees.toInt()} degrees')),
        );
      }
    } catch (e) {
      print('Error rotating image: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rotating image: $e')),
        );
      }
    }
  }

  // Actual image flipping function
  void _flipImage(FlipDirection direction) async {
    if (_image == null || _imageBytes == null) return;

    try {
      // Show loading indicator
      _showLoadingDialog();

      // Update flip state
      setState(() {
        if (direction == FlipDirection.horizontal) {
          _isImageFlippedHorizontally = !_isImageFlippedHorizontally;
        } else {
          _isImageFlippedVertically = !_isImageFlippedVertically;
        }
      });

      // Decode the image
      final img.Image? decodedImage = img.decodeImage(_imageBytes!);
      if (decodedImage == null) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        throw Exception('Failed to decode image for flipping');
      }

      // Apply flip
      img.Image flippedImage;
      if (direction == FlipDirection.horizontal) {
        flippedImage = img.flipHorizontal(decodedImage);
      } else {
        flippedImage = img.flipVertical(decodedImage);
      }

      // Convert back to bytes
      final Uint8List flippedBytes =
      Uint8List.fromList(img.encodePng(flippedImage));

      // Update the image
      final codec = await ui.instantiateImageCodec(flippedBytes);
      final frameInfo = await codec.getNextFrame();
      final flippedUiImage = frameInfo.image;

      // Update state
      setState(() {
        _image = flippedUiImage;
        _imageBytes = flippedBytes;
      });

      // Update painter background
      _painterController.background = flippedUiImage.backgroundDrawable;

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Image flipped ${direction == FlipDirection.horizontal ? 'horizontally' : 'vertically'}'),
          ),
        );
      }
    } catch (e) {
      print('Error flipping image: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flipping image: $e')),
        );
      }
    }
  }

  // Actual image reset function
  void _resetTransformations() async {
    if (_originalImageBytes == null) return;

    try {
      // Show loading indicator
      _showLoadingDialog();

      // Reset transformation state
      setState(() {
        _rotationDegrees = 0;
        _isImageFlippedHorizontally = false;
        _isImageFlippedVertically = false;
      });

      // Reset image to original
      final codec = await ui.instantiateImageCodec(_originalImageBytes!);
      final frameInfo = await codec.getNextFrame();
      final originalImage = frameInfo.image;

      // Update state
      setState(() {
        _image = originalImage;
        _imageBytes = _originalImageBytes;
        _imageSize = Size(
            originalImage.width.toDouble(), originalImage.height.toDouble());
      });

      // Update painter background
      _painterController.background = originalImage.backgroundDrawable;

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image transformations reset')),
        );
      }
    } catch (e) {
      print('Error resetting image: $e');
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _cleanupQuillResources();
    _tabController.dispose();
    _painterController.dispose();
    _image?.dispose();
    super.dispose();
  }
}

enum EditingMode {
  filter,
  draw,
  text,
  crop,
}

enum FlipDirection {
  horizontal,
  vertical,
}

// Custom color picker widget - simplified version
class ColorPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: pickerColor,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 10),

        // Color options grid
        GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: Colors.primaries.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => onColorChanged(Colors.primaries[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.primaries[index],
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}