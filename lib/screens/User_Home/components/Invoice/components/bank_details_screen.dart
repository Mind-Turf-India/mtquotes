import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/app_colors.dart';
import '../../../../../utils/theme_provider.dart';

class BankDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDetails;
  final Function(Map<String, dynamic>) onSave;

  const BankDetailsScreen({
    Key? key,
    this.initialDetails,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDetails != null) {
      _ifscController.text = widget.initialDetails!['ifscCode'] ?? '';
      _bankNameController.text = widget.initialDetails!['bankName'] ?? '';
      _accountNumberController.text = widget.initialDetails!['accountNumber'] ?? '';
      _accountHolderController.text = widget.initialDetails!['accountHolderName'] ?? '';
    }
  }

  void _saveDetails() {
    final details = {
      'ifscCode': _ifscController.text,
      'bankName': _bankNameController.text,
      'accountNumber': _accountNumberController.text,
      'accountHolderName': _accountHolderController.text,
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
        title: const Text('Bank Details'),
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
              controller: _ifscController,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'IFSC Code*',
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
              controller: _bankNameController,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Bank Name*',
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
              controller: _accountNumberController,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Account Number*',
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
              controller: _accountHolderController,
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
              decoration: InputDecoration(
                labelText: 'Account Holder Name*',
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDetails,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}