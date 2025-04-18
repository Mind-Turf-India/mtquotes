import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';

class ResumeSelectionScreen extends StatefulWidget {
  final Function(String) onTemplateSelected;

  const ResumeSelectionScreen({
    Key? key,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  State<ResumeSelectionScreen> createState() => _ResumeSelectionScreenState();
}

class _ResumeSelectionScreenState extends State<ResumeSelectionScreen> {
  String _selectedTemplate = 'modern'; // Default template

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context, _selectedTemplate),
        ),
        title: const Text(
          'Select Template',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a template for your resume',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Modern Template
                  _buildTemplateOption(
                    'modern',
                    'Modern',
                    'Clean, professional layout with a contemporary look.',
                    'assets/images/modern_template_preview.png',
                  ),
                  const SizedBox(height: 16),

                  // Classic Template
                  _buildTemplateOption(
                    'classic',
                    'Classic',
                    'Traditional layout suited for most industries.',
                    'assets/images/classic_template_preview.png',
                  ),
                  const SizedBox(height: 16),

                  // Business Template
                  _buildTemplateOption(
                    'business',
                    'Business',
                    'Formal design ideal for corporate positions.',
                    'assets/images/business_template_preview.png',
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onTemplateSelected(_selectedTemplate);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PersonalDetailsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(
      String templateId,
      String title,
      String description,
      String imagePath,
      ) {
    final isSelected = _selectedTemplate == templateId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = templateId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for template image
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Template Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}