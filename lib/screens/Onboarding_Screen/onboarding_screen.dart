import 'package:flutter/material.dart';
import 'package:mtquotes/screens/Auth_Screen/Login_Screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  void completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);

    // Navigate to LoginScreen and remove OnboardingScreen from navigation stack
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final List<Map<String, String>> onboardingData = [
      {"title": "Search Templates", "image": "assets/search.png"},
      {"title": "Edit Templates", "image": "assets/edit.png"},
      {"title": "Use It", "image": "assets/use it.png"},
    ];

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => currentPage = index),
        itemCount: onboardingData.length,
        itemBuilder: (context, index) => OnboardingPage(
          title: onboardingData[index]['title']!,
          image: onboardingData[index]['image']!,
          isLast: index == onboardingData.length - 1,
          isDarkMode: isDarkMode,
          onComplete: completeOnboarding,
          onNext: () => _controller.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.ease,
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String image;
  final bool isLast;
  final bool isDarkMode;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  OnboardingPage({
    required this.title,
    required this.image,
    required this.isLast,
    required this.isDarkMode,
    required this.onComplete,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 70),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          SizedBox(height: 40),
          // Apply ColorFiltered to make images visible in dark mode if needed
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDarkMode ? Colors.white.withOpacity(0.9) : Colors.transparent,
              isDarkMode ? BlendMode.srcATop : BlendMode.srcOver,
            ),
            child: Image.asset(image, height: 300),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: isLast ? onComplete : onNext,
            child: Text(isLast ? 'Get Started' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}