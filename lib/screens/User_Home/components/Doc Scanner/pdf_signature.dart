import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  
  // For draggable signature
  Uint8List? _signatureImage;
  Offset _signaturePosition = Offset.zero;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill & Sign PDF'),
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
                  _signatureImage = null;
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
          // PDF Viewer
          _savedSignedPdfPath != null
              ? SfPdfViewer.file(
                  File(_savedSignedPdfPath!),
                  controller: _pdfViewerController,
                )
              : SfPdfViewer.file(
                  File(widget.pdfPath),
                  controller: _pdfViewerController,
                ),
          
          // Draggable signature overlay
          if (_isPositioningSignature && _signatureImage != null)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _signaturePosition += details.delta;
                  });
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: _signaturePosition.dx,
                      top: _signaturePosition.dy,
                      child: Container(
                        width: _signatureSize.width,
                        height: _signatureSize.height,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Image.memory(
                          _signatureImage!,
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
                                'Drag signature to position it, then tap ✓ to apply',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
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
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
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
                                          ? Border.all(color: Colors.blue, width: 2)
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
                    
                    // Signature pad
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SfSignaturePad(
                          key: _signaturePadKey,
                          backgroundColor: Colors.white,
                          strokeColor: _signatureColor,
                          minimumStrokeWidth: _strokeWidth,
                          maximumStrokeWidth: _strokeWidth + 2,
                        ),
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
          
          // Loading indicator
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _getSignatureAndPosition() async {
    try {
      // Get the signature as image
      final signatureData = await _signaturePadKey.currentState?.toImage();
      if (signatureData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No signature found')),
        );
        return;
      }

      final byteData = await signatureData.toByteData(format: ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();

      // Set initial position to center of screen
      final screenSize = MediaQuery.of(context).size;
      setState(() {
        _signatureImage = uint8List;
        _isSignaturePanelOpen = false;
        _isPositioningSignature = true;
        _signaturePosition = Offset(
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

  Future<void> _applySignature() async {
    if (_signatureImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No signature to apply')),
      );
      return;
    }

    try {
      // Get current page
      final currentPage = _pdfViewerController.pageNumber;

      // Process the PDF
      setState(() {
        _isSaving = true;
      });

      // Load the existing PDF
      final PdfDocument document =
          PdfDocument(inputBytes: File(widget.pdfPath).readAsBytesSync());

      // Create PdfBitmap from the signature
      final PdfBitmap image = PdfBitmap(_signatureImage!);

      // Get the page
      final page = document.pages[currentPage - 1];
      final pageSize = page.size;
      
      // Calculate position on the PDF page
      // Convert screen coordinates to PDF coordinates
      final viewportSize = MediaQuery.of(context).size;
      final x = (_signaturePosition.dx / viewportSize.width) * pageSize.width;
      final y = (_signaturePosition.dy / viewportSize.height) * pageSize.height;
      
      // Calculate size on PDF page
      final signatureWidth = (_signatureSize.width / viewportSize.width) * pageSize.width;
      final signatureHeight = (_signatureSize.height / viewportSize.height) * pageSize.height;

      // Add the signature to the PDF
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(x, y, signatureWidth, signatureHeight),
      );

      // Save the modified PDF
      final directory = await getApplicationDocumentsDirectory();
      final String signedPdfPath =
          '${directory.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final File signedPdfFile = File(signedPdfPath);
      await signedPdfFile.writeAsBytes(await document.save());

      // Dispose the document
      document.dispose();

      setState(() {
        _isPositioningSignature = false;
        _isSaving = false;
        _signatureImage = null;
        _savedSignedPdfPath = signedPdfPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature applied to PDF')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying signature: $e')),
      );
    }
  }

  Future<void> _savePdf() async {
    try {
      final pdfPath = _savedSignedPdfPath ?? widget.pdfPath;
      
      // Create a copy in the vaky directory
      final directory = await _getVakyDirectory();
      final filename = 'signed_doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = File('${directory.path}/$filename');
      
      await File(pdfPath).copy(savedFile.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${savedFile.path}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(savedFile.path),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PDF: $e')),
      );
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
}