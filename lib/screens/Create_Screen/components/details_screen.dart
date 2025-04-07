import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/utils/app_colors.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../l10n/app_localization.dart';

class DetailsScreen extends StatefulWidget {
  final QuoteTemplate template;
  final bool isPaidUser;

  const DetailsScreen({
    Key? key,
    required this.template,
    required this.isPaidUser,
  }) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _socialMediaController = TextEditingController();

  late TabController _tabController;
  File? _profileImage;
  String? _profileImageUrl;
  bool _showInfoBox = true;
  bool _isLoading = false;
  bool _isTemplateImageLoading = true;
  String _selectedBackground = 'white'; // Default background

  // Background options
  final List<Map<String, dynamic>> _backgroundOptions = [
    {'name': 'White', 'value': 'white', 'color': Colors.white},
    {'name': 'Light Gray', 'value': 'lightGray', 'color': Colors.grey[200]},
    {'name': 'Light Blue', 'value': 'lightBlue', 'color': Colors.blue[100]},
    {'name': 'Light Green', 'value': 'lightGreen', 'color': Colors.green[100]},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email != null) {
        String docId = currentUser!.email!.replaceAll('.', '_');

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            _nameController.text = userData['name'] ?? '';
            _mobileController.text = userData['mobile'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _descriptionController.text = userData['description'] ?? '';
            _companyNameController.text = userData['companyName'] ?? '';
            _socialMediaController.text = userData['socialMedia'] ?? '';
            _profileImageUrl = userData['profileImage'];
            _showInfoBox = userData['showInfoBox'] ?? true;
            _selectedBackground = userData['infoBoxBackground'] ?? 'white';

            // Set the tab based on the lastActiveProfileTab if available
            if (userData['lastActiveProfileTab'] == 'business') {
              _tabController.index = 1;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.failedToLoadUserData)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionScreen(),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (!widget.isPaidUser) {
      _navigateToSubscription();
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return _profileImageUrl;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(_profileImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (!widget.isPaidUser) {
      _navigateToSubscription();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) {
        throw Exception(context.loc.userNotLoggedIn);
      }

      String docId = currentUser!.email!.replaceAll('.', '_');
      String? newProfileImageUrl = await _uploadProfileImage();

      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'companyName': _companyNameController.text,
        'socialMedia': _socialMediaController.text,
        'showInfoBox': _showInfoBox,
        'infoBoxBackground': _selectedBackground,
        'lastActiveProfileTab':
            _tabController.index == 0 ? 'personal' : 'business',
      };

      if (newProfileImageUrl != null) {
        userData['profileImage'] = newProfileImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.profileDetailsSavedSuccessfully),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.loc.failedToSaveProfileDetails),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(
          title: context.loc.editTemplate,
          templateImageUrl: widget.template.imageUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _companyNameController.dispose();
    _socialMediaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to get background color
  Color _getBackgroundColor() {
    switch (_selectedBackground) {
      case 'lightGray':
        return Colors.grey[200]!;
      case 'lightBlue':
        return Colors.blue[100]!;
      case 'lightGreen':
        return Colors.green[100]!;
      case 'white':
      default:
        return Colors.white;
    }
  }

  Widget _buildTemplatePreview({required bool isPersonal}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDarkMode
        ? Colors.black
        : Colors.black; // Info box text is always black regardless of theme
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.getDividerColor(isDarkMode)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Template image with loading indicator inside
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Network image
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    widget.template.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      // Use post-frame callback to safely update state
                      if (loadingProgress == null && _isTemplateImageLoading) {
                        // Image loaded, schedule state update
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isTemplateImageLoading = false;
                            });
                          }
                        });
                        return child;
                      } else if (loadingProgress != null &&
                          !_isTemplateImageLoading) {
                        // Still loading, schedule state update if needed
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _isTemplateImageLoading = true;
                            });
                          }
                        });
                      }

                      // Return the appropriate widget based on current state
                      return loadingProgress == null
                          ? child
                          : Container(color: Colors.transparent);
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Error loading image, schedule state update
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _isTemplateImageLoading = false;
                          });
                        }
                      });

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text(
                              context.loc.failedToLoadImage,
                              style: TextStyle(
                                color: AppColors.getTextColor(isDarkMode),
                                fontSize: fontSize - 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Overlay loading indicator (shows only when loading)
                if (_isTemplateImageLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          backgroundColor: isDarkMode
                              ? Colors.grey.shade700.withOpacity(0.3)
                              : Colors.grey.shade300.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800.withOpacity(0.7)
                                : Colors.grey.shade200.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.loc.loadingTemplate,
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode),
                              fontSize: fontSize - 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // PRO badge overlay for premium templates (maintain your existing code)
                if (widget.template.isPaid && !widget.isPaidUser)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.amber, size: 40),
                            SizedBox(height: 8),
                            Text(
                              context.loc.premiumTemplate,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/subscription');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                context.loc.upgrade,
                                style: TextStyle(fontSize: fontSize - 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info box (your existing code)
          if (_showInfoBox)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  // Profile image or logo
                  _buildCircularImage(size: 50),
                  SizedBox(width: 12),

                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPersonal)
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : context.loc.yourName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                              color: textColor,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company name first for business cards
                              Text(
                                _companyNameController.text.isNotEmpty
                                    ? _companyNameController.text
                                    : context.loc.companyName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              // Then person's name
                              Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : context.loc.yourName,
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        if (_locationController.text.isNotEmpty)
                          Text(
                            _locationController.text,
                            style: TextStyle(
                                fontSize: fontSize - 2, color: textColor),
                          ),
                        if (_mobileController.text.isNotEmpty)
                          Text(
                            _mobileController.text,
                            style: TextStyle(
                                fontSize: fontSize - 2, color: textColor),
                          ),
                        // Only show social media and description in business profile
                        if (!isPersonal) ...[
                          if (_socialMediaController.text.isNotEmpty)
                            Text(
                              _socialMediaController.text,
                              style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: AppColors.primaryBlue),
                            ),
                          if (_descriptionController.text.isNotEmpty)
                            Text(
                              _descriptionController.text,
                              style: TextStyle(
                                  fontSize: fontSize - 2, color: textColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build profile photo widget
  Widget _buildProfilePhotoWidget() {
    return _buildCircularImage(size: 64);
  }

  // Build circular image widget for both profile and preview
  Widget _buildCircularImage({required double size}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.getDividerColor(isDarkMode)),
        image: _profileImage != null
            ? DecorationImage(
                image: FileImage(_profileImage!),
                fit: BoxFit.cover,
              )
            : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: _profileImage == null &&
              (_profileImageUrl == null || _profileImageUrl!.isEmpty)
          ? Icon(
              Icons.person,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
              size: size / 2,
            )
          : null,
    );
  }

  // Build a text field with lock functionality for non-paid users
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    if (widget.isPaidUser) {
      // Normal text field for paid users
      return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        // Update preview in real-time
        style: TextStyle(
          color: AppColors.getTextColor(isDarkMode),
          fontSize: fontSize - 1,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.getSecondaryTextColor(isDarkMode),
            fontSize: fontSize - 1,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.getDividerColor(isDarkMode)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.getDividerColor(isDarkMode)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          filled: true,
          fillColor:
              isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      );
    } else {
      // Locked text field for non-paid users
      return InkWell(
        onTap: _navigateToSubscription,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.getDividerColor(isDarkMode)),
            color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: maxLines > 1 ? 100 : 56,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  hintText,
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(isDarkMode),
                    fontSize: fontSize - 1,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.lock, color: Colors.yellow),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        foregroundColor: AppColors.getTextColor(isDarkMode),
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          context.loc.profileDetails,
          style: TextStyle(
            color: AppColors.getTextColor(isDarkMode),
            fontSize: fontSize,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : Column(
              children: [
                // Tab Bar
                Container(
                  color: AppColors.getBackgroundColor(isDarkMode),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        child: Text(
                          context.loc.personal,
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                      ),
                      Tab(
                        child: Text(
                          context.loc.business,
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                      ),
                    ],
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor:
                        AppColors.getSecondaryTextColor(isDarkMode),
                    indicatorColor: AppColors.primaryBlue,
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Personal Tab
                      _buildPersonalTab(),

                      // Business Tab
                      _buildBusinessTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPersonalTab() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: context.loc.enterYourName,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.mobile,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _mobileController,
            hintText: context.loc.enterYourMobileNumber,
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.location,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: context.loc.enterYourLocation,
          ),

          SizedBox(height: 24),

          // Profile Photo Section
          Text(
            context.loc.profilePhoto,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildProfilePhotoWidget(),
              SizedBox(width: 16),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  context.loc.changePhoto,
                  style: TextStyle(fontSize: fontSize - 2),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  textStyle: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (!widget.isPaidUser)
                Icon(Icons.lock, color: Colors.yellow, size: 16),
            ],
          ),

          SizedBox(height: 24),

          // Template Preview
          Text(
            context.loc.templatePreview,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 12),
          _buildTemplatePreview(isPersonal: true),

          SizedBox(height: 24),

          // Display Options - Only for paid users
          if (widget.isPaidUser) ...[
            Text(
              context.loc.displayOptions,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDarkMode),
                fontSize: fontSize - 1,
              ),
            ),
            SizedBox(height: 12),

            // Show Info Box Toggle
            Row(
              children: [
                Text(
                  context.loc.showInfoBox,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDarkMode),
                    fontSize: fontSize - 2,
                  ),
                ),
                Spacer(),
                Switch(
                  value: _showInfoBox,
                  onChanged: (value) {
                    setState(() {
                      _showInfoBox = value;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),

            // Background Color Selection
            if (_showInfoBox) ...[
              SizedBox(height: 8),
              Text(
                context.loc.backgroundColor,
                style: TextStyle(
                  color: AppColors.getTextColor(isDarkMode),
                  fontSize: fontSize - 2,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _backgroundOptions.map((bg) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackground = bg['value'];
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bg['color'],
                        border: Border.all(
                          color: _selectedBackground == bg['value']
                              ? AppColors.primaryBlue
                              : AppColors.getDividerColor(isDarkMode),
                          width: _selectedBackground == bg['value'] ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],

          SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  child: Text(
                    context.loc.save,
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? AppColors.darkSurface : Colors.white,
                    foregroundColor: AppColors.getTextColor(isDarkMode),
                    elevation: 1,
                    side: BorderSide(
                        color: AppColors.getDividerColor(isDarkMode)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEditScreen,
                  child: Text(
                    context.loc.next,
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final fontSize = textSizeProvider.fontSize;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: context.loc.enterYourName,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.companyName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _companyNameController,
            hintText: context.loc.enterYourCompanyName,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.mobile,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _mobileController,
            hintText: context.loc.enterYourMobileNumber,
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.location,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: context.loc.enterYourBusinessLocation,
          ),

          SizedBox(height: 16),

          // New Social Media field
          Text(
            context.loc.socialMediaHandle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _socialMediaController,
            hintText: context.loc.enterYourSocialMediaHandle,
          ),

          SizedBox(height: 16),

          Text(
            context.loc.productDescription,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            hintText: context.loc.enterBusinessDescription,
            maxLines: 3,
          ),

          SizedBox(height: 24),

          Text(
            context.loc.logo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildProfilePhotoWidget(),
              SizedBox(width: 16),
              TextButton(
                onPressed: _pickImage,
                child: Text(
                  context.loc.changeLogo,
                  style: TextStyle(fontSize: fontSize - 2),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  textStyle: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              if (!widget.isPaidUser)
                Icon(Icons.lock, color: Colors.yellow, size: 16),
            ],
          ),

          SizedBox(height: 24),

          // Template Preview
          Text(
            context.loc.templatePreview,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
              fontSize: fontSize - 1,
            ),
          ),
          SizedBox(height: 12),
          _buildTemplatePreview(isPersonal: false),

          SizedBox(height: 24),

          // Display Options - Only for paid users
          if (widget.isPaidUser) ...[
            Text(
              context.loc.displayOptions,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDarkMode),
                fontSize: fontSize - 1,
              ),
            ),
            SizedBox(height: 12),

            // Show Info Box Toggle
            Row(
              children: [
                Text(
                  context.loc.showInfoBox,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDarkMode),
                    fontSize: fontSize - 2,
                  ),
                ),
                Spacer(),
                Switch(
                  value: _showInfoBox,
                  onChanged: (value) {
                    setState(() {
                      _showInfoBox = value;
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
              ],
            ),

            // Background Color Selection
            if (_showInfoBox) ...[
              SizedBox(height: 8),
              Text(
                context.loc.backgroundColor,
                style: TextStyle(
                  color: AppColors.getTextColor(isDarkMode),
                  fontSize: fontSize - 2,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _backgroundOptions.map((bg) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackground = bg['value'];
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bg['color'],
                        border: Border.all(
                          color: _selectedBackground == bg['value']
                              ? AppColors.primaryBlue
                              : AppColors.getDividerColor(isDarkMode),
                          width: _selectedBackground == bg['value'] ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],

          SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveUserData,
                  child: Text(
                    context.loc.save,
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? AppColors.darkSurface : Colors.white,
                    foregroundColor: AppColors.getTextColor(isDarkMode),
                    elevation: 1,
                    side: BorderSide(
                        color: AppColors.getDividerColor(isDarkMode)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEditScreen,
                  child: Text(
                    context.loc.next,
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
