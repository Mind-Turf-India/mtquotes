import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/app_theme.dart';

class SignatureInfo {
  final Uint8List signatureImage;
  final Offset position;
  final Size size;
  final int pageNumber;

  SignatureInfo({
    required this.signatureImage,
    required this.position,
    required this.size,
    required this.pageNumber,
  });
}

class PdfSignatureScreen extends StatefulWidget {
  final String pdfPath;

  const PdfSignatureScreen({Key? key, required this.pdfPath}) : super(key: key);

  @override
  State<PdfSignatureScreen> createState() => _PdfSignatureScreenState();
}

class _PdfSignatureScreenState extends State<PdfSignatureScreen> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isSignaturePanelOpen = false;
  bool _isSaving = false;
  String? _savedSignedPdfPath;

  // For tracking multiple signatures
  List<SignatureInfo> _signatures = [];

  // For draggable signature
  Uint8List? _currentSignatureImage;
  Offset _currentSignaturePosition = Offset.zero;
  bool _isPositioningSignature = false;
  Size _signatureSize = const Size(150, 50);

  // For signature styling
  Color _signatureColor = Colors.black;
  double _strokeWidth = 2.0;
  List<Color> _availableColors = [
    Colors.black,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
  ];

  // For keeping track of signature mode
  bool _showSignaturesList = false;

  @override
  Widget build(BuildContext context) {
    // Use theme properties from the current theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fill & Sign PDF'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSignaturePanelOpen && !_isPositioningSignature)
            IconButton(
              icon: const Icon(Icons.draw),
              tooltip: 'Add Signature',
              onPressed: () {
                setState(() {
                  _isSignaturePanelOpen = true;
                });
              },
            ),
          if (!_isSignaturePanelOpen && !_isPositioningSignature && _signatures.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'View Signatures',
              onPressed: () {
                setState(() {
                  _showSignaturesList = !_showSignaturesList;
                });
              },
            ),
          if (_isSignaturePanelOpen)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Confirm Signature',
              onPressed: _getSignatureAndPosition,
            ),
          if (_isSignaturePanelOpen)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                setState(() {
                  _isSignaturePanelOpen = false;
                });
              },
            ),
          if (_isPositioningSignature)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Apply Signature',
              onPressed: _applySignature,
            ),
          if (_isPositioningSignature)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                setState(() {
                  _isPositioningSignature = false;
                  _currentSignatureImage = null;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save PDF',
            onPressed: _savePdf,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer - Use a key to force rebuild when savedSignedPdfPath changes
          _savedSignedPdfPath != null
              ? SfPdfViewer.file(
            File(_savedSignedPdfPath!),
            controller: _pdfViewerController,
            key: ValueKey(_savedSignedPdfPath),
          )
              : SfPdfViewer.file(
            File(widget.pdfPath),
            controller: _pdfViewerController,
            key: ValueKey(widget.pdfPath),
          ),

          // Display existing signatures overlay - Using Stack of positioned widgets instead of CustomPaint
          if (!_isPositioningSignature && !_isSignaturePanelOpen)
            Positioned.fill(
              child: Stack(
                children: _signatures
                    .where((sig) => sig.pageNumber == _pdfViewerController.pageNumber)
                    .map((sig) {
                  return Positioned(
                    left: sig.position.dx,
                    top: sig.position.dy,
                    width: sig.size.width,
                    height: sig.size.height,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Image.memory(
                        sig.signatureImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Draggable signature overlay
          if (_isPositioningSignature && _currentSignatureImage != null)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _currentSignaturePosition += details.delta;
                  });
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: _currentSignaturePosition.dx,
                      top: _currentSignaturePosition.dy,
                      child: Container(
                        width: _signatureSize.width,
                        height: _signatureSize.height,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primary, width: 1),
                        ),
                        child: Image.memory(
                          _currentSignatureImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Size controls at bottom
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Signature Size',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.compress, size: 20),
                                  Expanded(
                                    child: Slider(
                                      value: _signatureSize.width,
                                      min: 100,
                                      max: 300,
                                      onChanged: (value) {
                                        setState(() {
                                          // Keep aspect ratio
                                          double aspectRatio = _signatureSize.height / _signatureSize.width;
                                          _signatureSize = Size(value, value * aspectRatio);
                                        });
                                      },
                                    ),
                                  ),
                                  Icon(Icons.expand, size: 20),
                                ],
                              ),
                              Text(
                                'Page: ${_pdfViewerController.pageNumber} - Drag signature to position it, then tap ✓',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Signature pad panel
          if (_isSignaturePanelOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 280,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Signature Style:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Color picker
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _availableColors.map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _signatureColor = color;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: _signatureColor == color
                                          ? Border.all(color: theme.colorScheme.primary, width: 2)
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Stroke width slider
                    Row(
                      children: [
                        Text(
                          'Line Width:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Slider(
                            value: _strokeWidth,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            activeColor: theme.colorScheme.primary,
                            inactiveColor: theme.colorScheme.primary.withOpacity(0.3),
                            onChanged: (value) {
                              setState(() {
                                _strokeWidth = value;
                              });
                            },
                          ),
                        ),
                        Text(_strokeWidth.toStringAsFixed(1)),
                      ],
                    ),

                    // Signature pad with appropriate background
                    Expanded(
                      child: Stack(
                        children: [
                          // Checkerboard pattern background
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CheckerboardPainter(
                                color1: Colors.grey.shade200,
                                color2: Colors.white,
                                size: 10.0,
                              ),
                            ),
                          ),
                          // Transparent signature pad
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SfSignaturePad(
                                key: _signaturePadKey,
                                backgroundColor: Colors.transparent,
                                strokeColor: _signatureColor,
                                minimumStrokeWidth: _strokeWidth,
                                maximumStrokeWidth: _strokeWidth + 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _signaturePadKey.currentState?.clear();
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Signatures list panel
          if (_showSignaturesList)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 200,
              child: Container(
                color: theme.colorScheme.surface,
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Signatures', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _showSignaturesList = false;
                            });
                          },
                        ),
                      ],
                    ),
                    Divider(),
                    Expanded(
                      child: _signatures.isEmpty
                          ? Center(child: Text('No signatures added'))
                          : ListView.builder(
                        itemCount: _signatures.length,
                        itemBuilder: (context, index) {
                          final sig = _signatures[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            leading: Container(
                              width: 50,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerTheme.color ?? Colors.grey.shade300),
                                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              ),
                              child: Image.memory(sig.signatureImage),
                            ),
                            title: Text('Page ${sig.pageNumber}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, size: 20),
                              onPressed: () {
                                setState(() {
                                  _signatures.removeAt(index);
                                });
                              },
                            ),
                            onTap: () {
                              // Navigate to the signature's page
                              _pdfViewerController.jumpToPage(sig.pageNumber);
                              setState(() {
                                _showSignaturesList = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _getSignatureAndPosition() async {
    try {
      // Get the signature as image with transparent background
      final signatureData = await _signaturePadKey.currentState?.toImage(
        pixelRatio: 3.0, // Higher resolution
      );

      if (signatureData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No signature found')),
        );
        return;
      }

      // Convert to byte data with PNG format (to preserve transparency)
      final byteData = await signatureData.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();

      // Process the image to make the background transparent
      final transparentSignature = await _makeSignatureTransparent(uint8List);

      // Set initial position to center of screen
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _currentSignatureImage = transparentSignature;
        _isSignaturePanelOpen = false;
        _isPositioningSignature = true;
        _currentSignaturePosition = Offset(
          (screenSize.width - _signatureSize.width) / 2,
          (screenSize.height - _signatureSize.height) / 2,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating signature: $e')),
      );
    }
  }

  Future<Uint8List> _makeSignatureTransparent(Uint8List imageData) async {
    // The SfSignaturePad with backgroundColor: Colors.transparent already creates
    // a transparent PNG, so we just need to return it as is
    return imageData;
  }

  Future<void> _applySignature() async {
    if (_currentSignatureImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signature to apply')),
      );
      return;
    }

    try {
      // Get current page
      final currentPage = _pdfViewerController.pageNumber;

      // Add signature to our list
      _signatures.add(
        SignatureInfo(
          signatureImage: _currentSignatureImage!,
          position: _currentSignaturePosition,
          size: _signatureSize,
          pageNumber: currentPage,
        ),
      );

      setState(() {
        _isPositioningSignature = false;
        _currentSignatureImage = null;
      });

      // Don't automatically update the PDF here, just show a success message
      // We'll only update the PDF when saving
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature placed successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePdfWithSignatures() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Load the existing PDF
      final PdfDocument document =
      PdfDocument(inputBytes: File(widget.pdfPath).readAsBytesSync());

      // Group signatures by page number for more efficient processing
      Map<int, List<SignatureInfo>> signaturesByPage = {};
      for (var sig in _signatures) {
        if (!signaturesByPage.containsKey(sig.pageNumber)) {
          signaturesByPage[sig.pageNumber] = [];
        }
        signaturesByPage[sig.pageNumber]!.add(sig);
      }

      // Get app bar height for position adjustment
      final appBarHeight = AppBar().preferredSize.height;

      // Process each page that has signatures
      signaturesByPage.forEach((pageNumber, sigs) {
        final page = document.pages[pageNumber - 1];
        final pageSize = page.size;

        // Get the actual viewable area (excluding AppBar)
        final viewportSize = MediaQuery.of(context).size;
        final viewableHeight = viewportSize.height - appBarHeight;

        // Calculate the scaling factor between PDF and viewport
        // Assuming PDF is fitted to width in the viewer
        final scaleX = pageSize.width / viewportSize.width;

        // Calculate the effective height of the PDF in the viewport
        final pdfAspectRatio = pageSize.height / pageSize.width;
        final effectivePdfHeight = viewportSize.width * pdfAspectRatio;

        // Calculate vertical offset if PDF doesn't fill the entire view height
        final verticalOffset = (viewableHeight - effectivePdfHeight) / 2;

        // Add each signature to the page
        for (var sig in sigs) {
          // Create PdfBitmap from the signature
          final PdfBitmap image = PdfBitmap(sig.signatureImage);

          // Adjust Y position to account for AppBar
          final adjustedY = sig.position.dy - appBarHeight;

          // Calculate position on the PDF page with adjusted coordinates
          final x = sig.position.dx * scaleX;

          // For Y position, we need to adjust for the viewable area
          // and scale relative to the content area
          double y;
          if (effectivePdfHeight < viewableHeight) {
            // If PDF is shorter than viewable area, adjust for vertical centering
            if (adjustedY < verticalOffset) {
              // Signature is above the PDF
              y = 0;
            } else if (adjustedY > verticalOffset + effectivePdfHeight) {
              // Signature is below the PDF
              y = pageSize.height;
            } else {
              // Signature is within the PDF area
              y = (adjustedY - verticalOffset) * (pageSize.height / effectivePdfHeight);
            }
          } else {
            // PDF is taller than the viewable area
            y = adjustedY * (pageSize.height / viewableHeight);
          }

          // Calculate size on PDF page with proper scaling
          final signatureWidth = sig.size.width * scaleX;
          final signatureHeight = sig.size.height * scaleX; // Use same scale for aspect ratio preservation

          // Add the signature to the PDF
          page.graphics.drawImage(
            image,
            Rect.fromLTWH(x, y, signatureWidth, signatureHeight),
          );
        }
      });

      // Save the modified PDF
      final directory = await getApplicationDocumentsDirectory();
      final String signedPdfPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final File signedPdfFile = File(signedPdfPath);
      await signedPdfFile.writeAsBytes(await document.save());

      // Dispose the document
      document.dispose();

      // Clear the signatures array since they are now in the PDF
      // This will prevent them from being rendered twice on screen
      setState(() {
        _isSaving = false;
        _savedSignedPdfPath = signedPdfPath;
        _signatures = []; // Clear the signatures array
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePdf() async {
    try {
      // Show saving indicator
      setState(() {
        _isSaving = true;
      });

      // Make sure the PDF is updated with all signatures
      if (_signatures.isNotEmpty) {
        await _updatePdfWithSignatures();
      }

      final pdfPath = _savedSignedPdfPath ?? widget.pdfPath;

      // Create a copy in the vaky directory
      final directory = await _getVakyDirectory();
      final filename = 'signed_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = File('${directory.path}/$filename');

      await File(pdfPath).copy(savedFile.path);

      // Hide saving indicator
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${savedFile.path}'),
          backgroundColor: AppColors.primaryGreen,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(savedFile.path),
          ),
        ),
      );
    } catch (e) {
      // Hide saving indicator even if there's an error
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<Directory> _getVakyDirectory() async {
  if (Platform.isAndroid) {
    Directory? directory;

    if (await Permission.manageExternalStorage.isGranted) {
      try {
        directory = Directory('/storage/emulated/0/Vaky');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } catch (e) {
        print('Error accessing external storage: $e');
      }
    }

    directory = await getExternalStorageDirectory();
    if (directory != null) {
      final vakyDir = Directory('${directory.path}/vaky');
      if (!await vakyDir.exists()) {
        await vakyDir.create(recursive: true);
      }
      return vakyDir;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final vakyDir = Directory('${appDir.path}/vaky');
    if (!await vakyDir.exists()) {
      await vakyDir.create(recursive: true);
    }
    return vakyDir;
  } else {
    final directory = await getApplicationDocumentsDirectory();
    final vakyDir = Directory('${directory.path}/vaky');
    if (!await vakyDir.exists()) {
      await vakyDir.create(recursive: true);
    }
    return vakyDir;
  }
}


// Custom painter for creating a checkerboard pattern to indicate transparency
class CheckerboardPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double size;

  CheckerboardPainter({
    required this.color1,
    required this.color2,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()..color = color1;
    final Paint paint2 = Paint()..color = color2;

    final numSquaresX = (size.width / this.size).ceil();
    final numSquaresY = (size.height / this.size).ceil();

    for (int y = 0; y < numSquaresY; y++) {
      for (int x = 0; x < numSquaresX; x++) {
        final paint = (x + y) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
            x * this.size,
            y * this.size,
            this.size,
            this.size,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Create a themed app with your AppTheme class
class PdfSignatureApp extends StatelessWidget {
  final String pdfPath;

  const PdfSignatureApp({Key? key, required this.pdfPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.system, // Use system theme by default
      home: PdfSignatureScreen(pdfPath: pdfPath),
    );
  }
}