import 'package:flutter/material.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_interface.dart';

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
                    'Clean, professional layout with a sidebar for skills and contact information.',
                    _buildTemplatePreview('modern'),
                  ),
                  const SizedBox(height: 16),

                  // Classic Template
                  _buildTemplateOption(
                    'classic',
                    'Classic',
                    'Traditional layout with header at top and clean sections below.',
                    _buildTemplatePreview('classic'),
                  ),
                  const SizedBox(height: 16),

                  // Business Template
                  _buildTemplateOption(
                    'business',
                    'Business',
                    'Corporate design with bold header and professional styling.',
                    _buildTemplatePreview('business'),
                  ),
                ],
              ),
            ),
          ),

          // Continue Button
          // Replace the Continue button code with this:
          Container(
  padding: const EdgeInsets.all(16),
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      // Call the callback to notify parent if needed
      widget.onTemplateSelected(_selectedTemplate);
      
      // Navigate to PersonalDetailsScreen with template parameter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalDetailsScreen(
            initialTemplateType: _selectedTemplate,
          ),
        ),
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
      Widget preview,
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
            // Template preview image
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: preview,
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

  // Helper to create mini preview of each template
  Widget _buildTemplatePreview(String templateType) {
    switch (templateType) {
      case 'modern':
        return Column(
          children: [
            // Header block
            Container(
              color: Colors.blueGrey[800],
              width: double.infinity,
              height: 30,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          width: 30,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 2,
                          width: 20,
                          color: Colors.white60,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Two column layout
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 25,
                    color: Colors.blueGrey[50],
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, width: 15, color: Colors.blueGrey),
                        const SizedBox(height: 4),
                        Container(height: 2, width: 12, color: Colors.black54),
                        const SizedBox(height: 2),
                        Container(height: 2, width: 12, color: Colors.black54),
                        const SizedBox(height: 4),
                        Container(height: 3, width: 15, color: Colors.blueGrey),
                        const SizedBox(height: 4),
                        Container(height: 2, width: 12, color: Colors.black54),
                        Container(height: 2, width: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 3, width: 25, color: Colors.blueGrey),
                          const SizedBox(height: 3),
                          Container(height: 2, width: 40, color: Colors.black45),
                          const SizedBox(height: 5),
                          Container(height: 3, width: 25, color: Colors.blueGrey),
                          const SizedBox(height: 3),
                          Container(height: 2, width: 40, color: Colors.black45),
                          Container(height: 2, width: 35, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'classic':
        return Column(
          children: [
            // Header block
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 50,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    width: 30,
                    color: Colors.black45,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 2, width: 12, color: Colors.black38),
                      const SizedBox(width: 2),
                      Container(height: 2, width: 12, color: Colors.black38),
                      const SizedBox(width: 2),
                      Container(height: 2, width: 12, color: Colors.black38),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Container(height: 1, color: Colors.grey),
            const SizedBox(height: 2),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 3, width: 30, color: Colors.black87),
                    const SizedBox(height: 2),
                    Container(height: 2, width: 70, color: Colors.black45),
                    const SizedBox(height: 3),
                    Container(height: 1, color: Colors.grey),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(height: 2, width: 30, color: Colors.black54),
                        Container(height: 2, width: 20, color: Colors.black38),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case 'business':
        return Column(
          children: [
            // Header block
            Container(
              color: Colors.indigo[800],
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                          color: Colors.indigo[800],
                        ),
                      ),
                      const SizedBox(width: 3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 3, width: 35, color: Colors.white),
                          const SizedBox(height: 1),
                          Container(height: 2, width: 25, color: Colors.indigo[100]),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.email, size: 6, color: Colors.indigo[100]),
                      const SizedBox(width: 2),
                      Container(height: 2, width: 20, color: Colors.indigo[100]),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, width: 25, color: Colors.indigo[800]),
                        const SizedBox(height: 1),
                        Container(height: 2, width: 20, color: Colors.indigo[800]),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.all(2),
                      color: Colors.grey[100],
                      child: Container(height: 2, width: double.infinity, color: Colors.black45),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.indigo[800]!,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 2, width: 30, color: Colors.black54),
                            const SizedBox(height: 1),
                            Container(height: 2, width: 20, color: Colors.indigo),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Text('Preview'),
          ),
        );
    }
  }
}