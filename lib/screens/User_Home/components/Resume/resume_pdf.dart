import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class ResumePdfGenerator {
  // Generate PDF from Resume Data
  static Future<String> generatePdf(ResumeData data) async {
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

    // Add page based on template type
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

    // Save the PDF to temporary directory
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/${data.personalInfo.firstName}_${data.personalInfo.lastName}_Resume.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  // Build Modern Template
  static pw.Page _buildModernTemplate(
    ResumeData data,
    pw.ThemeData theme,
    pw.MemoryImage? profileImage,
  ) {
    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          children: [
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

            // Two column layout
            pw.Expanded(
              child: pw.Row(
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
            ),
          ],
        );
      },
    );
  }

  // Build Classic Template
  static pw.Page _buildClassicTemplate(
    ResumeData data,
    pw.ThemeData theme,
    pw.MemoryImage? profileImage,
  ) {
    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
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
                          image: pw.DecorationImage(
                            image: profileImage,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),

                    pw.Text(
                      '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
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

                    // Contact info in one line
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
              pw.Divider(thickness: 1),
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
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),
              ...data.employmentHistory.map((job) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                            pw.Text(
                              job.employer,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.black,
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
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),
              ...data.education.map((edu) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              edu.title,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
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
                            pw.Text(
                              edu.school,
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                color: PdfColors.black,
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
                        pw.Divider(thickness: 1),
                        pw.SizedBox(height: 6),
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: data.skills
                              .map((skill) => pw.Text(
                                    '• $skill',
                                    style: const pw.TextStyle(
                                      fontSize: 10,
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
                        pw.Divider(thickness: 1),
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
        );
      },
    );
  }

  // Build Business Template
  static pw.Page _buildBusinessTemplate(
    ResumeData data,
    pw.ThemeData theme,
    pw.MemoryImage? profileImage,
  ) {
    return pw.Page(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with name, role and contact info
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              color: PdfColors.indigo800,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Profile and name row
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
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
                            pw.SizedBox(height: 6),
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

                  pw.SizedBox(height: 12),

                  // Contact info in two columns
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 16,
                                  height: 16,
                                  margin: const pw.EdgeInsets.only(right: 6),
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
                                    fontSize: 10,
                                    color: PdfColors.grey200,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 16,
                                  height: 16,
                                  margin: const pw.EdgeInsets.only(right: 6),
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
                                    fontSize: 10,
                                    color: PdfColors.grey200,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 16,
                                  height: 16,
                                  margin: const pw.EdgeInsets.only(right: 6),
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
                                    fontSize: 10,
                                    color: PdfColors.grey200,
                                  ),
                                ),
                              ],
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
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Professional Summary
                    _buildPdfSectionHeader('Professional Summary'),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      data.professionalSummary,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Experience
                    _buildPdfSectionHeader('Professional Experience'),
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
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Divider(),
                            ],
                          ),
                        )),

                    // Education
                    _buildPdfSectionHeader('Education'),
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
                              pw.Text(
                                '${edu.school} | ${edu.level}',
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.indigo700,
                                ),
                              ),
                              pw.Text(
                                '${edu.startDate} - ${edu.endDate} | ${edu.location}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontStyle: pw.FontStyle.italic,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Divider(),
                            ],
                          ),
                        )),

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
                              pw.Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: data.skills
                                    .map((skill) => pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: pw.BoxDecoration(
                                            color: PdfColors.indigo50,
                                            borderRadius:
                                                const pw.BorderRadius.all(
                                              pw.Radius.circular(12),
                                            ),
                                          ),
                                          child: pw.Text(
                                            skill,
                                            style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: PdfColors.indigo700,
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
                              _buildPdfSectionHeader('Languages'),
                              pw.SizedBox(height: 10),
                              ...data.languages.map((language) => pw.Padding(
                                    padding:
                                        const pw.EdgeInsets.only(bottom: 6),
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
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
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}
