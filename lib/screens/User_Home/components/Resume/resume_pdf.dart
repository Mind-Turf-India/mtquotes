import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ResumePdfGenerator {
  // Generate PDF from Resume Data
  static Future<String> generatePdf(ResumeData data, {bool saveToDownloads = true}) async {
    // Create PDF document
    final pdf = pw.Document();

    // Load font assets
    final regularFont =
    await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
    final boldFont = await rootBundle.load('assets/fonts/OpenSans-Bold.ttf');
    final italicFont =
    await rootBundle.load('assets/fonts/OpenSans-Italic.ttf');

    // Register fonts
    final ttfRegular = pw.Font.ttf(regularFont);
    final ttfBold = pw.Font.ttf(boldFont);
    final ttfItalic = pw.Font.ttf(italicFont);

    // Define theme
    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
      italic: ttfItalic,
    );

    // Load profile image if it exists
    pw.MemoryImage? profileImage;
    if (data.personalInfo.profileImagePath != null) {
      final file = File(data.personalInfo.profileImagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        profileImage = pw.MemoryImage(bytes);
      }
    }

    // Add pages based on template type and content size
    // Using MultiPage to handle content overflow automatically
    switch (data.templateType.toLowerCase()) {
      case 'modern':
        pdf.addPage(_buildModernTemplate(data, theme, profileImage));
        break;
      case 'classic':
        pdf.addPage(_buildClassicTemplate(data, theme, profileImage));
        break;
      case 'business':
        pdf.addPage(_buildBusinessTemplate(data, theme, profileImage));
        break;
      default:
        pdf.addPage(_buildModernTemplate(data, theme, profileImage));
    }

    // Save the PDF to the appropriate directory
    String filePath;

    if (saveToDownloads) {
      // Request storage permission
      await _requestStoragePermission();

      try {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // For Android
          downloadsDir = Directory('/storage/emulated/0/Download');
          // Ensure the directory exists
          if (!await downloadsDir.exists()) {
            // Fall back to app documents directory
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
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${downloadsDir.path}/Resume_${data.personalInfo.firstName}_${data.personalInfo.lastName}_$timestamp.pdf';
      } catch (e) {
        // If there's any error, fall back to temporary directory
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${dir.path}/Resume_${timestamp}.pdf';
      }
    } else {
      // Just save to temporary directory if not saving to downloads
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${dir.path}/Resume_${timestamp}.pdf';
    }

    // Save the PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  // Build Modern Template with MultiPage to handle overflow
  static pw.Page _buildModernTemplate(
      ResumeData data,
      pw.ThemeData theme,
      pw.MemoryImage? profileImage,
      ) {
    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          // Header with name and role
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            color: PdfColors.blueGrey800,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Profile image if available
                if (profileImage != null)
                  pw.Container(
                    width: 70,
                    height: 70,
                    margin: const pw.EdgeInsets.only(right: 20),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(
                        image: profileImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),

                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        data.personalInfo.role,
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content in two columns
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left sidebar with contact info and skills
              pw.Container(
                width: 160,
                color: PdfColors.blueGrey50,
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Contact section
                    pw.Text(
                      'CONTACT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey,
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // Email
                    pw.Text(
                      data.personalInfo.email,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Phone
                    pw.Text(
                      data.personalInfo.phone,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 8),

                    // Address
                    pw.Text(
                      '${data.personalInfo.address}\n${data.personalInfo.city}, ${data.personalInfo.country}\n${data.personalInfo.postalCode}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                    ),

                    pw.SizedBox(height: 24),

                    // Skills section
                    pw.Text(
                      'SKILLS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...data.skills.map((skill) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        skill,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    )),

                    pw.SizedBox(height: 24),

                    // Languages section
                    pw.Text(
                      'LANGUAGES',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    ...data.languages.map((language) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        language,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              // Main content with summary, experience, and education
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Professional Summary
                      pw.Text(
                        'PROFESSIONAL SUMMARY',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        data.professionalSummary,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // Work Experience
                      pw.Text(
                        'EXPERIENCE',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      ...data.employmentHistory.map((job) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 14),
                        child: pw.Column(
                          crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              job.jobTitle,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${job.employer} | ${job.location} | ${job.startDate} - ${job.endDate}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              job.description,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      )),

                      pw.SizedBox(height: 20),

                      // Education
                      pw.Text(
                        'EDUCATION',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      ...data.education.map((edu) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 14),
                        child: pw.Column(
                          crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              edu.title,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${edu.school} | ${edu.level} | ${edu.startDate} - ${edu.endDate}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              edu.description,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.black,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ];
      },
    );
  }

  // Build Classic Template with traditional centered design
  static pw.Page _buildClassicTemplate(
      ResumeData data,
      pw.ThemeData theme,
      pw.MemoryImage? profileImage,
      ) {
    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with name and contact info
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (profileImage != null)
                        pw.Container(
                          width: 80,
                          height: 80,
                          margin: const pw.EdgeInsets.only(bottom: 10),
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: PdfColors.grey300, width: 2),
                            image: pw.DecorationImage(
                              image: profileImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),

                      pw.Text(
                        '${data.personalInfo.firstName} ${data.personalInfo.lastName}'.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                          letterSpacing: 1.5,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        data.personalInfo.role,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),

                      // Contact info in one row using spacers for separation
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            data.personalInfo.email,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(' | ',
                              style:
                              const pw.TextStyle(color: PdfColors.grey700)),
                          pw.Text(
                            data.personalInfo.phone,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(' | ',
                              style:
                              const pw.TextStyle(color: PdfColors.grey700)),
                          pw.Text(
                            '${data.personalInfo.city}, ${data.personalInfo.country}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 10),

                // Professional Summary
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  data.professionalSummary,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.black,
                  ),
                ),

                pw.SizedBox(height: 16),

                // Experience
                pw.Text(
                  'EXPERIENCE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
                ...data.employmentHistory.map((job) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              job.jobTitle,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${job.startDate} - ${job.endDate}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              job.employer,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            job.location,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        job.description,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                )),

                pw.SizedBox(height: 16),

                // Education
                pw.Text(
                  'EDUCATION',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
                ...data.education.map((edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              edu.title,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            '${edu.startDate} - ${edu.endDate}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              edu.school,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Text(
                            edu.location,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        edu.level,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                )),

                pw.SizedBox(height: 16),

                // Skills and Languages
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Skills section
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SKILLS',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                          pw.SizedBox(height: 6),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: data.skills
                                .map((skill) => pw.Padding(
                              padding:
                              const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '• $skill',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.black,
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),

                    // Languages section
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'LANGUAGES',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                          pw.SizedBox(height: 6),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: data.languages
                                .map((language) => pw.Padding(
                              padding:
                              const pw.EdgeInsets.only(bottom: 4),
                              child: pw.Text(
                                '• $language',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.black,
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  // Build Business Template with corporate styling
  // Build Business Template with corporate styling
  static pw.Page _buildBusinessTemplate(
      ResumeData data,
      pw.ThemeData theme,
      pw.MemoryImage? profileImage,
      ) {
    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          // Header with name, role and contact info
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            color: PdfColors.indigo800,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Profile image and name in row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Profile image if available
                    if (profileImage != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        margin: const pw.EdgeInsets.only(right: 20),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.white, width: 2),
                          image: pw.DecorationImage(
                            image: profileImage,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),

                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            data.personalInfo.role,
                            style: const pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.white),
                pw.SizedBox(height: 16),

                // Contact info in row
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 14,
                            height: 14,
                            margin: const pw.EdgeInsets.only(right: 6),
                            child: pw.Center(
                              child: pw.Text(
                                '✉',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            data.personalInfo.email,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 14,
                            height: 14,
                            margin: const pw.EdgeInsets.only(right: 6),
                            child: pw.Center(
                              child: pw.Text(
                                '✆',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            data.personalInfo.phone,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 14,
                            height: 14,
                            margin: const pw.EdgeInsets.only(right: 6),
                            child: pw.Center(
                              child: pw.Text(
                                '⌂',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            '${data.personalInfo.city}, ${data.personalInfo.country}',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Professional Summary
                _buildPdfSectionHeader('Professional Summary'),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    data.professionalSummary,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.black,
                      lineSpacing: 1.5,
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                // Experience
                _buildPdfSectionHeader('Professional Experience'),
                pw.SizedBox(height: 10),

                // Employment history items
                ...data.employmentHistory.map((job) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 14),
                  padding: const pw.EdgeInsets.only(left: 10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(
                          color: PdfColors.indigo800,
                          width: 2,
                        ),
                      )
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        job.jobTitle,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        '${job.employer} | ${job.location}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.indigo700,
                        ),
                      ),
                      pw.Text(
                        '${job.startDate} - ${job.endDate}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        job.description,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                )),

                pw.SizedBox(height: 20),

                // Education
                _buildPdfSectionHeader('Education'),
                pw.SizedBox(height: 10),

                // Education in a grid or row based layout
                pw.Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: data.education.map((edu) => pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          edu.title,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          edu.school,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.indigo700,
                          ),
                        ),
                        pw.Text(
                          '${edu.startDate} - ${edu.endDate}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          edu.level,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),

                pw.SizedBox(height: 20),

                // Skills and Languages
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Skills section
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Skills'),
                          pw.SizedBox(height: 10),
                          // Skills with tags and boxes
                          pw.Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: data.skills.map((skill) => pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.indigo50,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                              ),
                              child: pw.Text(
                                skill,
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.indigo700,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),

                    // Languages section with progress bars
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Languages'),
                          pw.SizedBox(height: 10),
                          // Languages with skill bars
                          ...data.languages.map((language) => pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                language,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Container(
                                height: 4,
                                width: 150,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                                child: pw.Align(
                                  alignment: pw.Alignment.centerLeft,
                                  child: pw.Container(
                                    height: 4,
                                    width: 120, // Default 80% proficiency (150*0.8)
                                    decoration: pw.BoxDecoration(
                                      color: PdfColors.indigo700,
                                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                    ),
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 10),
                            ],
                          )).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  // Helper method for business template section headers
  static pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo800,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 3,
          width: 30,
          decoration: const pw.BoxDecoration(
            color: PdfColors.indigo800,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.5)),
          ),
        ),
      ],
    );
  }

  // Request storage permission
  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request storage permission on Android
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // On newer Android versions, also request the manageExternalStorage permission
      try {
        // Only needed on Android 11+ (API level 30+)
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
      } catch (e) {
        // Ignore errors for older Android versions
        print('Error requesting manage external storage: $e');
      }
    }
  }
}