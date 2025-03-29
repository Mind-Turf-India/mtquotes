import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';

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

class _DetailsScreenState extends State<DetailsScreen> with SingleTickerProviderStateMixin {
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
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _nameController.text = userData['name'] ?? '';
            _mobileController.text = userData['mobile'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _descriptionController.text = userData['description'] ?? '';
            _companyNameController.text = userData['companyName'] ?? '';
            _socialMediaController.text = userData['socialMedia'] ?? ''; // Load social media handle
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
          SnackBar(content: Text('Failed to load user data')),
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
          .child('profile_pictures')
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
        throw Exception('User not logged in');
      }

      String docId = currentUser!.email!.replaceAll('.', '_');
      String? newProfileImageUrl = await _uploadProfileImage();

      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'mobile': _mobileController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'companyName': _companyNameController.text,
        'socialMedia': _socialMediaController.text, // Save social media handle
        'showInfoBox': _showInfoBox,
        'infoBoxBackground': _selectedBackground,
        'lastActiveProfileTab': _tabController.index == 0 ? 'personal' : 'business',
      };

      if (newProfileImageUrl != null) {
        userData['profileImage'] = newProfileImageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(docId)
          .update(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile details saved successfully')),
      );
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile details')),
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
          title: 'Edit Template',
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

  // Build the template preview with user details in info box
  // Updated _buildTemplatePreview method to properly show name in business tab
  Widget _buildTemplatePreview({required bool isPersonal}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Template image
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              image: DecorationImage(
                image: NetworkImage(widget.template.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Info box
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
                            _nameController.text.isNotEmpty ? _nameController.text : 'Your Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company name first for business cards
                              Text(
                                _companyNameController.text.isNotEmpty ? _companyNameController.text : 'Company Name',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              // Then person's name
                              Text(
                                _nameController.text.isNotEmpty ? _nameController.text : 'Your Name',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        if (_locationController.text.isNotEmpty)
                          Text(
                            _locationController.text,
                            style: TextStyle(fontSize: 14),
                          ),
                        if (_mobileController.text.isNotEmpty)
                          Text(
                            _mobileController.text,
                            style: TextStyle(fontSize: 14),
                          ),
                        // Only show social media and description in business profile
                        if (!isPersonal) ...[
                          if (_socialMediaController.text.isNotEmpty)
                            Text(
                              _socialMediaController.text,
                              style: TextStyle(fontSize: 14, color: Colors.blue),
                            ),
                          if (_descriptionController.text.isNotEmpty)
                            Text(
                              _descriptionController.text,
                              style: TextStyle(fontSize: 14),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
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
        color: Colors.grey.shade200,
      ),
      child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
          ? Icon(
        Icons.person,
        color: Colors.grey.shade400,
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
    if (widget.isPaidUser) {
      // Normal text field for paid users
      return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}), // Update preview in real-time
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      );
    } else {
      // Locked text field for non-paid users
      return InkWell(
        onTap: _navigateToSubscription,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
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
                    color: Colors.grey,
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
    return Scaffold(
      appBar: AppBar(
        
          leading: GestureDetector(child: Icon(Icons.arrow_back_ios),
      onTap: () {
        Navigator.pop(context);
      },),
        title: Text('Profile Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Tab Bar
          Container(

            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Personal'),
                Tab(text: 'Business'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.blue,
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter your name',
          ),

          SizedBox(height: 16),

          Text(
            'Mobile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _mobileController,
            hintText: 'Enter your mobile number',
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 16),

          Text(
            'Location',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: 'Enter your location',
          ),

          // SizedBox(height: 16),
          //
          // Text(
          //   'Description',
          //   style: TextStyle(fontWeight: FontWeight.bold),
          // ),
          // SizedBox(height: 8),
          // _buildTextField(
          //   controller: _descriptionController,
          //   hintText: 'Enter a short description or message',
          //   maxLines: 3,
          // ),

          SizedBox(height: 24),

          // Profile Photo Section
          Text(
            'Profile Photo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildProfilePhotoWidget(),
              SizedBox(width: 16),
              TextButton(
                onPressed: _pickImage,
                child: Text('Change photo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
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
            'Template Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildTemplatePreview(isPersonal: true),

          SizedBox(height: 24),

          // Display Options - Only for paid users
          if (widget.isPaidUser) ...[
            Text(
              'Display Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Show Info Box Toggle
            Row(
              children: [
                Text('Show Info Box'),
                Spacer(),
                Switch(
                  value: _showInfoBox,
                  onChanged: (value) {
                    setState(() {
                      _showInfoBox = value;
                    });
                  },
                ),
              ],
            ),

            // Background Color Selection
            if (_showInfoBox) ...[
              SizedBox(height: 8),
              Text('Background Color'),
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
                              ? Colors.blue
                              : Colors.grey,
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
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 1,
                    side: BorderSide(color: Colors.grey),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEditScreen,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter your name',
          ),

          SizedBox(height: 16),

          Text(
            'Company Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _companyNameController,
            hintText: 'Enter your company name',
          ),

          SizedBox(height: 16),

          Text(
            'Mobile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _mobileController,
            hintText: 'Enter your mobile number',
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 16),

          Text(
            'Location',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _locationController,
            hintText: 'Enter your business location',
          ),

          SizedBox(height: 16),

          // New Social Media field
          Text(
            'Social Media Handle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _socialMediaController,
            hintText: 'Enter your social media handle',
          ),

          SizedBox(height: 16),

          Text(
            'Product Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            hintText: 'Enter a business description or tagline',
            maxLines: 3,
          ),

          SizedBox(height: 24),

          Text(
            'Logo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildProfilePhotoWidget(),
              SizedBox(width: 16),
              TextButton(
                onPressed: _pickImage,
                child: Text('Change logo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
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
            'Template Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          _buildTemplatePreview(isPersonal: false),

          SizedBox(height: 24),

          // Display Options - Only for paid users
          if (widget.isPaidUser) ...[
            Text(
              'Display Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // Show Info Box Toggle
            Row(
              children: [
                Text('Show Info Box'),
                Spacer(),
                Switch(
                  value: _showInfoBox,
                  onChanged: (value) {
                    setState(() {
                      _showInfoBox = value;
                    });
                  },
                ),
              ],
            ),

            // Background Color Selection
            if (_showInfoBox) ...[
              SizedBox(height: 8),
              Text('Background Color'),
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
                              ? Colors.blue
                              : Colors.grey,
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
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 1,
                    side: BorderSide(color: Colors.grey),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToEditScreen,
                  child: Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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