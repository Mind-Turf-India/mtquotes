// Modify the Step3Screen class
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_builder_manager.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_selection.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';

class Step3Screen extends BaseStepScreen {
  final Step1Data step1Data;
  final Step2Data step2Data;

  const Step3Screen({
    Key? key,
    required this.step1Data,
    required this.step2Data,
  }) : super(key: key, currentStep: 3);

  @override
  State<Step3Screen> createState() => _Step3ScreenState();
}

class _Step3ScreenState extends BaseStepScreenState<Step3Screen> {
  // Controllers for skills
  final List<TextEditingController> _skillControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController()
  ];

  // Controllers for languages
  final List<TextEditingController> _languageControllers = [
    TextEditingController()
  ];

  // Selected template
  String _selectedTemplate = 'modern'; // Default template

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _skillControllers) {
      controller.dispose();
    }
    for (var controller in _languageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to add a new skill field
  void _addSkill() {
    setState(() {
      _skillControllers.add(TextEditingController());
    });
  }

  // Function to add a new language field
  void _addLanguage() {
    setState(() {
      _languageControllers.add(TextEditingController());
    });
  }

  // Function to select template
  void _selectTemplate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeSelectionScreen(
          onTemplateSelected: (template) {
            setState(() {
              _selectedTemplate = template;
            });
          },
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedTemplate = result;
      });
    }
  }

  // Function to create resume

  void _createResume() async {
    if (formKey.currentState!.validate()) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating your resume...'),
              ],
            ),
          ),
        );

        // Collect data from Step 1 (Personal Details & Education)
        final step1Data = {
          'role': widget.step1Data.role,
          'firstName': widget.step1Data.firstName,
          'lastName': widget.step1Data.lastName,
          'email': widget.step1Data.email,
          'phone': widget.step1Data.phone,
          'address': widget.step1Data.address,
          'city': widget.step1Data.city,
          'country': widget.step1Data.country,
          'postalCode': widget.step1Data.postalCode,
          'profileImagePath': widget.step1Data.profileImagePath,
          'education': widget.step1Data.education.map((edu) => {
            'title': edu.title,
            'school': edu.school,
            'level': edu.level,
            'startDate': edu.startDate,
            'endDate': edu.endDate,
            'location': edu.location,
            'description': edu.description,
          }).toList(),
        };

        // Collect data from Step 2 (Professional Summary & Employment)
        final step2Data = {
          'summary': widget.step2Data.summary,
          'employment': widget.step2Data.employment.map((job) => {
            'jobTitle': job.jobTitle,
            'employer': job.employer,
            'startDate': job.startDate,
            'endDate': job.endDate,
            'location': job.location,
            'description': job.description,
          }).toList(),
        };

        // Collect data from Step 3 (Skills & Languages)
        final step3Data = {
          'skills': _skillControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
          'languages': _languageControllers.map((c) => c.text).where((s) => s.isNotEmpty).toList(),
        };

        // Close loading dialog
        Navigator.pop(context);

        // Create resume manager
        final resumeManager = ResumeBuilderManager(context);

        // Finalize resume with collected data
        await resumeManager.finalizeResume(
          templateType: _selectedTemplate,
          step1Data: step1Data,
          step2Data: step2Data,
          step3Data: step3Data,
        );
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create resume: $e'),
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

  @override
  Widget buildStepContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skills Section
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Skills Input Fields
            for (int i = 0; i < _skillControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _skillControllers[i],
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Add skill ${i + 1}',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

            // Add Skill Button
            GestureDetector(
              onTap: _addSkill,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add one more skill',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Languages Section
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Language Input Fields
            for (int i = 0; i < _languageControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _languageControllers[i],
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Add language ${i + 1}',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

            // Add Language Button
            GestureDetector(
              onTap: _addLanguage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add one more language',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Template Selection Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a Resume Template',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose a professional design template for your resume.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectTemplate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.style, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Template: ${_selectedTemplate}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Create Resume Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _createResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Create Resume',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }}