import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/theme_provider.dart';
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
    Container(), // Placeholder for create button
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

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
                    Flexible(child: _buildCreateOption(context.loc.gallery, Icons.image, isDarkMode)),
                    Flexible(child: _buildCreateOption(context.loc.template, Icons.grid_view, isDarkMode)),
                    Flexible(child: _buildCreateOption(context.loc.downloads, Icons.folder, isDarkMode)),
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

  Widget _buildCreateOption(String label, IconData icon, bool isDarkMode) {
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = AppColors.getBackgroundColor(isDarkMode);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, context.loc.home),
                _buildNavItem(1, Icons.search, Icons.search, context.loc.search),
                // Empty space for the center button
                SizedBox(width: 60),
                _buildNavItem(3, Icons.folder_outlined, Icons.folder, context.loc.files),
                _buildNavItem(4, Icons.person_outline, Icons.person, context.loc.profile),
              ],
            ),
            Center(
              child: GestureDetector(
                onTap: _toggleCreateOptions,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: isDarkMode ? Colors.black54 : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.grey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}