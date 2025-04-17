import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard2.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard3.dart';

// Base class for all step screens to ensure consistent UI and navigation
abstract class BaseStepScreen extends StatefulWidget {
  final int currentStep;
  
  const BaseStepScreen({
    Key? key,
    required this.currentStep,
  }) : super(key: key);
}

// Base state class for all step screens
abstract class BaseStepScreenState<T extends BaseStepScreen> extends State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Navigate to specific step
  void navigateToStep(int step) {
    if (step == 1) {
      // Navigate to Step 1 (Personal Details)
      if (widget.currentStep != 1) {
        if (widget.currentStep == 3) {
          // Pop twice if coming from step 3
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          // Pop once if coming from step 2
          Navigator.pop(context);
        }
      }
    } else if (step == 2) {
      // Navigate to Step 2 (Employment History)
      if (widget.currentStep < 2) {
        // Navigate forward to step 2
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>const Step2Screen()),
        );
      } else if (widget.currentStep > 2) {
        // Navigate back to step 2
        Navigator.pop(context);
      }
    } else if (step == 3) {
      // Navigate to Step 3 (Skills & Languages)
      if (widget.currentStep < 3) {
        if (widget.currentStep == 1) {
          // Navigate through step 2 first if coming from step 1
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const Step2Screen())
          ).then((_) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Step3Screen()),
            );
          });
        } else {
          // Navigate directly to step 3 if coming from step 2
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Step3Screen()),
          );
        }
      }
    }
  }
  
  // Shared breadcrumb widget with consistent styling
  Widget buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => navigateToStep(1),
            child: Text(
              'Step 1',
              style: TextStyle(
                fontSize: 16,
                color: widget.currentStep == 1 
                    ? const Color(0xFF2196F3)
                    : Colors.grey,
                fontWeight: widget.currentStep == 1 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          GestureDetector(
            onTap: () => navigateToStep(2),
            child: Text(
              'Step 2',
              style: TextStyle(
                fontSize: 16,
                color: widget.currentStep == 2 
                    ? const Color(0xFF2196F3)
                    : Colors.grey,
                fontWeight: widget.currentStep == 2 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          GestureDetector(
            onTap: () => navigateToStep(3),
            child: Text(
              'Step 3',
              style: TextStyle(
                fontSize: 16,
                color: widget.currentStep == 3 
                    ? const Color(0xFF2196F3)
                    : Colors.grey,
                fontWeight: widget.currentStep == 3 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Shared app bar with consistent styling
  PreferredSizeWidget buildAppBar() {
    return AppBar(
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
    );
  }
  
  // Base scaffold implementation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: buildAppBar(),
      body: Column(
        children: [
          buildBreadcrumb(),
          Expanded(
            child: buildStepContent(),
          ),
        ],
      ),
    );
  }
  
  // Abstract method to be implemented by each step screen
  Widget buildStepContent();
}

// Step 1: Personal Details Screen
class PersonalDetailsScreen extends BaseStepScreen {
  const PersonalDetailsScreen({Key? key}) : super(key: key, currentStep: 1);
  
  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends BaseStepScreenState<PersonalDetailsScreen> {
  // Controllers for date fields
  final List<TextEditingController> _startDateControllers = [TextEditingController()];
  final List<TextEditingController> _endDateControllers = [TextEditingController()];
  final List<TextEditingController> _educationTitleControllers = [TextEditingController()];
  
  // For profile image
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  // List to track education blocks
  final List<Widget> _educationBlocks = [];
  
  @override
  void initState() {
    super.initState();
    // Add initial education block
    _educationBlocks.add(_buildEducationBlock(0));
  }
  
  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _startDateControllers) {
      controller.dispose();
    }
    for (var controller in _endDateControllers) {
      controller.dispose();
    }
    for (var controller in _educationTitleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
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
  
  // Function to add a new education block
  void _addEducationBlock() {
    setState(() {
      final int index = _educationBlocks.length;
      _startDateControllers.add(TextEditingController());
      _endDateControllers.add(TextEditingController());
      _educationTitleControllers.add(TextEditingController());
      _educationBlocks.add(_buildEducationBlock(index));
    });
  }
  
  // Function to remove an education block
  void _removeEducationBlock(int index) {
    if (_educationBlocks.length > 1) {
      setState(() {
        _educationBlocks.removeAt(index);
        _startDateControllers.removeAt(index);
        _endDateControllers.removeAt(index);
        _educationTitleControllers.removeAt(index);
      });
    }
  }
  
  // Build a single education block
  Widget _buildEducationBlock(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education block header with number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Education #${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeEducationBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Education Title
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _educationTitleControllers[index],
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Education Title',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // School and Education Level Row
          Row(
            children: [
              // School Name
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Name Of School',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Education Level
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Higher Sec...',
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

          // Start Date and End Date Row
          Row(
            children: [
              // Start Date
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          controller: _startDateControllers[index],
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'Start Date',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.grey),
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
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: const TextStyle(color: Colors.black),
                          controller: _endDateControllers[index],
                          readOnly: true,
                          decoration: const InputDecoration(
                            hintText: 'End Date',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.grey),
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
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
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

          // Description text field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
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
    );
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
            const Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Role you want
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Role you want',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // First Name and Upload Photo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Name
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'First Name',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Upload Photo
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 110,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _profileImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: 110,
                              height: 48,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Upload Photo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Icon(
                                Icons.add,
                                color: Colors.grey[400],
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Last Name
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Last Name',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Email
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone No.
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Phone No.',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(height: 16),
            
            // Address
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Address',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // City and Country
            Row(
              children: [
                // City
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'City',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Country
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const TextField(
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Country',
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
            
            // Postal Code
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Postal Code',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 40),
            
            // Education Section Header with border
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Education',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dynamic Education Blocks
            ..._educationBlocks,
            
            // Add one more education button
            GestureDetector(
              onTap: _addEducationBlock,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add one more education',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
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
                  if (formKey.currentState!.validate()) {
                    // Navigate to Step2Screen when Next is pressed
                    navigateToStep(2);
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
    );
  }
}