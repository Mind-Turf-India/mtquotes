import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';

class MyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDetails;
  final Function(Map<String, dynamic>)? onSave;

  const MyDetailsScreen({
    Key? key,
    this.initialDetails,
    this.onSave,
  }) : super(key: key);

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _logoPath;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetails != null) {
      _gstController.text = widget.initialDetails!['gstNumber'] ?? '';
      _companyNameController.text = widget.initialDetails!['companyName'] ?? '';
      _mobileController.text = widget.initialDetails!['mobileNumber'] ?? '';
      _addressController.text = widget.initialDetails!['address'] ?? '';
      _cityController.text = widget.initialDetails!['city'] ?? '';
      _stateController.text = widget.initialDetails!['state'] ?? '';
      _pincodeController.text = widget.initialDetails!['pincode'] ?? '';
      _panController.text = widget.initialDetails!['panNumber'] ?? '';
      _emailController.text = widget.initialDetails!['email'] ?? '';
      _logoPath = widget.initialDetails!['logoPath'];
    } else {
      // If no initial details are provided, try to load from Firebase
      _loadUserDetails();
    }
  }

  // Get the current user's document ID (email with dots replaced by underscores)
  String get _userDocId {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    String userEmail = _auth.currentUser!.email!;
    return userEmail.replaceAll('.', '_');
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the user document
      DocumentSnapshot doc =
          await _firestore.collection('users')
              .doc(_userDocId)
              .collection('invoice')
              .doc('details').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('myDetails')) {
          final myDetails = data['myDetails'] as Map<String, dynamic>;
          setState(() {
            _gstController.text = myDetails['gstNumber'] ?? '';
            _companyNameController.text = myDetails['companyName'] ?? '';
            _mobileController.text = myDetails['mobileNumber'] ?? '';
            _addressController.text = myDetails['address'] ?? '';
            _cityController.text = myDetails['city'] ?? '';
            _stateController.text = myDetails['state'] ?? '';
            _pincodeController.text = myDetails['pincode'] ?? '';
            _panController.text = myDetails['panNumber'] ?? '';
            _emailController.text = myDetails['email'] ?? '';
            _logoPath = myDetails['logoPath'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDetails() async {
    if (_companyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final details = {
        'gstNumber': _gstController.text,
        'companyName': _companyNameController.text,
        'mobileNumber': _mobileController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'panNumber': _panController.text,
        'email': _emailController.text,
        'logoPath': _logoPath,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(_userDocId)
          .collection('invoice')
          .doc('details')
          .set({'myDetails': details}, SetOptions(merge: true));

      // Call the onSave callback if provided
      if (widget.onSave != null) {
        widget.onSave!(details);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload to Firebase Storage
        final File file = File(pickedFile.path);
        final String fileName =
            'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef =
            _storage.ref().child('users/$_userDocId/logo/$fileName');

        // Upload the file
        final uploadTask = storageRef.putFile(file);
        final taskSnapshot = await uploadTask;

        // Get the download URL
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Update the logo path in state
        setState(() {
          _logoPath = downloadUrl;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading logo: $e')),
        );
      }
    }
  }

  Future<void> _deleteUserDetails() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Details'),
        content: const Text('Are you sure you want to delete your details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Delete the details from Firestore
        await _firestore
            .collection('users')
            .doc(_userDocId)
            .collection('invoice')
            .doc('details')
            .update({'myDetails': FieldValue.delete()});

        // Clear all controllers
        _gstController.clear();
        _companyNameController.clear();
        _mobileController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        _panController.clear();
        _emailController.clear();

        setState(() {
          _logoPath = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details deleted successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _gstController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'GST Number*',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _companyNameController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'My Company Name*',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mobileController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number*',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Address*',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                            decoration: InputDecoration(
                              labelText: 'City*',
                              labelStyle: TextStyle(color: secondaryTextColor),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: dividerColor),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _stateController,
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                            decoration: InputDecoration(
                              labelText: 'State*',
                              labelStyle: TextStyle(color: secondaryTextColor),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: dividerColor),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pincodeController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Pincode*',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _panController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'PAN Number',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Logo Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Logo',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: dividerColor),
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            child: _logoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      _logoPath!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.primaryBlue),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.error,
                                            color: secondaryTextColor,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: secondaryTextColor,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _deleteUserDetails,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Delete'),
                        ),
                        ElevatedButton(
                          onPressed: _saveDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
