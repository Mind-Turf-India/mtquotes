import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';

// Template interface
abstract class ResumeTemplate {
  Widget buildTemplate(ResumeData data, {bool isPreview = false});

  String get templateName;
}

// Modern Template
class ModernTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Modern';

  @override
  Widget buildTemplate(ResumeData data, {bool isPreview = false}) {
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
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: FileImage(
                            File(data.personalInfo.profileImagePath!)),
                        fit: BoxFit.cover,
                      ),
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
                // Left sidebar with contact info and skills
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
                        '${data.personalInfo.address}\n${data.personalInfo.city}, ${data.personalInfo.country}\n${data.personalInfo.postalCode}',
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
                                    '${job.employer} | ${job.location} | ${job.startDate} - ${job.endDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
                                    '${edu.school} | ${edu.level} | ${edu.startDate} - ${edu.endDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
}

// Classic Template
class ClassicTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Classic';

  @override
  Widget buildTemplate(ResumeData data, {bool isPreview = false}) {
    return Container(
        width: isPreview ? 400 : 595,
        // A4 width in points
        height: isPreview ? 560 : 842,
        // A4 height in points
        color: Colors.white,
        padding: const EdgeInsets.all(40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header with name and contact info
          Center(
            child: Column(
              children: [
                Text(
                  '${data.personalInfo.firstName} ${data.personalInfo.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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

                // Contact info in one line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
          Text(
            data.professionalSummary,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
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
          ...data.employmentHistory.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job.jobTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job.employer,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
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
                      '${edu.school} | ${edu.level} | ${edu.startDate} - ${edu.endDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
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
        ]));
  }
}

// Business Template
class BusinessTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Business';

  @override
  Widget buildTemplate(ResumeData data, {bool isPreview = false}) {
    return Container(
      width: isPreview ? 400 : 595, // A4 width in points
      height: isPreview ? 560 : 842, // A4 height in points
      color: Colors.white,
      child: Column(
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
                const SizedBox(height: 16),

                // Contact info in two columns
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.email,
                                  size: 14, color: Colors.indigo[100]),
                              const SizedBox(width: 8),
                              Text(
                                data.personalInfo.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo[100],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 14, color: Colors.indigo[100]),
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.indigo[100]),
                              const SizedBox(width: 8),
                              Text(
                                '${data.personalInfo.city}, ${data.personalInfo.country}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo[100],
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Professional Summary
                  _buildSectionHeader('Professional Summary'),
                  const SizedBox(height: 12),
                  Text(
                    data.professionalSummary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Experience
                  _buildSectionHeader('Professional Experience'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    Text(
                                      job.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                  ],
                                ),
                              )),

                          // Education
                          _buildSectionHeader('Education'),
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
                                    Text(
                                      '${edu.school} | ${edu.level}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.indigo[700],
                                      ),
                                    ),
                                    Text(
                                      '${edu.startDate} - ${edu.endDate} | ${edu.location}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                  ],
                                ),
                              )),

                          // Skills and Languages
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
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: data.skills
                                          .map((skill) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
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

                              // Languages section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader('Languages'),
                                    const SizedBox(height: 12),
                                    ...data.languages.map((language) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
