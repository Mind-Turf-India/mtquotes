import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';

class BuyerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDetails;
  final Function(Map<String, dynamic>) onSave;

  const BuyerDetailsScreen({
    Key? key,
    this.initialDetails,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BuyerDetailsScreen> createState() => _BuyerDetailsScreenState();
}

class _BuyerDetailsScreenState extends State<BuyerDetailsScreen> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDetails != null) {
      _customerNameController.text = widget.initialDetails!['customerName'] ?? '';
      _gstController.text = widget.initialDetails!['gstNumber'] ?? '';
      _mobileController.text = widget.initialDetails!['mobileNumber'] ?? '';
      _emailController.text = widget.initialDetails!['email'] ?? '';
      _addressController.text = widget.initialDetails!['address'] ?? '';
      _cityController.text = widget.initialDetails!['city'] ?? '';
      _stateController.text = widget.initialDetails!['state'] ?? '';
      _pincodeController.text = widget.initialDetails!['pincode'] ?? '';
    }
  }

  void _saveDetails() {
    final details = {
      'customerName': _customerNameController.text,
      'gstNumber': _gstController.text,
      'mobileNumber': _mobileController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
    };

    widget.onSave(details);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final dividerColor = AppColors.getDividerColor(isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _customerNameController,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Customer Name*',
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
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
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
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () {
                    // Handle delete
                    Navigator.pop(context);
                  },
                  child: const Text('Delete'),
                ),
                ElevatedButton(
                  onPressed: _saveDetails,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}