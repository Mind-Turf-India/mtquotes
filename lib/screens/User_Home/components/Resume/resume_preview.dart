import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_interface.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_pdf.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ResumePreviewScreen extends StatefulWidget {
  final ResumeData resumeData;
  final String? resumeId;
  final Function()? onEdit; // Callback for edit action

  const ResumePreviewScreen({
    Key? key,
    required this.resumeData,
    this.resumeId,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  bool _isGeneratingPdf = false;
  String? _pdfPath;
  late ResumeTemplate _template;
  late TemplateStyle _style;

  @override
  void initState() {
    super.initState();
    print("Selected template type: ${widget.resumeData.templateType}");
    _template = TemplateFactory.getTemplate(widget.resumeData.templateType);
    _style = _getTemplateStyle(widget.resumeData.templateType);
    // Generate PDF on load for immediate actions
    generatePdf(widget.resumeData,
      saveToDownloads: true);
  }

  // Helper method to get the template's styling parameters
  TemplateStyle _getTemplateStyle(String templateType) {
    switch (templateType.toLowerCase()) {
      case 'classic':
        return TemplateStyle(
          primaryColor: Colors.black,
          accentColor: Colors.grey[600]!,
          backgroundColor: Colors.grey[50]!,
          buttonColor: Colors.black,
          dividerColor: Colors.grey[400]!,
          buttonTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          instructionsBoxColor: Colors.grey[200]!,
          instructionsBoxBorderColor: Colors.grey[400]!,
          shadowColor: Colors.black.withOpacity(0.1),
        );

      case 'business':
        return TemplateStyle(
          primaryColor: Colors.indigo[800]!,
          accentColor: Colors.indigo[600]!,
          backgroundColor: Colors.white,
          buttonColor: Colors.indigo[700]!,
          dividerColor: Colors.indigo[200]!,
          buttonTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: TextStyle(
            color: Colors.indigo[800],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          instructionsBoxColor: Colors.indigo[50]!,
          instructionsBoxBorderColor: Colors.indigo[200]!,
          shadowColor: Colors.indigo.withOpacity(0.1),
        );

      case 'modern':
      default:
        return TemplateStyle(
          primaryColor: Colors.blue[700]!,
          accentColor: Colors.blueGrey[700]!,
          backgroundColor: const Color(0xFFF5F5F5),
          buttonColor: Colors.blue[700]!,
          dividerColor: Colors.blue[200]!,
          buttonTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          titleTextStyle: TextStyle(
            color: Colors.blue[800],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          instructionsBoxColor: Colors.blue[50]!,
          instructionsBoxBorderColor: Colors.blue[200]!,
          shadowColor: Colors.black.withOpacity(0.1),
        );
    }
  }

  // Generate PDF file
  static Future<String> generatePdf(ResumeData data, {bool saveToDownloads = true}) async {
    // Create PDF document
    final pdf = pw.Document();
    String filePath;

    if (saveToDownloads) {
      // Request storage permission
      await _requestStoragePermission();

      try {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // For Android
          // Try different approaches to get the Downloads directory
          try {
            // First approach: direct path to Download folder
            downloadsDir = Directory('/storage/emulated/0/Download/Vaky');
            if (!await downloadsDir.exists()) {
              // Fall back to secondary approach
              final externalDir = await getExternalStorageDirectory();
              if (externalDir != null) {
                String newPath = "";
                List<String> paths = externalDir.path.split("/");
                for (int i = 1; i < paths.length; i++) {
                  String folder = paths[i];
                  if (folder != "Android") {
                    newPath += "/" + folder;
                  } else {
                    break;
                  }
                }
                newPath += "/Vaky";
                downloadsDir = Directory(newPath);
                // Create directory if it doesn't exist
                if (!await downloadsDir.exists()) {
                  await downloadsDir.create(recursive: true);
                }
              }
            }
          } catch (e) {
            print("Error finding downloads directory: $e");
            // Final fallback to app documents directory
            downloadsDir = await getApplicationDocumentsDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS, we use the documents directory
          downloadsDir = await getApplicationDocumentsDirectory();
        } else {
          // For other platforms, just use temp directory
          downloadsDir = await getTemporaryDirectory();
        }

        // Create a file name with timestamp to avoid conflicts
        final fileName = 'Resume_${data.personalInfo.firstName}_${data.personalInfo.lastName}.pdf';
        filePath = '${downloadsDir?.path}/$fileName';

        // Save the PDF
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        print('PDF saved to: $filePath');

        // For Android 10+ (API level 29+), we need to use the MediaStore API
        // to make the file visible in the Downloads folder
        if (Platform.isAndroid) {
          try {
            // You can add code here to make the file visible in the gallery or files app
            // This might require additional plugins like path_provider_ex or media_scanner
          } catch (e) {
            print('Error adding file to media store: $e');
          }
        }
      } catch (e) {
        print('Error saving to downloads: $e');
        // If there's any error, fall back to temporary directory
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${dir.path}/Resume_${timestamp}.pdf';

        // Save to temp dir as fallback
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
      }
    } else {
      // Just save to temporary directory if not saving to downloads
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${dir.path}/Resume_${timestamp}.pdf';

      // Save the PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    }

    return filePath;
  }

  // Share PDF
  void _sharePdf() async {
    // If PDF isn't generated yet, generate it first
    if (_pdfPath == null) {
      await generatePdf(widget.resumeData,
        saveToDownloads: true);
    }

    if (_pdfPath != null) {
      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'My Resume',
      );
    } else {
      // Show error if sharing failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share. PDF not generated.')),
      );
    }
  }

  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request storage permission on Android
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        print('Storage permission status: $status');
      }

      // On newer Android versions, also request the manageExternalStorage permission
      try {
        // Only needed on Android 11+ (API level 30+)
        var externalStatus = await Permission.manageExternalStorage.status;
        if (!externalStatus.isGranted) {
          externalStatus = await Permission.manageExternalStorage.request();
          print('External storage permission status: $externalStatus');
        }
      } catch (e) {
        // Ignore errors for older Android versions
        print('Error requesting manage external storage: $e');
      }
    }
  }

  // Download PDF to device storage
  Future<void> _downloadPdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Generate and save PDF to downloads folder
      final pdfPath = await ResumePdfGenerator.generatePdf(
        widget.resumeData,
        saveToDownloads: true, // Save to downloads folder
      );

      setState(() {
        _pdfPath = pdfPath;
        _isGeneratingPdf = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resume downloaded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error downloading PDF: $e');
      setState(() {
        _isGeneratingPdf = false;
      });

      // Show error if download failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Edit the resume
  void _editResume() {
    // Go back to the previous screen (resume edit screen)
    if (widget.onEdit != null) {
      widget.onEdit!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusinessTemplate = widget.resumeData.templateType.toLowerCase() == 'business';

    return Scaffold(
      backgroundColor: _style.backgroundColor,
      appBar: AppBar(
        backgroundColor: isBusinessTemplate ? _style.primaryColor : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isBusinessTemplate ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resume Preview',
          style: TextStyle(
            color: isBusinessTemplate ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        iconTheme: IconThemeData(
          color: isBusinessTemplate ? Colors.white : Colors.black,
        ),
        centerTitle: true,
        actions: [
          // Share icon in app bar
          IconButton(
            icon: Icon(
              Icons.share,
              color: isBusinessTemplate ? Colors.white : Colors.black,
            ),
            onPressed: _isGeneratingPdf ? null : _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: _style.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: _template.buildTemplate(
                    widget.resumeData,
                    isPreview: true,
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  ),
                ),
              ),
            ),
          ),

          // Bottom buttons - Edit and Download
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _style.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Edit button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _editResume,
                      icon: const Icon(Icons.edit, size: 20),
                      label: Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Download button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _style.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isGeneratingPdf ? null : _downloadPdf,
                      icon: _isGeneratingPdf
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.download, size: 20),
                      label: Text(
                        _isGeneratingPdf ? 'Processing...' : 'Download',
                        style: _style.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to manage styling for different templates
class TemplateStyle {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color buttonColor;
  final Color dividerColor;
  final TextStyle buttonTextStyle;
  final TextStyle titleTextStyle;
  final Color instructionsBoxColor;
  final Color instructionsBoxBorderColor;
  final Color shadowColor;

  TemplateStyle({
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.buttonColor,
    required this.dividerColor,
    required this.buttonTextStyle,
    required this.titleTextStyle,
    required this.instructionsBoxColor,
    required this.instructionsBoxBorderColor,
    required this.shadowColor,
  });
}