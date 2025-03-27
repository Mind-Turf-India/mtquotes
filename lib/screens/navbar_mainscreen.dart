import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'Create_Screen/edit_screen_create.dart';
import 'Create_Screen/template_screen_create.dart';
import 'User_Home/search_screen.dart';

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
    FilesPage(),
    ProfileScreen(),
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
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideCreateOptions,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(child: _buildCreateOption(context.loc.gallery, Icons.image)),
                    Flexible(child: _buildCreateOption(context.loc.template, Icons.grid_view)),
                    Flexible(child: _buildCreateOption(context.loc.downloads, Icons.folder)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: () {
        _hideCreateOptions();
        if (label == context.loc.template) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TemplatePage()),
          );
        } else if (label == context.loc.gallery) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditScreen(title: context.loc.imageeditor)),
          );
        } else if (label == context.loc.downloads) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FilesPage()),
          );
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
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blueAccent,
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
            label: context.loc.home,
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.search, color: Colors.white),
            label: context.loc.search,
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.add, color: Colors.white),
            label: context.loc.create,
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.folder, color: Colors.white),
            label: context.loc.files,
            labelStyle: TextStyle(color: Colors.white),
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.person, color: Colors.white),
            label: context.loc.profile,
            labelStyle: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}