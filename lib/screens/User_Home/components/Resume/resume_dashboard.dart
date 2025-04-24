import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard2.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard3.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_data.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';

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
  bool isDarkMode = false; // You can set this based on your app's theme mode

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
        // For Step 1 to Step 2, we need to collect and pass the data
        if (widget.currentStep == 1) {
          // This would be handled in the onPressed of the Next button
          // since we need to collect the data from the form
        }
      } else if (widget.currentStep > 2) {
        // Navigate back to step 2
        Navigator.pop(context);
      }
    } else if (step == 3) {
      // Navigate to Step 3 (Skills & Languages)
      if (widget.currentStep < 3) {
        // This is handled in the onPressed of Step2's Next button
      }
    }
  }

  // Shared breadcrumb widget with consistent styling
  Widget buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        border: Border(
          bottom: BorderSide(
              color: AppColors.getDividerColor(isDarkMode), width: 1),
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
                    ? AppColors.primaryBlue
                    : AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: widget.currentStep == 1
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppColors.getSecondaryTextColor(isDarkMode), size: 20),
          GestureDetector(
            onTap: () => navigateToStep(2),
            child: Text(
              'Step 2',
              style: TextStyle(
                fontSize: 16,
                color: widget.currentStep == 2
                    ? AppColors.primaryBlue
                    : AppColors.getSecondaryTextColor(isDarkMode),
                fontWeight: widget.currentStep == 2
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppColors.getSecondaryTextColor(isDarkMode), size: 20),
          GestureDetector(
            onTap: () => navigateToStep(3),
            child: Text(
              'Step 3',
              style: TextStyle(
                fontSize: 16,
                color: widget.currentStep == 3
                    ? AppColors.primaryBlue
                    : AppColors.getSecondaryTextColor(isDarkMode),
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
      backgroundColor: AppColors.getSurfaceColor(isDarkMode),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Dashboard',
        style: TextStyle(
            color: AppColors.getTextColor(isDarkMode),
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  // Base scaffold implementation
  @override
  Widget build(BuildContext context) {
    // You can get the isDarkMode value from your theme provider or MediaQuery
    // For example: isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
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
  final String initialTemplateType;

  const PersonalDetailsScreen({
    Key? key,
    this.initialTemplateType = 'modern', // Default template if none provided
  }) : super(key: key, currentStep: 1);

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState
    extends BaseStepScreenState<PersonalDetailsScreen> {
  // Controllers for date fields
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  late String _selectedTemplateType;

  // Controllers for education fields
  final List<TextEditingController> _schoolControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _levelControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _locationControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _descriptionControllers = [
    TextEditingController()
  ];

  // These were already declared in your original code
  final List<TextEditingController> _startDateControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _endDateControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _educationTitleControllers = [
    TextEditingController()
  ];

  // For profile image
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Loading state
  bool _isLoading = false;
  bool _isDataLoading = false;

  // List to track education blocks
  final List<Widget> _educationBlocks = [];

  @override
  void initState() {
    super.initState();
    // // Check if dark mode is active
    // isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Initialize with the passed template
    _selectedTemplateType = widget.initialTemplateType;
    _educationBlocks.add(_buildEducationBlock(0));

    // Pre-fill email if user is signed in
    if (_auth.currentUser != null) {
      _emailController.text = _auth.currentUser!.email ?? '';
    }
    _fetchExistingResumeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move theme detection to didChangeDependencies which is safe to access context
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();

    for (var controller in _schoolControllers) {
      controller.dispose();
    }
    for (var controller in _levelControllers) {
      controller.dispose();
    }
    for (var controller in _locationControllers) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }

    // These were in your original dispose method
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

  Future<void> _fetchExistingResumeData() async {
    try {
      setState(() {
        _isDataLoading = true;
      });

      // Make sure we have a user
      if (_auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Format user ID for Firestore document ID (replace '.' with '_')
      String userEmail = _auth.currentUser!.email ?? '';
      String userId = userEmail.replaceAll('.', '_');

      // Reference to user's resume collection
      final resumeCollection =
          _firestore.collection('users').doc(userId).collection('resume');

      // Get the latest resume document
      final querySnapshot = await resumeCollection
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final resumeData = querySnapshot.docs.first.data();

        // Update template type
        _selectedTemplateType =
            resumeData['templateType'] ?? widget.initialTemplateType;

        // Fill personal info fields
        if (resumeData.containsKey('personalInfo')) {
          final personalInfo =
              resumeData['personalInfo'] as Map<String, dynamic>;
          _roleController.text = personalInfo['role'] ?? '';
          _firstNameController.text = personalInfo['firstName'] ?? '';
          _lastNameController.text = personalInfo['lastName'] ?? '';
          _emailController.text = personalInfo['email'] ?? '';
          _phoneController.text = personalInfo['phone'] ?? '';
          _addressController.text = personalInfo['address'] ?? '';
          _cityController.text = personalInfo['city'] ?? '';
          _countryController.text = personalInfo['country'] ?? '';
          _postalCodeController.text = personalInfo['postalCode'] ?? '';

          // Get profile image if exists
          if (personalInfo['profileImagePath'] != null &&
              personalInfo['profileImagePath'] != '') {
            try {
              // Here we're using http package to download the image
              final response =
                  await http.get(Uri.parse(personalInfo['profileImagePath']));
              final bytes = response.bodyBytes;

              // Create a temporary file
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/profile_image.jpg');
              await tempFile.writeAsBytes(bytes);

              setState(() {
                _profileImage = tempFile;
              });
            } catch (e) {
              print('Error loading profile image: $e');
            }
          }
        }

        // Fill education data
        if (resumeData.containsKey('education') &&
            resumeData['education'] is List) {
          final educationList = resumeData['education'] as List;

          // Clear the initial education block
          setState(() {
            _educationBlocks.clear();
            _startDateControllers.clear();
            _endDateControllers.clear();
            _educationTitleControllers.clear();
            _schoolControllers.clear();
            _levelControllers.clear();
            _locationControllers.clear();
            _descriptionControllers.clear();
          });

          // Add each education entry
          for (var education in educationList) {
            if (education is Map<String, dynamic>) {
              setState(() {
                final index = _educationBlocks.length;

                // Add controllers
                _startDateControllers.add(
                    TextEditingController(text: education['startDate'] ?? ''));
                _endDateControllers.add(
                    TextEditingController(text: education['endDate'] ?? ''));
                _educationTitleControllers
                    .add(TextEditingController(text: education['title'] ?? ''));
                _schoolControllers.add(
                    TextEditingController(text: education['school'] ?? ''));
                _levelControllers
                    .add(TextEditingController(text: education['level'] ?? ''));
                _locationControllers.add(
                    TextEditingController(text: education['location'] ?? ''));
                _descriptionControllers.add(TextEditingController(
                    text: education['description'] ?? ''));

                // Add education block widget
                _educationBlocks.add(_buildEducationBlock(index));
              });
            }
          }

          // If no education was added, add an empty one
          if (_educationBlocks.isEmpty) {
            setState(() {
              _startDateControllers.add(TextEditingController());
              _endDateControllers.add(TextEditingController());
              _educationTitleControllers.add(TextEditingController());
              _schoolControllers.add(TextEditingController());
              _levelControllers.add(TextEditingController());
              _locationControllers.add(TextEditingController());
              _descriptionControllers.add(TextEditingController());
              _educationBlocks.add(_buildEducationBlock(0));
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching resume data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading resume data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isDataLoading = false;
      });
    }
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
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        // This more aggressively overrides styles for the date input
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.getSurfaceColor(isDarkMode),
                    onSurface: AppColors.getTextColor(isDarkMode),
                  )
                : ColorScheme.light(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.getSurfaceColor(isDarkMode),
                    onSurface: Colors.black,
                  ),
            // Apply a direct override for text selection and input
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: isDarkMode ? Colors.white : Colors.black,
              selectionColor: AppColors.primaryBlue.withOpacity(0.3),
              selectionHandleColor: AppColors.primaryBlue,
            ),
            // Override text field defaults
            textTheme: Typography.material2021().black.copyWith(
                  bodyLarge: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  bodyMedium: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  titleMedium: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
            // Override primary text theme
            primaryTextTheme: Typography.material2021().black.copyWith(
                  bodyLarge: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  bodyMedium: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                  titleMedium: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
          ),
          child: MediaQuery(
            // Force text scale factor to ensure visibility
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
            ),
            child: child!,
          ),
        );
      },
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
      _schoolControllers.add(TextEditingController());
      _levelControllers.add(TextEditingController());
      _locationControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
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
        _schoolControllers.removeAt(index);
        _levelControllers.removeAt(index);
        _locationControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
      });
    }
  }

  // Save data to Firebase
  Future<String?> _saveToFirebase(Step1Data step1Data) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Make sure we have a user
      if (_auth.currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Format user ID for Firestore document ID (replace '.' with '_')
      String userEmail = _auth.currentUser!.email ?? '';
      String userId = userEmail.replaceAll('.', '_');

      // Initialize variables for Firestore data
      String? profileImageUrl;
      final now = DateTime.now();

      // Upload profile image if exists
      if (_profileImage != null) {
        // Create a storage reference
        final storageRef = _storage.ref().child(
            'resume_profile_images/$userId/${now.millisecondsSinceEpoch}');

        // Upload the file
        await storageRef.putFile(_profileImage!);

        // Get download URL
        profileImageUrl = await storageRef.getDownloadURL();
      }

      // Convert Education objects to a list of maps for Firestore
      List<Map<String, dynamic>> educationList = step1Data.education
          .map((education) => {
                'title': education.title,
                'school': education.school,
                'level': education.level,
                'startDate': education.startDate,
                'endDate': education.endDate,
                'location': education.location,
                // 'description': education.description,
              })
          .toList();

      // Create document with personal info and education
      Map<String, dynamic> resumeData = {
        'userId': userId,
        'personalInfo': {
          'role': step1Data.role,
          'firstName': step1Data.firstName,
          'lastName': step1Data.lastName,
          'email': step1Data.email,
          'phone': step1Data.phone,
          'address': step1Data.address,
          'city': step1Data.city,
          'country': step1Data.country,
          'postalCode': step1Data.postalCode,
          'profileImagePath': profileImageUrl,
        },
        'education': educationList,
        // 'employmentHistory': [], // Empty for now, will be filled in Step 2
        // 'skills': [], // Empty for now, will be filled in Step 3
        // 'languages': [], // Empty for now, will be filled in Step 3
        'professionalSummary': '',
        'templateType': _selectedTemplateType,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Reference to user's resume collection
      final resumeCollection =
          _firestore.collection('users').doc(userId).collection('resume');

      // Check if user already has a resume document
      final existingResumes = await resumeCollection.limit(1).get();
      String documentId;

      if (existingResumes.docs.isNotEmpty) {
        // Update existing document
        documentId = existingResumes.docs.first.id;
        await resumeCollection.doc(documentId).update(resumeData);
      } else {
        // Create new document
        final docRef = await resumeCollection.add(resumeData);
        documentId = docRef.id;
      }

      return documentId;
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving resume: ${e.toString()}')));
      print('Error saving to Firebase: $e');
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build a single education block
  // Build a single education block with proper dark theme support
  Widget _buildEducationBlock(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getDividerColor(isDarkMode)),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/trash_12252659.svg',
                  width: 24, // adjust size as needed
                  height: 18,
                  color:
                      Colors.red, // optional, applies if the SVG supports color
                ),
                onPressed: () => _removeEducationBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Education Title
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.7)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.getDividerColor(isDarkMode),
                width: 0.5,
              ),
            ),
            child: TextFormField(
              // Changed from TextField to TextFormField
              controller: _educationTitleControllers[index],
              style: TextStyle(color: AppColors.getTextColor(isDarkMode),
              fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Education Title *',
                // Added asterisk for required field
                hintStyle: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontSize: 11),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorStyle: TextStyle(color: Colors.red),
              ),
              validator: (value) {
                // Only validate if this is the first education block or if the school field has content
                if ((index == 0 || _schoolControllers[index].text.isNotEmpty) &&
                    (value == null || value.isEmpty)) {
                  return 'Required';
                }
                return null;
              },
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
                    color: isDarkMode
                        ? AppColors.darkSurface.withOpacity(0.7)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.getDividerColor(isDarkMode),
                      width: 0.5,
                    ),
                  ),
                  child: TextFormField(
                    // Changed from TextField to TextFormField
                    controller: _schoolControllers[index],
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'School *',
                      // Added asterisk for required field
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    validator: (value) {
                      // Only validate if this is the first education block or if the title field has content
                      if ((index == 0 ||
                              _educationTitleControllers[index]
                                  .text
                                  .isNotEmpty) &&
                          (value == null || value.isEmpty)) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Education Level
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface.withOpacity(0.7)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.getDividerColor(isDarkMode),
                      width: 0.5,
                    ),
                  ),
                  child: TextField(
                    controller: _levelControllers[index],
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,%+-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Aggregate',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
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

          // Start Date and End Date Row
          Row(
            children: [
              // Start Date
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _selectDate(context, _startDateControllers[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface.withOpacity(0.7)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.getDividerColor(isDarkMode),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize:
                                  11, // Reduced font size to fit date better
                            ),
                            controller: _startDateControllers[index],
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: 'Start Date',
                              hintStyle: TextStyle(
                                color:
                                    AppColors.getSecondaryTextColor(isDarkMode),
                                fontSize: 11, // Matching hint text size
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              isDense: true, // Makes the field more compact
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: AppColors.getSecondaryTextColor(isDarkMode),
                            size: 18, // Slightly smaller icon
                          ),
                          padding: EdgeInsets.all(
                              8), // Smaller padding for the icon button
                          constraints:
                              BoxConstraints(), // Removes minimum size constraints
                          onPressed: () => _selectDate(
                              context, _startDateControllers[index]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // End Date
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, _endDateControllers[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkSurface.withOpacity(0.7)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.getDividerColor(isDarkMode),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize:
                                  11, 
                            ),
                            controller: _endDateControllers[index],
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              hintText: 'End Date',
                              hintStyle: TextStyle(
                                color:
                                    AppColors.getSecondaryTextColor(isDarkMode),
                                fontSize:
                                    11, 
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: AppColors.getSecondaryTextColor(isDarkMode),
                            size:
                                18, 
                          ),
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                          onPressed: () =>
                              _selectDate(context, _endDateControllers[index]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Location
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.7)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.getDividerColor(isDarkMode),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: _locationControllers[index],
              style: TextStyle(color: AppColors.getTextColor(isDarkMode),
              fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Location',
                hintStyle: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontSize: 11),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildStepContent() {
    return Stack(
      children: [
        if (_isDataLoading)
          Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ),
          ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 24),

                // Role you want
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _roleController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Role you want *',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your desired role';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // First Name, Last Name, and Upload Photo
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Name and Last Name Column
                    Expanded(
                      child: Column(
                        children: [
                          // First Name
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkSurface
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _firstNameController,
                              style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontSize: 11),
                              decoration: InputDecoration(
                                hintText: 'First Name *',
                                hintStyle: TextStyle(
                                    color: AppColors.getSecondaryTextColor(
                                        isDarkMode),
                                        fontSize: 11),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                errorStyle: TextStyle(
                                    color: Colors.red), // Style for error text
                              ),
                              // Add validator function
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Last Name
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkSurface
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _lastNameController,
                              style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontSize: 11),
                              decoration: InputDecoration(
                                hintText: 'Last Name',
                                hintStyle: TextStyle(
                                    color: AppColors.getSecondaryTextColor(
                                        isDarkMode),
                                        fontSize: 11),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Upload Photo - Height matches combined height of first name and last name fields
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 110,
                        // Height calculation: 2 text fields (each ~48px) + 16px spacing between them
                        height: 112,
                        // 48 + 48 + 16
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkSurface
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 112,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Upload Photo',
                                    style: TextStyle(
                                      color: AppColors.getSecondaryTextColor(
                                          isDarkMode),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.add,
                                    color: AppColors.getSecondaryTextColor(
                                        isDarkMode),
                                    size: 24,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Email *',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      errorStyle:
                          TextStyle(color: Colors.red), // Style for error text
                    ),
                    keyboardType: TextInputType.emailAddress,

                    // Add validator function
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Phone No.
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Phone No. *',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _addressController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Address',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
                          color: isDarkMode
                              ? AppColors.darkSurface
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _cityController,
                          style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize: 11),
                          decoration: InputDecoration(
                            hintText: 'City *',
                            hintStyle: TextStyle(
                                color: AppColors.getSecondaryTextColor(
                                    isDarkMode),
                                    fontSize: 11),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            errorStyle: TextStyle(
                                color: Colors.red), // Style for error text
                          ),
                          // Add validator function
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Country
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkSurface
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _countryController,
                          style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize: 11),
                          decoration: InputDecoration(
                            hintText: 'Country *',
                            hintStyle: TextStyle(
                                color: AppColors.getSecondaryTextColor(
                                    isDarkMode),
                                    fontSize: 11),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            errorStyle: TextStyle(
                                color: Colors.red), // Style for error text
                          ),
                          // Add validator function
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Postal Code
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.darkSurface
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _postalCodeController,
                    style: TextStyle(color: AppColors.getTextColor(isDarkMode),
                    fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Postal Code',
                      hintStyle: TextStyle(
                          color: AppColors.getSecondaryTextColor(isDarkMode),
                          fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 40),

                // Education Section Header with border
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.getDividerColor(isDarkMode),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Education',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextColor(isDarkMode),
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
                        Text(
                          'Add one more education',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextColor(isDarkMode),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
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
                    onPressed: _isLoading
                        ? null
                        : () async {
                            bool hasEducationData = false;

                            // Check if at least one education entry has required fields filled
                            for (int i = 0; i < _educationBlocks.length; i++) {
                              if (_educationTitleControllers[i]
                                      .text
                                      .isNotEmpty &&
                                  _schoolControllers[i].text.isNotEmpty) {
                                hasEducationData = true;
                                break;
                              }
                            }
                            if (!hasEducationData) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please fill in all required fields.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (formKey.currentState!.validate()) {
                              // Collect education data
                              List<Education> educationData = [];
                              for (int i = 0;
                                  i < _educationBlocks.length;
                                  i++) {
                                if (_educationTitleControllers[i]
                                        .text
                                        .isNotEmpty &&
                                    _schoolControllers[i].text.isNotEmpty) {
                                  educationData.add(Education(
                                    title: _educationTitleControllers[i].text,
                                    school: _schoolControllers[i].text,
                                    level: _levelControllers[i].text,
                                    startDate: _startDateControllers[i].text,
                                    endDate: _endDateControllers[i].text,
                                    location: _locationControllers[i].text,
                                  ));
                                }
                              }

                              // Create Step1Data
                              final step1Data = Step1Data(
                                role: _roleController.text,
                                firstName: _firstNameController.text,
                                lastName: _lastNameController.text,
                                email: _emailController.text,
                                phone: _phoneController.text,
                                address: _addressController.text,
                                city: _cityController.text,
                                country: _countryController.text,
                                postalCode: _postalCodeController.text,
                                profileImagePath: _profileImage?.path,
                                education: educationData,
                              );

                              // Save to Firebase and get document ID
                              final String? documentId =
                                  await _saveToFirebase(step1Data);

                              // If successful, navigate to Step2Screen passing data and document ID
                              if (!mounted || documentId == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Step2Screen(
                                          step1Data: step1Data,
                                          resumeId: documentId,
                                        )),
                              );
                            } else {
                              // Show error message and scroll to the first error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please fill in all required fields'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor:
                          AppColors.primaryBlue.withOpacity(0.6),
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
                            ))
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }
}
