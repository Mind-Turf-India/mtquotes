import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // List to track which FAQs are expanded
  List<bool> _isExpanded = List.filled(4, false);

  // Text controllers for the message and phone fields
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Phone number to contact on WhatsApp (replace with your number)
  final String phoneNumber = "9220380777"; // Your WhatsApp number without country code

  // Pre-defined message for WhatsApp (optional)
  final String defaultMessage = "Hello, I need support with Vaky app.";

  // FAQ questions and answers
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Is Vaky for Free?',
      'answer': 'Vaky offers both free and paid plans. The free plan includes basic features, while premium features require a subscription.'
    },
    {
      'question': 'How many template can I download?',
      'answer': 'The number of templates you can download depends on your current plan. Free users have limited downloads, while paid users have unlimited access.'
    },
    {
      'question': 'What is sharing limit?',
      'answer': 'Sharing limits vary based on your subscription tier. Check our pricing page for detailed information on sharing capabilities.'
    },
    {
      'question': 'How to use?',
      'answer': 'To use Vaky, first create an account, select a template, customize it to your needs, and then download or share as required.'
    }
  ];

  // Function to open WhatsApp with the given number and message
  Future<void> _openWhatsApp() async {
    String message = _messageController.text.isEmpty ? defaultMessage : _messageController.text;
    // URL encode the message
    message = Uri.encodeComponent(message);

    // Add country code to phone number (replace 91 with your country code)
    String formattedPhone = "91$phoneNumber"; // Add your country code here (91 for India)

    // Creating the WhatsApp URL based on platform
    String whatsappUrl;

    if (Platform.isAndroid) {
      // Android WhatsApp URL - use package name directly
      whatsappUrl = "https://wa.me/$formattedPhone?text=$message";

      try {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // Fallback to alternate method
        final fallbackUrl = "whatsapp://send?phone=$formattedPhone&text=$message";
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(Uri.parse(fallbackUrl));
        } else {
          _showWhatsAppNotInstalledMessage();
        }
      }
    } else if (Platform.isIOS) {
      // iOS WhatsApp URL
      whatsappUrl = "https://wa.me/$formattedPhone?text=$message";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showWhatsAppNotInstalledMessage();
      }
    } else {
      // Web fallback URL
      whatsappUrl = "https://wa.me/$formattedPhone?text=$message";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        _showWhatsAppNotInstalledMessage();
      }
    }
  }

  // Helper method to show WhatsApp not installed message
  void _showWhatsAppNotInstalledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("WhatsApp is not installed on your device"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to save message to Firebase in top-level messages collection
  Future<void> _saveMessageToFirebase() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a message"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your phone number"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You must be logged in to submit a message"),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Format email to use as document ID (replace . with _)
      String formattedEmail = user.email!.replaceAll('.', '_');

      // Reference to Firestore
      final firestore = FirebaseFirestore.instance;

      // Add message to the top-level 'messages' collection
      await firestore.collection('messages').add({
        'userEmail': user.email,
        'userName': user.displayName ?? 'Anonymous',
        'message': _messageController.text,
        'phoneNumber': _phoneController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Show success dialog
      _showSuccessDialog();

      // Clear the message and phone fields
      _messageController.clear();
      _phoneController.clear();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Message Submitted",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Your query will be resolved in few hours",
            style: TextStyle(
              color: textColor.withOpacity(0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "OK",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final surfaceColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Support',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),

                    // Write a Message Title
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: textColor, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Write a message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Message TextField
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        maxLength: 100,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Max 100 words...',
                          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          counterStyle: TextStyle(color: textColor.withOpacity(0.6)),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Phone Number Field
                    Row(
                      children: [
                        Icon(Icons.phone, color: textColor, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Your Phone Number',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    // Submit Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          onPressed: _saveMessageToFirebase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // OR divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: textColor.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: textColor.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // WhatsApp Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap: _openWhatsApp,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/whatsapp_5968841.svg',
                              height: 28,
                              width: 28,
                              colorFilter: ColorFilter.mode(Colors.green, BlendMode.srcIn),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Send Message to WhatsApp',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // FAQs Title
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'FAQ\'s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),

                    // Expandable FAQs
                    ...List.generate(_faqs.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded[index] = !_isExpanded[index];
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: _isExpanded[index]
                                      ? BorderRadius.vertical(top: Radius.circular(12))
                                      : BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _faqs[index]['question']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      ),
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        _isExpanded[index] ? Icons.remove : Icons.add,
                                        color: Theme.of(context).primaryColor,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isExpanded[index])
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                ),
                                child: Text(
                                  _faqs[index]['answer']!,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 20),
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