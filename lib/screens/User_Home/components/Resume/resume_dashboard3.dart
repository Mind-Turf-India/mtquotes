import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard3.dart';

class Step3Screen extends BaseStepScreen {
  const Step3Screen({Key? key}) : super(key: key, currentStep: 3);
  
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
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // Show success dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Success'),
                          content: const Text('Your resume has been created successfully!'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Navigate back to the dashboard or home screen
                                Navigator.popUntil(context, (route) => route.isFirst);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
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
  }
}