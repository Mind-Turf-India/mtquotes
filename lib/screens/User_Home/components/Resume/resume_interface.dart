import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';

// Template interface with improved signature for handling content size
abstract class ResumeTemplate {
  Widget buildTemplate(
    ResumeData data, {
    bool isPreview = false,

    double? maxWidth,
  });

  String get templateName;
}
Widget buildProfileImage(String? imagePath, {double size = 80.0, Color borderColor = Colors.white}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Icon(Icons.person, color: Colors.grey[600], size: size * 0.6),
      );
    }
    
    // Check if it's a Firebase URL (starts with http or https)
    if (imagePath.startsWith('http')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          image: DecorationImage(
            image: NetworkImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Local file path
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          image: DecorationImage(
            image: FileImage(File(imagePath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }



// Modern Template with modern styling
// Horizontal Modern Template with modern styling
// Horizontal Modern Template with modern styling and circular avatar
class ModernTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Modern';

  @override
  Widget buildTemplate(ResumeData data, {bool isPreview = false,double? maxWidth}) {
    return Container(
      width: isPreview ? 400 : 595, // A4 width in points
      height: isPreview ? 560 : 842, // A4 height in points
      color: Colors.white,
      child: Column(
        children: [
          // Header with name and role
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.blueGrey[800],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image if available
                 if (data.personalInfo.profileImagePath != null)
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: buildProfileImage(
                      data.personalInfo.profileImagePath,
                      size: 80,
                      borderColor: Colors.white,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.personalInfo.role,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Two column layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left sidebar with contact info, skills, and languages
                Container(
                  width: isPreview ? 120 : 180,
                  color: Colors.blueGrey[50],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact section
                      const Text(
                        'CONTACT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      Text(
                        data.personalInfo.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone
                      Text(
                        data.personalInfo.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Address
                      Text(
                        [
                          data.personalInfo.address,
                          if (data.personalInfo.city.isNotEmpty || data.personalInfo.country.isNotEmpty)
                            '${data.personalInfo.city}, ${data.personalInfo.country}',
                          data.personalInfo.postalCode,
                        ].where((s) => s.isNotEmpty).join('\n'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Skills section
                      const Text(
                        'SKILLS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.skills.map((skill) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          )),

                      const SizedBox(height: 24),

                      // Languages section
                      const Text(
                        'LANGUAGES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...data.languages.map((language) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              language,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                // Main content with summary, experience, and education
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Professional Summary
                        const Text(
                          'PROFESSIONAL SUMMARY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data.professionalSummary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Work Experience
                        const Text(
                          'EXPERIENCE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.employmentHistory.map((job) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (job.employer.isNotEmpty) job.employer,
                                      if (job.location.isNotEmpty) job.location,
                                      if (job.startDate.isNotEmpty || job.endDate.isNotEmpty)
                                        '${job.startDate} - ${job.endDate}',
                                    ].where((s) => s.isNotEmpty).join(' | '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (job.description.isNotEmpty)
                                    Text(
                                      job.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
                              ),
                            )),

                        const SizedBox(height: 24),

                        // Education
                        const Text(
                          'EDUCATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...data.education.map((edu) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    edu.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (edu.school.isNotEmpty) edu.school,
                                      if (edu.level.isNotEmpty) edu.level,
                                      if (edu.startDate.isNotEmpty || edu.endDate.isNotEmpty)
                                        '${edu.startDate} - ${edu.endDate}',
                                    ].where((s) => s.isNotEmpty).join(' | '),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (edu.description.isNotEmpty)
                                    Text(
                                      edu.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
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
      ),
    );
  }
}// Classic Template with traditional styling
class ClassicTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Classic';

  @override
  Widget buildTemplate(
    ResumeData data, {
    bool isPreview = false,
    double? maxWidth,
  }) {
    final contentWidth =
        maxWidth ?? (isPreview ? 400 : 595); // Default to A4 width

    return Container(
      width: contentWidth,
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min to fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and contact info
          Center(
            child: Column(
              children: [
                // Profile image if available
                if (data.personalInfo.profileImagePath != null)
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 3),
                      image: DecorationImage(
                        image: FileImage(
                            File(data.personalInfo.profileImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                Text(
                  '${data.personalInfo.firstName} ${data.personalInfo.lastName}'
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  data.personalInfo.role,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Contact info using Wrap to handle overflow
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8, // space between items
                  runSpacing: 8, // space between rows
                  children: [
                    Text(
                      data.personalInfo.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.black54)),
                    Text(
                      data.personalInfo.phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.black54)),
                    Text(
                      '${data.personalInfo.city}, ${data.personalInfo.country}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(thickness: 1),
          const SizedBox(height: 16),

          // Professional Summary
          const Text(
            'SUMMARY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              Text(
                data.professionalSummary,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Experience
          const Text(
            'EXPERIENCE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 8),

          // Employment items
          ...data.employmentHistory.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job title and dates row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.jobTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${job.startDate} - ${job.endDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Employer and location row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.employer,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          job.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description with wrap for text overflow
                    Wrap(
                      children: [
                        Text(
                          job.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Education
          const Text(
            'EDUCATION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 8),

          // Education items
          ...data.education.map((edu) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Education title and dates row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            edu.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          '${edu.startDate} - ${edu.endDate}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // School and location row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            edu.school,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          edu.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Level text
                    Text(
                      edu.level,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),

                    // Description with wrap for text overflow
                    if (edu.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          children: [
                            Text(
                              edu.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Skills and Languages in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skills section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKILLS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    const SizedBox(height: 8),
                    // Use Wrap for skills to handle overflow
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.skills
                          .map((skill) => Text(
                                '• $skill',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Languages section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LANGUAGES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    const SizedBox(height: 8),
                    // Use Wrap for languages to handle overflow
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.languages
                          .map((language) => Text(
                                '• $language',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
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
  }
}

// Business Template with corporate styling
class BusinessTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Business';

  @override
  Widget buildTemplate(
    ResumeData data, {
    bool isPreview = false,
    double? maxWidth,
  }) {
    final contentWidth =
        maxWidth ?? (isPreview ? 400 : 595); // Default to A4 width

    return SingleChildScrollView(
      physics: isPreview ? const NeverScrollableScrollPhysics() : null,
      child: Container(
        width: contentWidth,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to fit content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name, role and contact info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.indigo[800],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image and name in row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile image if available
                      if (data.personalInfo.profileImagePath != null)
                         Container(
                          margin: const EdgeInsets.only(right: 20),
                          child: buildProfileImage(
                            data.personalInfo.profileImagePath,
                            size: 80,
                            borderColor: Colors.white,
                          ),
                        ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.personalInfo.role,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.indigo[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),

                  // Contact info in row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.email,
                                size: 16, color: Colors.indigo[100]),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                data.personalInfo.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo[100],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Colors.indigo[100]),
                            const SizedBox(width: 8),
                            Text(
                              data.personalInfo.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.indigo[100]),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${data.personalInfo.city}, ${data.personalInfo.country}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo[100],
                                ),
                                overflow: TextOverflow.ellipsis,
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Professional Summary
                  _buildSectionHeader('Professional Summary'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data.professionalSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Experience
                  _buildSectionHeader('Professional Experience'),
                  const SizedBox(height: 12),

                  // Employment history items
                  ...data.employmentHistory.map((job) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          // border: Border.left(
                          //   color: Colors.indigo[800]!,
                          //   width: 3,
                          // ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.jobTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${job.employer} | ${job.location}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo[700],
                              ),
                            ),
                            Text(
                              '${job.startDate} - ${job.endDate}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              children: [
                                Text(
                                  job.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Education
                  _buildSectionHeader('Education'),
                  const SizedBox(height: 12),

                  // Education items in grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: data.education.length,
                    itemBuilder: (context, index) {
                      final edu = data.education[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              edu.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              edu.school,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${edu.startDate} - ${edu.endDate}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              edu.level,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Skills and Languages in two columns with visual styling
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skills section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Skills'),
                            const SizedBox(height: 12),
                            // Use Wrap with skill tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: data.skills
                                  .map((skill) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          skill,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.indigo[700],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Languages section with progress indicators
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Languages'),
                            const SizedBox(height: 12),
                            // Languages with visual bars
                            ...data.languages
                                .map((language) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          language,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 4,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                          child: FractionallySizedBox(
                                            widthFactor: 0.8,
                                            // Default 80% proficiency
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.indigo[700],
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  // Helper method for section headers
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[800],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.indigo[800],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// Template Factory
class TemplateFactory {
  static ResumeTemplate getTemplate(String templateType) {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return ModernTemplate();
      case 'classic':
        return ClassicTemplate();
        
      case 'business':
        return BusinessTemplate();
      default:
        return ModernTemplate(); // Default to modern if unknown template type
    }
  }
}
