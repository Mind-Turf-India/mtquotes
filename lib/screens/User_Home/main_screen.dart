import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  OverlayEntry? _overlayEntry;
  bool isCreateExpanded = false;

  final List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    Container(),
    Center(child: Text("Files Screen")),
    Center(child: Text("Profile Screen")),
  ];

  void _toggleCreateOptions() {
    if (isCreateExpanded) {
      _hideCreateOptions();
    } else {
      _showCreateOptions();
    }
  }

  void _showCreateOptions() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(child: _buildCreateOption('Gallery', Icons.image)),
                Flexible(child: _buildCreateOption('Template', Icons.grid_view)),
                Flexible(child: _buildCreateOption('Drafts', Icons.folder)),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => isCreateExpanded = true);
  }

  void _hideCreateOptions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => isCreateExpanded = false);
  }

  Widget _buildCreateOption(String label, IconData icon) {
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
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.blue,fontSize: 12, fontWeight: FontWeight.w500,decoration: TextDecoration.none,),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        index: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _toggleCreateOptions();
          } else {
            _hideCreateOptions();
            setState(() => _currentIndex = index);
          }
        },
        items: [
          CurvedNavigationBarItem(
            child: Icon(Icons.home, color: Colors.white),
            label: 'Home',
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.search, color: Colors.white),
            label: 'Search',
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.add, color: Colors.white),
            label: 'Create',
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.folder, color: Colors.white),
            label: 'Files',
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
