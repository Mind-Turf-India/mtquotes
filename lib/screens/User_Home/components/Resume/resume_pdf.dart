import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ResumePdfGenerator {
  // Generate PDF from Resume Data
  static Future<String> generatePdf(ResumeData data,
      {bool saveToDownloads = true}) async {
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

// Load profile image if it exists
    pw.MemoryImage? profileImage;
    if (data.personalInfo.profileImagePath != null &&
        data.personalInfo.profileImagePath!.isNotEmpty) {
      print(
          'DEBUG - Original image path: ${data.personalInfo.profileImagePath}');
      try {
        if (data.personalInfo.profileImagePath!.startsWith('http')) {
          // For network images from Firebase or other URLs
          print(
              'Network image detected. Downloading image from: ${data.personalInfo.profileImagePath}');

          // Download the image bytes
          final response =
              await http.get(Uri.parse(data.personalInfo.profileImagePath!));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            if (bytes.isNotEmpty) {
              try {
                profileImage = pw.MemoryImage(bytes);
                print('Successfully downloaded and loaded network image');
              } catch (e) {
                print('Error creating MemoryImage from network image: $e');
              }
            } else {
              print('Downloaded image is empty');
            }
          } else {
            print('Failed to download image: ${response.statusCode}');
          }
        } else {
          // For local file path
          final file = File(data.personalInfo.profileImagePath!);

          if (await file.exists()) {
            final bytes = await file.readAsBytes();

            // Check if the bytes are valid and not empty
            if (bytes.isNotEmpty) {
              try {
                profileImage = pw.MemoryImage(bytes);
                print(
                    'Successfully loaded image from: ${data.personalInfo.profileImagePath}');
              } catch (e) {
                print('Error creating MemoryImage: $e');
              }
            } else {
              print(
                  'Image file exists but is empty: ${data.personalInfo.profileImagePath}');
            }
          } else {
            print(
                'Image file does not exist: ${data.personalInfo.profileImagePath}');

            // If the file doesn't exist at the provided path, try to see if it's a relative path
            // This is a common issue with path resolution
            final appDir = await getApplicationDocumentsDirectory();
            final alternativePath =
                '${appDir.path}/${data.personalInfo.profileImagePath!.split('/').last}';

            final alternativeFile = File(alternativePath);
            if (await alternativeFile.exists()) {
              final bytes = await alternativeFile.readAsBytes();
              if (bytes.isNotEmpty) {
                profileImage = pw.MemoryImage(bytes);
                print(
                    'Successfully loaded image from alternative path: $alternativePath');
              }
            }
          }
        }
      } catch (e) {
        print('Error loading profile image: $e');
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
        filePath =
            '${downloadsDir.path}/Resume_${data.personalInfo.firstName}_${data.personalInfo.lastName}_$timestamp.pdf';
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
        // Header with name, role, and contact info
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          color: PdfColors.blueGrey800,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Name and role with profile image
              pw.Row(
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
              
              // Contact details below name and role
              pw.SizedBox(height: 15),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Contact info - Email and Phone
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        pw.Icon(
                          pw.IconData(0xe0be), // Email icon
                          color: PdfColors.white,
                          size: 12,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          data.personalInfo.email,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Icon(
                          pw.IconData(0xe0cd), // Phone icon
                          color: PdfColors.white,
                          size: 12,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          data.personalInfo.phone,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Address
                  if (data.personalInfo.address.isNotEmpty)
                    pw.Container(
                      width: 180,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Icon(
                            pw.IconData(0xe0c8), // Location icon
                            color: PdfColors.white,
                            size: 12,
                          ),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Text(
                              '${data.personalInfo.address}, ${data.personalInfo.city}, ${data.personalInfo.country} ${data.personalInfo.postalCode}',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.white,
                              ),
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

        // Main content in two columns
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left sidebar with skills and languages
              pw.Container(
                width: 150,
                color: PdfColors.blueGrey50,
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
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
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                                // if (edu.description.isNotEmpty)
                                //   pw.Text(
                                //     edu.description,
                                //     style: const pw.TextStyle(
                                //       fontSize: 10,
                                //       color: PdfColors.black,
                                //     ),
                                //   ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            padding: const pw.EdgeInsets.all(
                40), // Increased from 30 to 40 to match interface
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with name and contact info
                pw.Center(
                  child: pw.Column(
                    children: [
                      // Profile image with updated styling to match interface
                      if (profileImage != null)
                        pw.Container(
                          width:
                              100, // Increased from 80 to 100 to match interface
                          height:
                              100, // Increased from 80 to 100 to match interface
                          margin: const pw.EdgeInsets.only(
                              bottom: 16), // Increased from 10 to 16
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(
                                color: PdfColors.grey300,
                                width: 3), // Increased from 2 to 3
                            image: pw.DecorationImage(
                              image: profileImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),

                      pw.Text(
                        '${data.personalInfo.firstName} ${data.personalInfo.lastName}'
                            .toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24, // Increased from 22 to 24
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                          letterSpacing: 1.5,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8), // Increased from 6 to 8
                      pw.Text(
                        data.personalInfo.role,
                        style: const pw.TextStyle(
                          fontSize: 16, // Increased from 14 to 16
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 12), // Increased from 10 to 12

                      // Contact info row with updated font size
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            data.personalInfo.email,
                            style: const pw.TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(' | ',
                              style:
                                  const pw.TextStyle(color: PdfColors.grey700)),
                          pw.Text(
                            data.personalInfo.phone,
                            style: const pw.TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(' | ',
                              style:
                                  const pw.TextStyle(color: PdfColors.grey700)),
                          pw.Text(
                            '${data.personalInfo.city}, ${data.personalInfo.country}',
                            style: const pw.TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 16), // Updated spacing to match interface

                // Professional Summary
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 16, // Increased from 14 to 16
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Divider(
                    thickness: 1,
                    color: PdfColors.grey400), // Increased thickness to 1
                pw.SizedBox(height: 8), // Increased from 6 to 8
                pw.Text(
                  data.professionalSummary,
                  style: const pw.TextStyle(
                    fontSize: 12, // Increased from 10 to 12
                    color: PdfColors.black,
                  ),
                ),

                pw.SizedBox(height: 24), // Increased from 16 to 24

                // Experience
                pw.Text(
                  'EXPERIENCE',
                  style: pw.TextStyle(
                    fontSize: 16, // Increased from 14 to 16
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Divider(
                    thickness: 1,
                    color: PdfColors.grey400), // Increased thickness to 1
                pw.SizedBox(height: 8), // Increased from 6 to 8
                ...data.employmentHistory.map((job) => pw.Padding(
                      padding: const pw.EdgeInsets.only(
                          bottom: 16), // Increased from 14 to 16
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  job.jobTitle,
                                  style: pw.TextStyle(
                                    fontSize: 14, // Increased from 12 to 14
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                '${job.startDate} - ${job.endDate}',
                                style: const pw.TextStyle(
                                  fontSize: 12, // Increased from 10 to 12
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4), // Increased from 2 to 4
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  job.employer,
                                  style: pw.TextStyle(
                                    fontSize: 12, // Increased from 10 to 12
                                    fontStyle: pw.FontStyle.italic,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                job.location,
                                style: const pw.TextStyle(
                                  fontSize: 12, // Increased from 10 to 12
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8), // Increased from 6 to 8
                          pw.Text(
                            job.description,
                            style: const pw.TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    )),

                pw.SizedBox(height: 24), // Increased from 16 to 24

                // Education
                pw.Text(
                  'EDUCATION',
                  style: pw.TextStyle(
                    fontSize: 16, // Increased from 14 to 16
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Divider(
                    thickness: 1,
                    color: PdfColors.grey400), // Increased thickness to 1
                pw.SizedBox(height: 8), // Increased from 6 to 8
                ...data.education.map((edu) => pw.Padding(
                      padding: const pw.EdgeInsets.only(
                          bottom: 16), // Increased from 14 to 16
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  edu.title,
                                  style: pw.TextStyle(
                                    fontSize: 14, // Increased from 12 to 14
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                '${edu.startDate} - ${edu.endDate}',
                                style: const pw.TextStyle(
                                  fontSize: 12, // Increased from 10 to 12
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4), // Increased from 2 to 4
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  edu.school,
                                  style: pw.TextStyle(
                                    fontSize: 12, // Increased from 10 to 12
                                    fontStyle: pw.FontStyle.italic,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Text(
                                edu.location,
                                style: const pw.TextStyle(
                                  fontSize: 12, // Increased from 10 to 12
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4), // Increased from 2 to 4
                          pw.Text(
                            edu.level,
                            style: const pw.TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                    )),

                pw.SizedBox(height: 24), // Increased from 16 to 24

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
                              fontSize: 16, // Increased from 14 to 16
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Divider(
                              thickness: 1,
                              color: PdfColors
                                  .grey400), // Increased thickness to 1
                          pw.SizedBox(height: 8), // Increased from 6 to 8
                          // Changed to Wrap with spacing
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.skills
                                .map((skill) => pw.Text(
                                      '• $skill',
                                      style: const pw.TextStyle(
                                        fontSize: 12, // Increased from 10 to 12
                                        color: PdfColors.black,
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
                              fontSize: 16, // Increased from 14 to 16
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Divider(
                              thickness: 1,
                              color: PdfColors
                                  .grey400), // Increased thickness to 1
                          pw.SizedBox(height: 8), // Increased from 6 to 8
                          // Changed to Wrap with spacing
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.languages
                                .map((language) => pw.Text(
                                      '• $language',
                                      style: const pw.TextStyle(
                                        fontSize: 12, // Increased from 10 to 12
                                        color: PdfColors.black,
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
            padding: const pw.EdgeInsets.all(24),
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
                        width: 80,
                        height: 80,
                        margin: const pw.EdgeInsets.only(right: 20),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border:
                              pw.Border.all(color: PdfColors.white, width: 2),
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
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            data.personalInfo.role,
                            style: const pw.TextStyle(
                              fontSize: 18,
                              color: PdfColors.grey200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Divider(
                    color: PdfColors.grey400, thickness: 1), // Added divider
                pw.SizedBox(height: 16),

                // Contact info in row
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 16,
                            height: 16,
                            margin: const pw.EdgeInsets.only(right: 8),
                            child: pw.Center(
                              child: pw.Text(
                                '✉',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            data.personalInfo.email,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey200,
                            ),
                            // overflow: pw.TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 16,
                            height: 16,
                            margin: const pw.EdgeInsets.only(right: 8),
                            child: pw.Center(
                              child: pw.Text(
                                '✆',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            data.personalInfo.phone,
                            style: const pw.TextStyle(
                              fontSize: 12,
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
                            width: 16,
                            height: 16,
                            margin: const pw.EdgeInsets.only(right: 8),
                            child: pw.Center(
                              child: pw.Text(
                                '⌂',
                                style: const pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey200,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            '${data.personalInfo.city}, ${data.personalInfo.country}',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey200,
                            ),
                            // overflow: pw.TextOverflow.ellipsis,
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
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Professional Summary
                _buildPdfSectionHeader('SUMMARY'),
                pw.SizedBox(height: 12),
                // pw.Divider(color: Pdf, thickness: 1),
                pw.Text(
                  data.professionalSummary,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.black,
                    lineSpacing: 1.5,
                  ),
                ),

                pw.SizedBox(height: 24),

                // Experience
                _buildPdfSectionHeader('EXPERIENCE'),
                pw.SizedBox(height: 12),

                // Employment history items
                ...data.employmentHistory.map((job) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 16),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            job.jobTitle,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            '${job.employer} | ${job.location}',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.indigo700,
                            ),
                          ),
                          pw.Text(
                            '${job.startDate} - ${job.endDate}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            job.description,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.black,
                              lineSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )),

                pw.SizedBox(height: 24),

                // Education
                _buildPdfSectionHeader('Education'),
                pw.SizedBox(height: 12),

                // Education in a grid layout with wrapping
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: data.education
                      .map((edu) => pw.Container(
                            width:
                                250, // Set a fixed width for each education item
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  edu.title,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                  // overflow: pw.TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                pw.Text(
                                  edu.school,
                                  style: const pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.indigo700,
                                  ),
                                  // overflow: pw.TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                pw.Text(
                                  '${edu.startDate} - ${edu.endDate}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontStyle: pw.FontStyle.italic,
                                    color: PdfColors.black,
                                  ),
                                  // overflow: pw.TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                pw.Text(
                                  edu.level,
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.black,
                                  ),
                                  // overflow: pw.TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),

                pw.SizedBox(height: 24),

                // Skills and Languages in two columns
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Skills section
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Skills'),
                          pw.SizedBox(height: 12),
                          // Skills with tags
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.skills
                                .map((skill) => pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.indigo50,
                                        borderRadius: const pw.BorderRadius.all(
                                            pw.Radius.circular(16)),
                                      ),
                                      child: pw.Text(
                                        skill,
                                        style: const pw.TextStyle(
                                          fontSize: 12,
                                          color: PdfColors.indigo700,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),

                    // Languages section without progress bars (matching the interface template)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfSectionHeader('Languages'),
                          pw.SizedBox(height: 12),
                          // Languages without visual bars
                          ...data.languages
                              .map((language) => pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        language,
                                        style: pw.TextStyle(
                                          fontSize: 12,
                                          fontWeight: pw.FontWeight.normal,
                                          color: PdfColors.black,
                                        ),
                                      ),
                                      pw.SizedBox(height: 12),
                                    ],
                                  ))
                              .toList(),
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

// Update the section header method to match the interface styling
  // static pw.Widget _buildPdfSectionHeader(String title) {
  //   return pw.Container(
  //     child: pw.Text(
  //       title,
  //       style: pw.TextStyle(
  //         fontSize: 14,
  //         fontWeight: pw.FontWeight.bold,
  //         color: PdfColors.indigo800,
  //       ),
  //     ),
  //   );
  // }

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
  }}

