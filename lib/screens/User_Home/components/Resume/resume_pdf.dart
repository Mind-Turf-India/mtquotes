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

    // Here's the corrected code with null safety fixes:

    if (saveToDownloads) {
      // Request storage permission
      await _requestStoragePermission();

      try {
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // For Android, use correct paths for different Android versions
          try {
            // Primary approach for Downloads directory
            downloadsDir = Directory('/storage/emulated/0/Download');

            // Check if directory exists and is accessible
            if (downloadsDir != null && !await downloadsDir.exists()) {
              // Try alternate common locations for Downloads
              final possibilities = [
                '/storage/emulated/0/Downloads',  // Some devices use this path
                '/sdcard/Download',               // Legacy path
                '/sdcard/Downloads'               // Another common path
              ];

              bool foundDir = false;
              for (final path in possibilities) {
                final dir = Directory(path);
                if (await dir.exists()) {
                  downloadsDir = dir;
                  foundDir = true;
                  break;
                }
              }

              // If still not found, try to get the external storage directory
              if (!foundDir) {
                final externalDir = await getExternalStorageDirectory();
                if (externalDir != null) {
                  // Navigate to root of external storage
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
                  newPath += "/Download";
                  downloadsDir = Directory(newPath);

                  // Create directory if it doesn't exist
                  if (!await downloadsDir.exists()) {
                    await downloadsDir.create(recursive: true);
                  }
                }
              }
            }
          } catch (e) {
            print("Error finding downloads directory: $e");
            // Last resort: fall back to app documents directory
            downloadsDir = await getApplicationDocumentsDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS, use the documents directory
          // iOS doesn't have a concept of a "Downloads" folder like Android
          downloadsDir = await getApplicationDocumentsDirectory();
        } else {
          // For other platforms, just use temp directory
          downloadsDir = await getTemporaryDirectory();
        }

        // Create a descriptive file name with timestamp to avoid conflicts
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final firstName = data.personalInfo.firstName.isNotEmpty
            ? data.personalInfo.firstName
            : "Resume";
        final lastName = data.personalInfo.lastName.isNotEmpty
            ? data.personalInfo.lastName
            : "";

        final fileName = 'Resume_${firstName}_${lastName}_$timestamp.pdf';

        // Make sure downloadsDir is not null before using it
        if (downloadsDir != null) {
          filePath = '${downloadsDir.path}/$fileName';
          print('Saving PDF to: $filePath');
        } else {
          // Fall back to temp directory if downloadsDir is null
          final tempDir = await getTemporaryDirectory();
          filePath = '${tempDir.path}/$fileName';
          print('Saving PDF to temp directory: $filePath');
        }
      } catch (e) {
        print('Error determining download path: $e');
        // If there's any error, fall back to temporary directory
        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filePath = '${dir.path}/VakyResume_${timestamp}.pdf';
      }
    } else {
      // Just save to temporary directory if not saving to downloads
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${dir.path}/VakyResume_${timestamp}.pdf';
    }

    // Save the PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // For Android 11+ (API 30+), we need additional handling to make the file visible
    // in the Downloads folder via Media Store
    if (Platform.isAndroid && saveToDownloads) {
      try {
        // This would be a good place to implement Media Store integration
        // For modern Android versions, simply writing to Download may not
        // make the file visible without proper Media Store integration
        print('PDF saved. For modern Android devices, additional Media Store integration may be needed.');
      } catch (e) {
        print('Note: File saved but might not be visible in gallery: $e');
      }
    }

    return filePath;
  }

  static Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version to determine which permissions to request
      // Android 10 (API 29) and below needs Storage permission
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        print('Storage permission status: $storageStatus');
      }

      // On Android 11+ (API 30+), we need MANAGE_EXTERNAL_STORAGE for direct Downloads access
      // Note: This is a special permission that users must grant in Settings
      try {
        var externalStatus = await Permission.manageExternalStorage.status;
        if (!externalStatus.isGranted) {
          externalStatus = await Permission.manageExternalStorage.request();
          print('External storage permission status: $externalStatus');
        }
      } catch (e) {
        // Ignore errors for older Android versions where this permission doesn't exist
        print('Note: ManageExternalStorage permission check failed, likely on older Android: $e');
      }
    }
  }

  // Helper function to check if there are valid skills
  static bool hasValidSkills(ResumeData data) {
    return data.skills.isNotEmpty &&
        data.skills.any((skill) => skill.trim().isNotEmpty);
  }

// Helper function to check if there are valid languages
  static bool hasValidLanguages(ResumeData data) {
    return data.languages.isNotEmpty &&
        data.languages.any((language) => language.trim().isNotEmpty);
  }

// Helper function to check if there is valid employment history
  static bool hasValidEmploymentHistory(ResumeData data) {
    return data.employmentHistory.isNotEmpty &&
        data.employmentHistory.any((job) =>
        job.jobTitle.trim().isNotEmpty ||
            job.employer.trim().isNotEmpty ||
            job.description.trim().isNotEmpty);
  }

// Helper function to check if there is valid education data
  static bool hasValidEducation(ResumeData data) {
    return data.education.isNotEmpty &&
        data.education.any((edu) =>
        edu.title.trim().isNotEmpty ||
            edu.school.trim().isNotEmpty);
  }

// Helper function to check if there is a valid summary
  static bool hasValidSummary(ResumeData data) {
    return data.professionalSummary.trim().isNotEmpty;
  }

  static List<Employment> getValidEmployment(ResumeData data) {
    return data.employmentHistory
        .where((job) =>
    job.jobTitle.trim().isNotEmpty ||
        job.employer.trim().isNotEmpty ||
        job.description.trim().isNotEmpty)
        .toList();
  }

// Helper function to filter valid education entries
  static List<Education> getValidEducation(ResumeData data) {
    return data.education
        .where((edu) =>
    edu.title.trim().isNotEmpty ||
        edu.school.trim().isNotEmpty)
        .toList();
  }

// Helper function to filter valid skills
  static List<String> getValidSkills(ResumeData data) {
    return data.skills
        .where((skill) => skill.trim().isNotEmpty)
        .toList();
  }

// Helper function to filter valid languages
  static List<String> getValidLanguages(ResumeData data) {
    return data.languages
        .where((language) => language.trim().isNotEmpty)
        .toList();
  }

  // Build Modern Template with MultiPage to handle overflow
  static pw.Page _buildModernTemplate(
      ResumeData data,
      pw.ThemeData theme,
      pw.MemoryImage? profileImage,
      ) {
    // Check if sections have valid data
    final bool hasSkills = hasValidSkills(data);
    final bool hasLanguages = hasValidLanguages(data);
    final bool hasEmploymentHistory = hasValidEmploymentHistory(data);
    final bool hasEducation = hasValidEducation(data);
    final bool hasSummary = hasValidSummary(data);

    // Get filtered valid entries
    final validJobs = getValidEmployment(data);
    final validEducation = getValidEducation(data);
    final validSkills = getValidSkills(data);
    final validLanguages = getValidLanguages(data);


    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          // Header (always shown) - No change needed here
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
                // Left sidebar with skills and languages - Only show if there are valid skills or languages
                if (hasSkills || hasLanguages)
                  pw.Container(
                    width: 150,
                    color: PdfColors.blueGrey50,
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Skills section - Only show if there are valid skills
                        if (hasSkills) ...[
                          pw.Text(
                            'SKILLS',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          ...validSkills.map((skill) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Text(
                              skill,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.black,
                              ),
                            ),
                          )),
                          if (hasLanguages) pw.SizedBox(height: 24),
                        ],

                        // Languages section - Only show if there are valid languages
                        if (hasLanguages) ...[
                          pw.Text(
                            'LANGUAGES',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          ...validLanguages.map((language) => pw.Padding(
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
                        // Professional Summary - Only show if there's a valid summary
                        if (hasSummary) ...[
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
                        ],

                        // Work Experience - Only show if there are valid jobs
                        if (hasEmploymentHistory && validJobs.isNotEmpty) ...[
                          pw.Text(
                            'EXPERIENCE',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          ...validJobs.map((job) => pw.Padding(
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
                          if (hasEducation && validEducation.isNotEmpty) pw.SizedBox(height: 20),
                        ],

                        // Education - Only show if there are valid education entries
                        if (hasEducation && validEducation.isNotEmpty) ...[
                          pw.Text(
                            'EDUCATION',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blueGrey,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          ...validEducation.map((edu) => pw.Padding(
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
                              ],
                            ),
                          )),
                        ],
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
    // Check if sections have valid data
    final bool hasSkills = hasValidSkills(data);
    final bool hasLanguages = hasValidLanguages(data);
    final bool hasEmploymentHistory = hasValidEmploymentHistory(data);
    final bool hasEducation = hasValidEducation(data);
    final bool hasSummary = hasValidSummary(data);

    // Get filtered valid entries
    final validJobs = getValidEmployment(data);
    final validEducation = getValidEducation(data);
    final validSkills = getValidSkills(data);
    final validLanguages = getValidLanguages(data);

    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          pw.Padding(
            padding: const pw.EdgeInsets.all(40),
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
                if (hasSummary) pw.SizedBox(height: 16),

                // Professional Summary - Only show if there is valid content
                if (hasSummary) ...[
                  pw.Text(
                    'SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Divider(thickness: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    data.professionalSummary,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],// Increased from 16 to 24

                // Experience
                if (hasEmploymentHistory && validJobs.isNotEmpty) ...[
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
        ...validJobs.map((job) => pw.Padding(
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
                  if (hasEducation && validEducation.isNotEmpty) pw.SizedBox(height: 16),
                ],



                // Education
        if (hasEducation && validEducation.isNotEmpty) ...[
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
                ...validEducation.map((edu) => pw.Padding(
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
          if (hasSkills || hasLanguages) pw.SizedBox(height: 16),
        ],


                // Skills and Languages
                if (hasSkills || hasLanguages)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Skills section - Only show if there are valid skills
                      if (hasSkills)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'SKILLS',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.Divider(thickness: 1, color: PdfColors.grey400),
                              pw.SizedBox(height: 8),
                              // Use validSkills instead of data.skills
                              pw.Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: validSkills
                                    .map((skill) => pw.Text(
                                  '• $skill',
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.black,
                                  ),
                                ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      if (hasSkills && hasLanguages) pw.SizedBox(width: 20),

                      // Languages section - Only show if there are valid languages
                      if (hasLanguages)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'LANGUAGES',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.Divider(thickness: 1, color: PdfColors.grey400),
                              pw.SizedBox(height: 8),
                              // Use validLanguages instead of data.languages
                              pw.Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: validLanguages
                                    .map((language) => pw.Text(
                                  '• $language',
                                  style: const pw.TextStyle(
                                    fontSize: 12,
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
    // Check if sections have valid data
    final bool hasSkills = hasValidSkills(data);
    final bool hasLanguages = hasValidLanguages(data);
    final bool hasEmploymentHistory = hasValidEmploymentHistory(data);
    final bool hasEducation = hasValidEducation(data);
    final bool hasSummary = hasValidSummary(data);

    // Get filtered valid entries
    final validJobs = getValidEmployment(data);
    final validEducation = getValidEducation(data);
    final validSkills = getValidSkills(data);
    final validLanguages = getValidLanguages(data);

    return pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) {
        return [
          // Header section (always shown) - No change needed
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
                // Professional Summary - Only show if there is valid content
                if (hasSummary) ...[
                  _buildPdfSectionHeader('SUMMARY'),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    data.professionalSummary,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.black,
                      lineSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],


                // Experience
                if (hasEmploymentHistory && validJobs.isNotEmpty) ...[
                _buildPdfSectionHeader('EXPERIENCE'),
                pw.SizedBox(height: 12),

                // Only use valid jobs
                ...validJobs.map((job) => pw.Container(
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
                  if (hasEducation && validEducation.isNotEmpty) pw.SizedBox(height: 24),
                ],


                // Education
        if (hasEducation && validEducation.isNotEmpty) ...[
        _buildPdfSectionHeader('Education'),
        pw.SizedBox(height: 12),

        // Education in a grid layout with wrapping - Use validEducation
        pw.Wrap(
        spacing: 16,
        runSpacing: 16,
        children: validEducation
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
          if (hasSkills || hasLanguages) pw.SizedBox(height: 24),
        ],


                // Skills and Languages in two columns
                if (hasSkills || hasLanguages)
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Skills section - Only show if there are valid skills
                      if (hasSkills)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfSectionHeader('Skills'),
                              pw.SizedBox(height: 12),
                              // Use validSkills for skills tags
                              pw.Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: validSkills
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
                      if (hasSkills && hasLanguages) pw.SizedBox(width: 24),

                    // Languages section without progress bars (matching the interface template)
                      if (hasLanguages)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildPdfSectionHeader('Languages'),
                              pw.SizedBox(height: 12),
                              // Use validLanguages for language list
                              ...validLanguages
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

