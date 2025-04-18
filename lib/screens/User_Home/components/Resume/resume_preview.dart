import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_interface.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_pdf.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:share_plus/share_plus.dart';

class ResumePreviewScreen extends StatefulWidget {
  final ResumeData resumeData;
  final String? resumeId;

  const ResumePreviewScreen({
    Key? key,
    required this.resumeData,
    this.resumeId,
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
    print("Selected template type: ${widget.resumeData.templateType}"); // Debug print
    _template = TemplateFactory.getTemplate(widget.resumeData.templateType);
    _style = _getTemplateStyle(widget.resumeData.templateType);
    // Generate PDF on load for immediate sharing
    _generatePdf();
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
  Future<void> _generatePdf() async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Use the PDF generator service with saveToDownloads=true
      final pdfPath = await ResumePdfGenerator.generatePdf(
        widget.resumeData,
        saveToDownloads: true, // Save to downloads folder
      );

      // Update state with PDF path
      setState(() {
        _pdfPath = pdfPath;
        _isGeneratingPdf = false;
      });
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() {
        _isGeneratingPdf = false;
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to generate PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Share PDF
  void _sharePdf() async {
    // If PDF isn't generated yet, generate it first
    if (_pdfPath == null) {
      await _generatePdf();
    }

    if (_pdfPath != null) {
      await Share.shareXFiles(
        [XFile(_pdfPath!)],
        text: 'My Resume',
      );

      // After sharing, navigate to MainScreen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
              (route) => false, // Removes all routes from the stack
        );
      }
    } else {
      // Show error if sharing failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share. PDF not generated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _style.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.resumeData.templateType.toLowerCase() == 'business'
            ? _style.primaryColor
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: widget.resumeData.templateType.toLowerCase() == 'business'
                ? Colors.white
                : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resume Preview',
          style: TextStyle(
            color: widget.resumeData.templateType.toLowerCase() == 'business'
                ? Colors.white
                : Colors.black,
            fontSize: 16,
          ),
        ),
        actions: [
          // Share button always visible
          IconButton(
            icon: Icon(
              Icons.share,
              color: widget.resumeData.templateType.toLowerCase() == 'business'
                  ? Colors.white
                  : Colors.black,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Template preview with flexible sizing
                    Container(
                      constraints: BoxConstraints(
                        // Use maximum width available, constrained to A4 proportions when possible
                        maxWidth: MediaQuery.of(context).size.width > 600
                            ? 595 // A4 width in points
                            : MediaQuery.of(context).size.width - 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _style.shadowColor,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: widget.resumeData.templateType.toLowerCase() == 'classic'
                            ? Border.all(color: Colors.grey[300]!)
                            : null,
                      ),
                      // Use SingleChildScrollView to prevent overflow issues
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this inner scroll view
                        child: _template.buildTemplate(
                          widget.resumeData,
                          isPreview: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructions box - styled based on template
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: _style.instructionsBoxColor,
                    //     borderRadius: BorderRadius.circular(8),
                    //     border: Border.all(color: _style.instructionsBoxBorderColor),
                    //     boxShadow: widget.resumeData.templateType.toLowerCase() == 'business'
                    //         ? [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.05),
                    //         blurRadius: 4,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ]
                    //         : null,
                    //   ),
                    //   child: Column(
                    //     children: [
                    //       Text(
                    //         'Preview',
                    //         style: _style.titleTextStyle,
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(
                    //         'This is a preview of your resume. To download it as a PDF, tap the "Download PDF" button below. The PDF will be saved to your Downloads folder.',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: widget.resumeData.templateType.toLowerCase() == 'classic'
                    //               ? Colors.black87
                    //               : _style.accentColor,
                    //         ),
                    //         textAlign: TextAlign.center,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom buttons - styled based on template
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.resumeData.templateType.toLowerCase() == 'business'
                  ? _style.primaryColor.withOpacity(0.05)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _style.shadowColor,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
              border: widget.resumeData.templateType.toLowerCase() == 'classic'
                  ? Border(top: BorderSide(color: _style.dividerColor))
                  : null,
            ),
            child: Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to edit
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: _style.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            widget.resumeData.templateType.toLowerCase() == 'classic' ? 4 : 8),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _style.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Download PDF button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGeneratingPdf ? null : _generatePdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _style.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            widget.resumeData.templateType.toLowerCase() == 'classic' ? 4 : 8),
                      ),
                    ),
                    child: _isGeneratingPdf
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Generating...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _pdfPath == null ? 'Download PDF' : 'Download Again',
                          style: _style.buttonTextStyle,
                        ),
                      ],
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