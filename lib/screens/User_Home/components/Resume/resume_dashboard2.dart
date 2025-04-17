import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard3.dart';

class Step2Screen extends StatefulWidget {
  const Step2Screen({Key? key}) : super(key: key);

  @override
  State<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends State<Step2Screen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for date fields
  final List<TextEditingController> _startDateControllers = [TextEditingController()];
  final List<TextEditingController> _endDateControllers = [TextEditingController()];
  final List<TextEditingController> _jobTitleControllers = [TextEditingController()];
  final List<TextEditingController> _employerControllers = [TextEditingController()];
  final List<TextEditingController> _locationControllers = [TextEditingController()];
  final List<TextEditingController> _descriptionControllers = [TextEditingController()];
  
  // List to track employment blocks
  final List<Widget> _employmentBlocks = [];
  
  // Text controller for professional summary
  final TextEditingController _summaryController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Add initial employment block
    _employmentBlocks.add(_buildEmploymentBlock(0));
  }
  
  @override
  void dispose() {
    // Dispose all controllers
    _summaryController.dispose();
    for (var controller in _startDateControllers) {
      controller.dispose();
    }
    for (var controller in _endDateControllers) {
      controller.dispose();
    }
    for (var controller in _jobTitleControllers) {
      controller.dispose();
    }
    for (var controller in _employerControllers) {
      controller.dispose();
    }
    for (var controller in _locationControllers) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to show date picker and update the text field
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }
  
  // Function to add a new employment block
  void _addEmploymentBlock() {
    setState(() {
      final int index = _employmentBlocks.length;
      _startDateControllers.add(TextEditingController());
      _endDateControllers.add(TextEditingController());
      _jobTitleControllers.add(TextEditingController());
      _employerControllers.add(TextEditingController());
      _locationControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _employmentBlocks.add(_buildEmploymentBlock(index));
    });
  }
  
  // Function to remove an employment block
  void _removeEmploymentBlock(int index) {
    if (_employmentBlocks.length > 1) {
      setState(() {
        _employmentBlocks.removeAt(index);
        _startDateControllers.removeAt(index);
        _endDateControllers.removeAt(index);
        _jobTitleControllers.removeAt(index);
        _employerControllers.removeAt(index);
        _locationControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
      });
    }
  }
  
  // Build a single employment block
  Widget _buildEmploymentBlock(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with expand/collapse and delete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add here...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        // Toggle collapse/expand (would implement state for this)
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeEmploymentBlock(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Employment details form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Job Title and Employer
                Row(
                  children: [
                    // Job Title
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _jobTitleControllers[index],
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Job Title',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Employer
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _employerControllers[index],
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Employer',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Start Date and End Date
                Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _startDateControllers[index],
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'Start Date',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                              onPressed: () => _selectDate(context, _startDateControllers[index]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // End Date
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _endDateControllers[index],
                                readOnly: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: const InputDecoration(
                                  hintText: 'End Date',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                              onPressed: () => _selectDate(context, _endDateControllers[index]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _locationControllers[index],
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Location',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _descriptionControllers[index],
                    style: const TextStyle(color: Colors.black),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Description of your role in 100 words...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  // Breadcrumb widget for Step 2
  Widget _buildBreadcrumb(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Step 1',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          const Text(
            'Step 2',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Step3Screen()),
              );
            },
            child: const Text(
              'Step 3',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Add the breadcrumb navigation
          _buildBreadcrumb(context),
          
          // Content goes in a scrollable view
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professional Summary Section
                    const Text(
                      'Professional Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Professional Summary Text Area
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _summaryController,
                        style: const TextStyle(color: Colors.black),
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Write here in 100 words...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Employment History Section
                    const Text(
                      'Employment History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Dynamic Employment Blocks
                    ...List.generate(_employmentBlocks.length, (index) => _employmentBlocks[index]),
                    
                    // Add one more employment button
                    GestureDetector(
                      onTap: _addEmploymentBlock,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add one more employment',
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
                    
                    const SizedBox(height: 30),
                    
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Navigate to Step3Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  Step3Screen()),
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
                          'Next',
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
            ),
          ),
        ],
      ),
    );
  }
}
