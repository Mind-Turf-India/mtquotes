import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';

abstract class ResumeTemplate {
  Widget buildTemplate(
    ResumeData data, {
    bool isPreview = false,
    double? maxWidth,
  });

  String get templateName;
}

Widget buildProfileImage(String? imagePath,
    {double size = 80.0, Color borderColor = Colors.white}) {
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

class ModernTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Modern';

  @override
  Widget buildTemplate(ResumeData data,
      {bool isPreview = false, double? maxWidth}) {
    final containerWidth = isPreview ? 400 : 595;
    final containerHeight = isPreview ? 560 : 842;

    final bool hasSkills = data.skills.isNotEmpty;
    final bool hasLanguages = data.languages.isNotEmpty;
    final bool hasEmploymentHistory = data.employmentHistory.isNotEmpty &&
        data.employmentHistory.any((job) =>
            job.jobTitle.trim().isNotEmpty ||
            job.employer.trim().isNotEmpty ||
            job.description.trim().isNotEmpty);
    final bool hasEducation = data.education.isNotEmpty;
    final bool hasSummary = data.professionalSummary.trim().isNotEmpty;

    return Container(
      width: containerWidth.toDouble(),
      height: containerHeight.toDouble(),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blueGrey[800],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.personalInfo.profileImagePath != null)
                      Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 20),
                        child: buildProfileImage(
                          data.personalInfo.profileImagePath,
                          size: 70,
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

                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            data.personalInfo.email,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            data.personalInfo.phone,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
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

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasSkills || hasLanguages)
                  Container(
                    width: isPreview ? 110 : 150,
                    color: Colors.blueGrey[50],
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSkills) ...[
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
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              )),
                          if (hasLanguages) const SizedBox(height: 24),
                        ],

                        if (hasLanguages) ...[
                          const Text(
                            'LANGUAGE',
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
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSummary) ...[
                          const Text(
                            'SUMMARY',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data.professionalSummary,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (hasEmploymentHistory) ...[
                          _buildSectionHeader('EXPERIENCE'),
                          const SizedBox(height: 12),

                          ...data.employmentHistory
                              .where((job) =>
                                  job.jobTitle.trim().isNotEmpty ||
                                  job.employer.trim().isNotEmpty ||
                                  job.description.trim().isNotEmpty)
                              .map((job) => Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.jobTitle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${job.employer} | ${job.location} | ${job.startDate} - ${job.endDate}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          job.description,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          if (hasEducation) const SizedBox(height: 24),
                        ],

                        if (hasEducation) ...[
                          const Text(
                            'EDUCATION',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...data.education.map((edu) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
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
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${edu.school} | ${edu.level} | ${edu.startDate} - ${edu.endDate}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
        ],
      ),
    );
  }
}

// Classic Template with traditional styling
class ClassicTemplate implements ResumeTemplate {
  @override
  String get templateName => 'Classic';

  @override
  Widget buildTemplate(
    ResumeData data, {
    bool isPreview = false,
    double? maxWidth,
  }) {
    final double containerWidth = maxWidth ?? (isPreview ? 400 : 595);
    final double containerHeight = isPreview ? 600 : 842;


    final bool hasSkills = data.skills.isNotEmpty &&
        data.skills.any((skill) => skill.trim().isNotEmpty);

    final bool hasLanguages = data.languages.isNotEmpty &&
        data.languages.any((lang) => lang.trim().isNotEmpty);

    final bool hasEmploymentHistory = data.employmentHistory.isNotEmpty &&
        data.employmentHistory.any((job) =>
            job.jobTitle.trim().isNotEmpty ||
            job.employer.trim().isNotEmpty ||
            job.description.trim().isNotEmpty);

    final bool hasEducation = data.education.isNotEmpty &&
        data.education.any((edu) =>
            edu.title.trim().isNotEmpty || edu.school.trim().isNotEmpty);

    final bool hasSummary = data.professionalSummary.trim().isNotEmpty;

    final List<Employment> validJobs = data.employmentHistory
        .where((job) =>
            job.jobTitle.trim().isNotEmpty ||
            job.employer.trim().isNotEmpty ||
            job.description.trim().isNotEmpty)
        .toList();

    final List<Education> validEducation = data.education
        .where((edu) =>
            edu.title.trim().isNotEmpty || edu.school.trim().isNotEmpty)
        .toList();

    return Container(
        width: containerWidth,
        height: isPreview ? containerHeight : null,
        color: Colors.white,
        padding: const EdgeInsets.all(40),
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  if (data.personalInfo.profileImagePath != null)
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: buildProfileImage(
                        data.personalInfo.profileImagePath,
                        size: 80,
                        borderColor: Colors.black,
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

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        data.personalInfo.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const Text(' | ',
                          style: TextStyle(color: Colors.black54)),
                      Text(
                        data.personalInfo.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const Text(' | ',
                          style: TextStyle(color: Colors.black54)),
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

            if (hasSummary) const SizedBox(height: 16),

            if (hasSummary) ...[
              const Text(
                'SUMMARY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 1),
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
            ],

            if (hasEmploymentHistory && validJobs.isNotEmpty) ...[
              const Text(
                'EXPERIENCE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 8),

              ...validJobs.map((job) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

              if (hasEducation && validEducation.isNotEmpty)
                const SizedBox(height: 10),
            ],

            if (hasEducation && validEducation.isNotEmpty) ...[
              const Text(
                'EDUCATION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 8),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      isPreview ? 120 : 200,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...validEducation.map((edu) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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

                                Text(
                                  edu.level,
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

              if (hasSkills || hasLanguages) const SizedBox(height: 16),
            ],

            if (hasSkills || hasLanguages)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasSkills)
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
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.skills
                                .where((skill) => skill.trim().isNotEmpty)
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
                  if (hasSkills && hasLanguages) const SizedBox(width: 20),

                  if (hasLanguages)
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
                          const Divider(thickness: 1),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.languages
                                .where((language) => language.trim().isNotEmpty)
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
        )));
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
    final double containerWidth = maxWidth ?? (isPreview ? 400 : 595);

    final bool hasSkills = data.skills.isNotEmpty &&
        data.skills.any((skill) => skill.trim().isNotEmpty);
    final bool hasLanguages = data.languages.isNotEmpty &&
        data.languages.any((lang) => lang.trim().isNotEmpty);
    final bool hasEmploymentHistory = data.employmentHistory.isNotEmpty &&
        data.employmentHistory.any((job) =>
        job.jobTitle.trim().isNotEmpty ||
            job.employer.trim().isNotEmpty ||
            job.description.trim().isNotEmpty);
    final bool hasEducation = data.education.isNotEmpty &&
        data.education.any((edu) =>
        edu.title.trim().isNotEmpty ||
            edu.school.trim().isNotEmpty);
    final bool hasSummary = data.professionalSummary.trim().isNotEmpty;

    final List<Employment> validJobs = data.employmentHistory
        .where((job) =>
    job.jobTitle.trim().isNotEmpty ||
        job.employer.trim().isNotEmpty ||
        job.description.trim().isNotEmpty)
        .toList();
    final List<Education> validEducation = data.education
        .where((edu) =>
    edu.title.trim().isNotEmpty ||
        edu.school.trim().isNotEmpty)
        .toList();

    return Container(
      width: containerWidth,
      color: Colors.white,
      child: SingleChildScrollView(
        physics: isPreview ? const NeverScrollableScrollPhysics() : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.indigo[800],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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

                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.indigo[100]),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.indigo[100]),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.indigo[100]),
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
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasSummary) ...[
                    _buildSectionHeader('SUMMARY'),
                    const SizedBox(height: 12),
                    Text(
                      data.professionalSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (hasEmploymentHistory && validJobs.isNotEmpty) ...[
                    _buildSectionHeader('EXPERIENCE'),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validJobs.length,
                      itemBuilder: (context, index) {
                        final job = validJobs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (hasEducation && validEducation.isNotEmpty) const SizedBox(height: 10),
                  ],

                  if (hasEducation && validEducation.isNotEmpty) ...[
                    _buildSectionHeader('Education'),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validEducation.length,
                      itemBuilder: (context, index) {
                        final edu = validEducation[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                              ),
                              Text(
                                edu.school,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.indigo[700],
                                ),
                              ),
                              Text(
                                '${edu.startDate} - ${edu.endDate} | ${edu.level}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (hasSkills || hasLanguages) const SizedBox(height: 16),
                  ],

                  if (hasSkills || hasLanguages) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSkills) ...[
                          _buildSectionHeader('Skills'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.skills
                                .where((skill) => skill.trim().isNotEmpty)
                                .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo[50],
                                borderRadius: BorderRadius.circular(16),
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
                          if (hasLanguages) const SizedBox(height: 16),
                        ],

                        if (hasLanguages) ...[
                          _buildSectionHeader('Languages'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: data.languages
                                .where((language) => language.trim().isNotEmpty)
                                .map((language) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                language,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.indigo[700],
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ],
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
