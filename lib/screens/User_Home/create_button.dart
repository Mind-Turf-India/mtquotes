import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_service.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/text_size_provider.dart';
import '../Create_screen/template_screen_create.dart';
import 'components/Image Upscaling/image_upscaling.dart';

class CreateBottomSheet extends StatefulWidget {
  @override
  State<CreateBottomSheet> createState() => _CreateBottomSheetState();
}

class _CreateBottomSheetState extends State<CreateBottomSheet> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize; // Dynamically adjust font size

    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: isExpanded ? 80 : 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: isExpanded ? 1.0 : 0.0,
            child: Container(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionItem(context, context.loc.gallery, Icons.image, fontSize),
                  _buildOptionItem(context, context.loc.template, Icons.folder, fontSize),
                  _buildOptionItem(context, context.loc.downloads, Icons.description, fontSize),
                ],
              ),
            ),
          ),
        ),

        // Create Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                duration: Duration(milliseconds: 300),
                turns: isExpanded ? 0.125 : 0, // 45 degrees when expanded
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

 void _navigateToScreen(BuildContext context, Widget screen) {
  setState(() {
    isExpanded = false; // Close the menu when an option is selected
  });
  
  // Replace the current route and remove all previous routes
  Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => screen),
  (route) => route.isFirst, // This keeps only the first route
);
}

  Widget _buildOptionItem(BuildContext context, String label, IconData icon, double fontSize) {
    return GestureDetector(
      onTap: () {
        if (label == context.loc.template) {
          _navigateToScreen(context, TemplatePage());
        } else if (label == context.loc.gallery) {
          _navigateToScreen(context, EditScreen(title: context.loc.imageeditor));
        } else if (label == context.loc.downloads) {
          // _navigateToScreen(context, ImageUpscalingScreen());
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.blue,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}