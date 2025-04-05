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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
                color: AppColors.primaryBlue,
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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          if (index == 2) {
            _toggleCreateOptions();
          } else {
            _hideCreateOptions();
            setState(() {
              _currentIndex = index;
            });
          }
        },
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.getIconColor(isDarkMode)),
            selectedIcon: Icon(Icons.home, color: AppColors.primaryBlue),
            label: context.loc.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.search, color: AppColors.getIconColor(isDarkMode)),
            selectedIcon: Icon(Icons.search, color: AppColors.primaryBlue),
            label: context.loc.search,
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, color: AppColors.getIconColor(isDarkMode)),
            selectedIcon: Icon(Icons.add_circle, color: AppColors.primaryBlue),
            label: context.loc.create,
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, color: AppColors.getIconColor(isDarkMode)),
            selectedIcon: Icon(Icons.folder, color: AppColors.primaryBlue),
            label: context.loc.files,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.getIconColor(isDarkMode)),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryBlue),
            label: context.loc.profile,
          ),
        ],
      ),
    );
  }
}