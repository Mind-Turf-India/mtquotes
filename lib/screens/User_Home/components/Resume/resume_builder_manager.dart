import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_preview.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_service.dart';

class ResumeBuilderManager {
  final BuildContext context;
  final ResumeService _resumeService = ResumeService();

  ResumeBuilderManager(this.context);

  // Collect data from all steps and create a resume
  Future<ResumeData> collectAndCreateResume({
    required String templateType,
    required Map<String, dynamic> step1Data,
    required Map<String, dynamic> step2Data,
    required Map<String, dynamic> step3Data,
  }) async {
    // Process Personal Info (Step 1)
    final personalInfo = PersonalInfo(
      role: step1Data['role'] ?? '',
      firstName: step1Data['firstName'] ?? '',
      lastName: step1Data['lastName'] ?? '',
      email: step1Data['email'] ?? '',
      phone: step1Data['phone'] ?? '',
      address: step1Data['address'] ?? '',
      city: step1Data['city'] ?? '',
      country: step1Data['country'] ?? '',
      postalCode: step1Data['postalCode'] ?? '',
      profileImagePath: step1Data['profileImagePath'],
    );

    // Process Education (Step 1)
    List<Education> education = [];
    List<Map<String, dynamic>> educationList = step1Data['education'] ?? [];

    for (var edu in educationList) {
      education.add(Education(
        title: edu['title'] ?? '',
        school: edu['school'] ?? '',
        level: edu['level'] ?? '',
        startDate: edu['startDate'] ?? '',
        endDate: edu['endDate'] ?? '',
        location: edu['location'] ?? '',
        description: edu['description'] ?? '',
      ));
    }

    // Process Professional Summary (Step 2)
    final String professionalSummary = step2Data['summary'] ?? '';

    // Process Employment History (Step 2)
    List<Employment> employmentHistory = [];
    List<Map<String, dynamic>> employmentList = step2Data['employment'] ?? [];

    for (var job in employmentList) {
      employmentHistory.add(Employment(
        jobTitle: job['jobTitle'] ?? '',
        employer: job['employer'] ?? '',
        startDate: job['startDate'] ?? '',
        endDate: job['endDate'] ?? '',
        location: job['location'] ?? '',
        description: job['description'] ?? '',
      ));
    }

    // Process Skills and Languages (Step 3)
    List<String> skills = step3Data['skills'] ?? [];
    List<String> languages = step3Data['languages'] ?? [];

    // Create ResumeData object
    final resumeData = ResumeData(
      userId: _resumeService.userId,
      templateType: templateType,
      personalInfo: personalInfo,
      education: education,
      professionalSummary: professionalSummary,
      employmentHistory: employmentHistory,
      skills: skills,
      languages: languages,
    );

    // Save to Firebase
    final resumeId = await _resumeService.saveResume(resumeData);

    return resumeData;
  }

  // Show resume preview
  void showResumePreview(ResumeData resumeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumePreviewScreen(resumeData: resumeData),
      ),
    );
  }

  // Handle final step submission with direct data
  Future<void> finalizeResume({
    required String templateType,
    required Map<String, dynamic> step1Data,
    required Map<String, dynamic> step2Data,
    required Map<String, dynamic> step3Data,
  }) async {
    try {
      // Create and save resume with provided data
      final resumeData = await collectAndCreateResume(
        templateType: templateType,
        step1Data: step1Data,
        step2Data: step2Data,
        step3Data: step3Data,
      );

      // Show preview
      showResumePreview(resumeData);
    } catch (e) {
      print('Error finalizing resume: $e');

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to finalize resume: $e'),
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
}