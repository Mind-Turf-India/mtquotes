import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtquotes/screens/User_Home/components/navbar_mainscreen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  void completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> onboardingData = [
      {
        "title": "Search Templates",
        "image": "assets/search.png"
      },
      {
        "title": "Edit Templates",
        "image": "assets/edit.png"
      },
      {
        "title": "Use It",
        "image": "assets/use it.png"
      },
    ];

    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => currentPage = index),
        itemCount: onboardingData.length,
        itemBuilder: (context, index) => OnboardingPage(
          title: onboardingData[index]['title']!,
          image: onboardingData[index]['image']!,
          isLast: index == onboardingData.length - 1,
          onComplete: completeOnboarding,
          onNext: () => _controller.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String image;
  final bool isLast;
  final VoidCallback onComplete;
  final VoidCallback onNext;

  OnboardingPage({
    required this.title,
    required this.image,
    required this.isLast,
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
          SizedBox(height: 70,),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 40),
          Image.asset(image, height: 300),
          Spacer(),
          ElevatedButton(
            onPressed: isLast ? onComplete : onNext,
            child: Text(isLast ? 'Get Started' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
