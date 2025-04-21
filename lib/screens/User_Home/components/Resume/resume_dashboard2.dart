import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard3.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';

import 'package:mtquotes/utils/app_colors.dart'; // Import app colors


class Step2Screen extends StatefulWidget {
  final Step1Data step1Data;
  final String resumeId;


  const Step2Screen({
    Key? key,
    required this.step1Data,
    required this.resumeId,
  }) : super(key: key);


  @override
  State<Step2Screen> createState() => _Step2ScreenState();
}


class _Step2ScreenState extends State<Step2Screen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = true; // Added to show loading state while fetching data
  bool isDarkMode = false; // Add dark mode tracking
  
  // Add this with your other state variables
  int _currentWordCount = 0;


  // Controllers for date fields
  final List<TextEditingController> _startDateControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _endDateControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _jobTitleControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _employerControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _locationControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _descriptionControllers = [
    TextEditingController()
  ];


  // List to track employment blocks
  final List<Widget> _employmentBlocks = [];


  // Text controller for professional summary
  final TextEditingController _summaryController = TextEditingController();


  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;


  @override
  void initState() {
    super.initState();
    // Add initial employment block
    _employmentBlocks.add(_buildEmploymentBlock(0));
    _getUserId();
    // Fetch existing data
    _fetchResumeData();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the theme mode
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }


  void _getUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      _userId = user.email?.replaceAll('.', '_');
    }
  }


  // New method to fetch resume data from Firebase
  Future<void> _fetchResumeData() async {
    if (_userId == null) {
      setState(() {
        _isLoadingData = false;
      });
      return;
    }


    try {
      DocumentSnapshot resumeDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('resume')
          .doc(widget.resumeId)
          .get();


      if (resumeDoc.exists) {
        Map<String, dynamic> data = resumeDoc.data() as Map<String, dynamic>;


        // Populate professional summary
        if (data.containsKey('professionalSummary')) {
          _summaryController.text = data['professionalSummary'] ?? '';
        }


        // Populate employment history
        if (data.containsKey('employmentHistory') &&
            data['employmentHistory'] is List) {
          List<dynamic> employmentHistory = data['employmentHistory'];


          // Clear existing controllers and blocks
          _startDateControllers.clear();
          _endDateControllers.clear();
          _jobTitleControllers.clear();
          _employerControllers.clear();
          _locationControllers.clear();
          _descriptionControllers.clear();
          _employmentBlocks.clear();


          // Create new controllers and blocks for each employment entry
          for (int i = 0; i < employmentHistory.length; i++) {
            Map<String, dynamic> job = employmentHistory[i];


            // Create controllers for this job
            TextEditingController startDateController =
                TextEditingController(text: job['startDate'] ?? '');
            TextEditingController endDateController =
                TextEditingController(text: job['endDate'] ?? '');
            TextEditingController jobTitleController =
                TextEditingController(text: job['jobTitle'] ?? '');
            TextEditingController employerController =
                TextEditingController(text: job['employer'] ?? '');
            TextEditingController locationController =
                TextEditingController(text: job['location'] ?? '');
            TextEditingController descriptionController =
                TextEditingController(text: job['description'] ?? '');


            // Add controllers to lists
            _startDateControllers.add(startDateController);
            _endDateControllers.add(endDateController);
            _jobTitleControllers.add(jobTitleController);
            _employerControllers.add(employerController);
            _locationControllers.add(locationController);
            _descriptionControllers.add(descriptionController);
          }


          // Build employment blocks after adding all controllers
          setState(() {
            // This ensures the UI is updated with new blocks
            for (int i = 0; i < employmentHistory.length; i++) {
              _employmentBlocks.add(_buildEmploymentBlock(i));
            }
          });


          // If no employment history was found, add a default block
          if (employmentHistory.isEmpty) {
            _startDateControllers.add(TextEditingController());
            _endDateControllers.add(TextEditingController());
            _jobTitleControllers.add(TextEditingController());
            _employerControllers.add(TextEditingController());
            _locationControllers.add(TextEditingController());
            _descriptionControllers.add(TextEditingController());


            setState(() {
              _employmentBlocks.add(_buildEmploymentBlock(0));
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching resume data: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
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
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: AppColors.getSurfaceColor(isDarkMode),
              onSurface: AppColors.getTextColor(isDarkMode),
            ),
          ),
          child: child!,
        );
      },
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
        color: isDarkMode ? AppColors.darkSurface : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with expand/collapse and delete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getDividerColor(isDarkMode),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employment History #${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.getIconColor(isDarkMode),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeEmploymentBlock(index),
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
                          color: AppColors.getSurfaceColor(isDarkMode),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _jobTitleControllers[index],
                          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                          decoration: InputDecoration(
                            hintText: 'Job Title',
                            hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),


                    // Employer
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(isDarkMode),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _employerControllers[index],
                          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                          decoration: InputDecoration(
                            hintText: 'Employer',
                            hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                          color: AppColors.getSurfaceColor(isDarkMode),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _startDateControllers[index],
                                readOnly: true,
                                style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                                decoration: InputDecoration(
                                  hintText: 'Start Date',
                                  hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: AppColors.getSecondaryTextColor(isDarkMode),
                                size: 20
                              ),
                              onPressed: () => _selectDate(
                                  context, _startDateControllers[index]),
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
                          color: AppColors.getSurfaceColor(isDarkMode),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _endDateControllers[index],
                                readOnly: true,
                                style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                                decoration: InputDecoration(
                                  hintText: 'End Date',
                                  hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: AppColors.getSecondaryTextColor(isDarkMode),
                                size: 20
                              ),
                              onPressed: () => _selectDate(
                                  context, _endDateControllers[index]),
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
                    color: AppColors.getSurfaceColor(isDarkMode),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _locationControllers[index],
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    decoration: InputDecoration(
                      hintText: 'Location',
                      hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                // Description
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDarkMode),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _descriptionControllers[index],
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Description of your role in 100 words...',
                      hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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


  // Breadcrumb widget for Step 2 (with disabled navigation for Step 3)
  Widget _buildBreadcrumb(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        border: Border(
          bottom: BorderSide(
            color: AppColors.getDividerColor(isDarkMode),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Only keeping back navigation
            },
            child: Text(
              'Step 1',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryTextColor(isDarkMode),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.getSecondaryTextColor(isDarkMode),
            size: 16
          ),
          Text(
            'Step 2',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.getSecondaryTextColor(isDarkMode),
            size: 16
          ),
          Text(
            'Step 3',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getSecondaryTextColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }


  // Method to save resume data to Firebase
  Future<void> _saveDataToFirebase() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }


    setState(() {
      _isLoading = true;
    });


    try {
      // Create employment objects from form data
      List<Employment> employmentList = [];
      for (int i = 0; i < _employmentBlocks.length; i++) {
        employmentList.add(Employment(
          jobTitle: _jobTitleControllers[i].text,
          employer: _employerControllers[i].text,
          startDate: _startDateControllers[i].text,
          endDate: _endDateControllers[i].text,
          location: _locationControllers[i].text,
          description: _descriptionControllers[i].text,
        ));
      }


      // Create Step2Data
      final step2Data = Step2Data(
        summary: _summaryController.text,
        employment: employmentList,
      );


      // Create a map with just the fields we want to update
      final Map<String, dynamic> updateData = {
        'professionalSummary': step2Data.summary,
        'employmentHistory': employmentList
            .map((job) => {
                  'jobTitle': job.jobTitle,
                  'employer': job.employer,
                  'startDate': job.startDate,
                  'endDate': job.endDate,
                  'location': job.location,
                  'description': job.description,
                })
            .toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };


      // Update the existing document using the resumeId passed from Step1
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('resume')
          .doc(widget.resumeId)
          .update(updateData);


      // Navigate to Step3Screen with the data and resumeId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step3Screen(
            step1Data: widget.step1Data,
            step2Data: step2Data,
            resumeId: widget.resumeId, // Pass the same resumeId to Step3
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.getTextColor(isDarkMode),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : Column(
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
                          Text(
                            'Professional Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 16),


                          // Professional Summary Text Area
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? AppColors.darkSurface : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _summaryController,
                                  style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
                                  maxLines: 5,
                                  maxLength: 100, // Built-in character limit
                                  decoration: InputDecoration(
                                    hintText:
                                        'Write here (maximum 100 characters)...',
                                    hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(16),
                                    // Hide the default counter
                                    counterText: '',
                                  ),
                                  onChanged: (text) {
                                    // Update state to refresh counter
                                    setState(() {});
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 8),
                                child: Text(
                                  '${100 - (_summaryController.text.length)} characters remaining',
                                  style: TextStyle(
                                    color: _summaryController.text.length >= 80
                                        ? Colors.red
                                        : AppColors.getSecondaryTextColor(isDarkMode),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                          // Employment History Section
                          Text(
                            'Employment History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextColor(isDarkMode),
                            ),
                          ),
                          const SizedBox(height: 16),


                          // Dynamic Employment Blocks
                          if (_employmentBlocks.isNotEmpty)
                            ...List.generate(_employmentBlocks.length,
                                (index) => _employmentBlocks[index]),


                          // Add one more employment button
                          GestureDetector(
                            onTap: _addEmploymentBlock,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Add one more employment',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.getTextColor(isDarkMode),
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
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
                              onPressed:
                                  _isLoading ? null : _saveDataToFirebase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
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



