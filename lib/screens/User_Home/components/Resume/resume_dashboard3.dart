import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_builder_manager.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_preview.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_selection.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';

class Step3Screen extends BaseStepScreen {
  final Step1Data step1Data;
  final Step2Data step2Data;
  final String resumeId; // Changed from String? to String (required)

  const Step3Screen({
    Key? key,
    required this.step1Data,
    required this.step2Data,
    required this.resumeId, // Made resumeId required
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

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Fetch existing resume data when the screen initializes
    _fetchResumeData();
  }

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

  Future<void> _fetchResumeData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Format user email for document ID (replace . with _)
      final String userId = currentUser.email!.replaceAll('.', '_');

      // Fetch resume data using the resumeId passed from previous screen
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc(widget.resumeId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // Populate skills if available
        if (data.containsKey('skills') && data['skills'] is List) {
          final skills = List<String>.from(data['skills']);

          // Clear existing controllers and create new ones for each skill
          for (var controller in _skillControllers) {
            controller.dispose();
          }
          _skillControllers.clear();

          if (skills.isNotEmpty) {
            for (var skill in skills) {
              final controller = TextEditingController(text: skill);
              _skillControllers.add(controller);
            }
          } else {
            // Add default empty controllers if no skills found
            _skillControllers.add(TextEditingController());
            _skillControllers.add(TextEditingController());
            _skillControllers.add(TextEditingController());
          }
        }

        // Populate languages if available
        if (data.containsKey('languages') && data['languages'] is List) {
          final languages = List<String>.from(data['languages']);

          // Clear existing controllers and create new ones for each language
          for (var controller in _languageControllers) {
            controller.dispose();
          }
          _languageControllers.clear();

          if (languages.isNotEmpty) {
            for (var language in languages) {
              final controller = TextEditingController(text: language);
              _languageControllers.add(controller);
            }
          } else {
            // Add default empty controller if no languages found
            _languageControllers.add(TextEditingController());
          }
        }

        // Set selected template if available
        if (data.containsKey('templateType') && data['templateType'] is String) {
          setState(() {
            _selectedTemplate = data['templateType'];
          });
        }
      }

      setState(() {
        _isDataLoaded = true;
      });

    } catch (e) {
      // Handle any errors
      print('Error fetching resume data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  // UPDATED: Function to save resume data to Firebase
  // This now simply updates the existing document rather than creating a new one
  // UPDATED: Function to save resume data to Firebase (only updates existing document)
  Future<void> _saveResumeToFirebase() async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Format user email for document ID (replace . with _)
      final String userId = currentUser.email!.replaceAll('.', '_');

      // Collect data from Step 3
      final List<String> skills = _skillControllers
          .map((c) => c.text)
          .where((s) => s.isNotEmpty)
          .toList();

      final List<String> languages = _languageControllers
          .map((c) => c.text)
          .where((s) => s.isNotEmpty)
          .toList();

      // Create a map with just the fields we want to update
      final Map<String, dynamic> updateData = {
        'templateType': _selectedTemplate,
        'skills': skills,
        'languages': languages,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update the existing document with the new skills and languages data
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('resume')
          .doc(widget.resumeId) // Use the same resumeId passed from Step2
          .update(updateData);

    } catch (e) {
      throw Exception('Failed to save resume: $e');
    }
  }

  // UPDATED: Function to create resume
  void _createResume() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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

        // Save the skills and languages data to the existing document without creating a new doc
        await _saveResumeToFirebase();

        // Get current user
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Format user email for document ID (replace . with _)
        final String userId = currentUser.email!.replaceAll('.', '_');

        // Fetch the complete resume data from Firestore using the existing resumeId
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('resume')
            .doc(widget.resumeId)
            .get();

        if (!docSnapshot.exists) {
          throw Exception('Resume not found');
        }

        // Convert the document data to a ResumeData object
        final resumeData = ResumeData.fromMap(docSnapshot.data()!);

        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Navigate to the ResumePreviewScreen with the complete data
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumePreviewScreen(
              resumeData: resumeData,
              resumeId: widget.resumeId,
            ),
          ),
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
      } finally {
        setState(() {
          _isLoading = false;
        });
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
                onPressed: _isLoading ? null : _createResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
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
  }

  // Override to remove breadcrumb navigation
  @override
  Widget buildStepIndicator() {
    // Return an empty container to remove the breadcrumb navigation
    return Container();
  }
}