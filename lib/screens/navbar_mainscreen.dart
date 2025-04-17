import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_screen.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:mtquotes/screens/User_Home/components/user_survey.dart'; // Add this import
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/theme_provider.dart';
import 'Create_Screen/edit_screen_create.dart';
import 'Create_Screen/template_screen_create.dart';
import 'User_Home/components/Image Upscaling/image_upscaling.dart';
import 'User_Home/search_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool isCreateExpanded = false;

  // Create a key to access the HomeScreen state
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // Late initialize the screens with the key
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens list with the key for HomeScreen
    _screens = [
      HomeScreen(key: _homeScreenKey),
      SearchScreen(),
      Container(), // Placeholder for create button
      FilesPage(),
      ProfileScreen(),
    ];
  }

  void _toggleCreateOptions() {
    setState(() {
      isCreateExpanded = !isCreateExpanded;
    });
  }

  Widget _buildCreateOption(String label, IconData icon, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isCreateExpanded = false;
        });

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
            MaterialPageRoute(builder: (context) => PersonalDetailsScreen()),
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
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w300,
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
      body: Stack(
        children: [
          // Main screen content
          _screens[_currentIndex],

          // Overlay for when create is expanded
          if (isCreateExpanded)
            GestureDetector(
              onTap: () {
                setState(() {
                  isCreateExpanded = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

          // Create options when expanded
          if (isCreateExpanded)
            Positioned(
              bottom: 20,
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
                _buildNavItem(0, 'assets/icons/home Inactive.svg', 'assets/icons/Home Active.svg', context.loc.home),
                _buildNavItem(1, 'assets/icons/Property 1=Search Inactive.svg', 'assets/icons/Property 1=Search Active.svg', context.loc.search),
                // Empty space for the center button
                SizedBox(width: 60),
                _buildNavItem(3, 'assets/icons/Property 1=Download Inactive.svg', 'assets/icons/Property 1=Download Active.svg', context.loc.files),
                _buildNavItem(4, 'assets/icons/Property 1=User Inactive.svg', 'assets/icons/Property 1=user Active.svg', context.loc.profile),
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
                    isCreateExpanded ? Icons.close : Icons.add,
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

  Widget _buildNavItem(int index, String iconPath, String activeIconPath, String label) {
    final isSelected = _currentIndex == index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return InkWell(
      onTap: () async {
        // If tapping on the same tab that's already selected
        if (index == _currentIndex) {
          // No need to do anything special when tapping same tab
          return;
        }

        // Store old index before updating to new one
        int oldIndex = _currentIndex;

        // Update the selected index
        setState(() {
          _currentIndex = index;
        });

        // If navigating TO home screen FROM a different screen
        if (index == 0 && oldIndex != 0) {
          print("Returning to home screen from another screen");

          // Increment app open count
          await UserSurveyManager.incrementAppOpenCount();

          // Add a small delay to ensure the counter updated
          await Future.delayed(Duration(milliseconds: 300));

          // Check for survey
          if (_homeScreenKey.currentState != null) {
            await _homeScreenKey.currentState!.checkAndShowSurvey();
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            isSelected ? activeIconPath : iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.primaryBlue : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}