import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_service.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:mtquotes/screens/User_Home/files_screen.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:mtquotes/screens/User_Home/components/user_survey.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/theme_provider.dart';
import 'Create_Screen/edit_screen_create.dart';
import 'Create_Screen/template_screen_create.dart';
import 'User_Home/components/Image Upscaling/image_upscaling.dart';
import 'User_Home/components/Resume/resume_selection.dart';
import 'User_Home/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool isCreateExpanded = false;

  // Stack to keep track of navigation history
  final List<int> _navigationStack = [0]; // Start with home screen

  // Create a key to access the HomeScreen state
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

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

  // Handle back button press
  Future<bool> _onWillPop() async {
    // If create menu is expanded, close it
    if (isCreateExpanded) {
      setState(() {
        isCreateExpanded = false;
      });
      return false;
    }

    // If we're already at the home screen or navigation stack is empty
    if (_navigationStack.length <= 1 || _currentIndex == 0) {
      // Show exit confirmation dialog
      final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: Text(
                "Exit Vaky?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  
                ),
              ),
              content: Text(
                'Are you sure you want to exit Vaky?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          ) ??
          false;

      // If user confirmed exit, close the app
      if (shouldExit) {
        // Close the app properly based on platform
        if (Platform.isAndroid) {
          SystemNavigator.pop(); // Exits app on Android
        } else if (Platform.isIOS) {
          exit(0); // Force exits app on iOS
        }
        return true; // This line may not be reached on some platforms
      }
      return false;
    }

    // Pop the current screen from stack
    _navigationStack.removeLast();

    // Navigate to the previous screen
    setState(() {
      _currentIndex = _navigationStack.last;
    });

    return false; // Don't exit the app
  }

  void _navigateToTab(int index) async {
    // If tapping on the same tab that's already selected
    if (index == _currentIndex) {
      // No need to do anything special when tapping same tab
      return;
    }

    // Store the current tab in navigation history
    _navigationStack.add(index);

    // Update the selected index
    setState(() {
      _currentIndex = index;
    });

    // If navigating TO home screen FROM a different screen
    if (index == 0 && _navigationStack[_navigationStack.length - 2] != 0) {
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
  }

  void _toggleCreateOptions() {
    setState(() {
      isCreateExpanded = !isCreateExpanded;
    });
  }

  Widget _buildCreateOption(String label, IconData icon, bool isDarkMode) {
    // If it's the "resumebuilder" option, we'll use the custom image
    if (label == context.loc.resumebuilder) {
      return GestureDetector(
        onTap: () {
          setState(() {
            isCreateExpanded = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PersonalDetailsScreen()),
          );
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
              child: Center(
                child: SvgPicture.asset(
                  'assets/resume_builder.svg',
                  width: 28,
                  height: 28,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none),
            ),
          ],
        ),
      );
    }

    // Otherwise use the default icon implementation
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
            MaterialPageRoute(
                builder: (context) =>
                    EditScreen(title: context.loc.imageeditor)),
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
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none),
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                        Flexible(
                            child: _buildCreateOption(
                                context.loc.gallery, Icons.image, isDarkMode)),
                        Flexible(
                            child: _buildCreateOption(context.loc.template,
                                Icons.grid_view, isDarkMode)),
                        Flexible(
                            child: _buildCreateOption(context.loc.resumebuilder,
                                Icons.folder, isDarkMode)),
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
                  _buildNavItem(0, 'assets/icons/home Inactive.svg',
                      'assets/icons/Home Active.svg', context.loc.home),
                  _buildNavItem(
                      1,
                      'assets/icons/Property 1=Search Inactive.svg',
                      'assets/icons/Property 1=Search Active.svg',
                      context.loc.search),
                  // Empty space for the center button
                  SizedBox(width: 60),
                  _buildNavItem(
                      3,
                      'assets/icons/Property 1=Download Inactive.svg',
                      'assets/icons/Property 1=Download Active.svg',
                      context.loc.files),
                  _buildNavItem(
                      4,
                      'assets/icons/Property 1=User Inactive.svg',
                      'assets/icons/Property 1=user Active.svg',
                      context.loc.profile),
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
      ),
    );
  }

  Widget _buildNavItem(
      int index, String iconPath, String activeIconPath, String label) {
    final isSelected = _currentIndex == index;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Wrap just the icon in Material for circular effect
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToTab(index),
            splashColor: AppColors.primaryBlue.withOpacity(0.3),
            highlightColor: AppColors.primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24), // Circular border radius
            customBorder: CircleBorder(), // Ensure perfect circle
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SvgPicture.asset(
                isSelected ? activeIconPath : iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? AppColors.primaryBlue : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        // Text outside the tap area
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
