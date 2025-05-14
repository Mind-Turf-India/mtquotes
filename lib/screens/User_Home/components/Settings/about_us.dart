import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        title: Text(
          context.loc.aboutus,
          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo or icon
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent, // Optional: Background color
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SvgPicture.asset(
                    'assets/logo_final.svg',
                    height: 200,
                    width: 220,
                  ),
                ),
              ),
            ),


            // App name and headline
            Center(
              child: Text(
                "Vaky",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  "Your space to feel, express, and connect",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Introduction section
            _buildSection(
              context,
              "About Us",
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                  children: const [
                    TextSpan(
                      text: "We believe words have the power to heal, inspire, and bring people together. Vaky was born from a simple idea: to create a safe, uplifting platform where anyone can share their moods, thoughts, quotes, and heartfelt wishes — whether it's a spark of joy, a cloud of doubt, or a quiet moment of reflection.",
                    ),
                  ],
                ),
              ),
              isDarkMode,
            ),

            // What is Vaky?
            _buildSection(
              context,
              "What is Vaky?",
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                  children: const [
                    TextSpan(
                      text: "Vaky is a mood-sharing and quote-sharing app designed to help you express yourself freely. Whether you're looking for the perfect quote to match your mood, want to post a personal thought, or send an anonymous wish into the universe — Vaky is your outlet.\n\n",
                    ),
                    TextSpan(
                      text: "We make it easy and beautiful to share your inner world, connect with others who resonate, and explore a universe of emotions through words.",
                    ),
                  ],
                ),
              ),
              isDarkMode,
            ),

            // Why We Built Vaky
            _buildSection(
              context,
              "Why We Built Vaky",
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                  children: const [
                    TextSpan(
                      text: "In a world that's always rushing, we wanted to slow things down — even for a few moments — so you can pause and reflect. Vaky was built to be a mindful space where expression matters more than perfection.\n\n",
                    ),
                    TextSpan(
                      text: "Our goal is to empower people to be emotionally honest and feel less alone in their journey, all while celebrating the art of words and human connection.",
                    ),
                  ],
                ),
              ),
              isDarkMode,
            ),

            // What Makes Vaky Unique?
            _buildSection(
              context,
              "What Makes Vaky Unique?",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    "Anonymous & judgment-free sharing",
                    "Express yourself freely without worrying about judgment.",
                    isDarkMode,
                  ),
                  _buildFeatureItem(
                    "Mood-based content suggestions",
                    "Discover quotes and content that match how you feel.",
                    isDarkMode,
                  ),
                  _buildFeatureItem(
                    "Thoughtfully designed for emotional expression",
                    "A platform built with your feelings in mind.",
                    isDarkMode,
                  ),
                  _buildFeatureItem(
                    "A growing community of thoughtful individuals",
                    "Connect with others who share and value authentic expression.",
                    isDarkMode,
                  ),
                  _buildFeatureItem(
                    "Simple, calming interface",
                    "User-friendly experience designed for mindful interaction.",
                    isDarkMode,
                  ),
                ],
              ),
              isDarkMode,
            ),

            const SizedBox(height: 24),

            // Closing message
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Whether you're here to inspire or be inspired, speak or simply listen — Vaky is here for you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Feel it. Share it. Vaky it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Version and copyright
            Center(
              child: Text(
                "Version 1.0.0",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "© 2025 Vaky. All rights reserved.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.star,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "– $description"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}