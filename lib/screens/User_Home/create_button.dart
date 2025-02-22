import 'package:flutter/material.dart';

class CreateBottomSheet extends StatefulWidget {
  @override
  State<CreateBottomSheet> createState() => _CreateBottomSheetState();
}

class _CreateBottomSheetState extends State<CreateBottomSheet> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Expanded options (Gallery, Template, Drafts)
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
                  _buildOptionItem('Gallery', Icons.image),
                  _buildOptionItem('Template', Icons.folder),
                  _buildOptionItem('Drafts', Icons.description),
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

  Widget _buildOptionItem(String label, IconData icon) {
    return Column(
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
          style: TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}