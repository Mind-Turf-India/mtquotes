  import 'package:flutter/material.dart';

  class AppColors {
    // Primary colors
    static const Color primaryBlue = Color(0xFF2897FF);
    static const Color primaryGreen = Color(0xFF00D1A7);

    // Gradient
    static const List<Color> primaryGradient = [primaryBlue, primaryGreen];

    // You can add more derived colors here
    static const Color lightBlue = Color(0xFF61B5FF);
    static const Color lightGreen = Color(0xFF4DDFBF);

    // Shades of primary colors (optional)
    static const Color darkBlue = Color(0xFF1E7AD9);
    static const Color darkGreen = Color(0xFF00AB89);

    // Theme specific colors
    // Light theme - ENSURING HIGH CONTRAST
    static const Color lightBackground = Colors.white;
    static const Color lightSurface = Colors.white;
    static const Color lightText = Colors.black87;
    static const Color lightSecondaryText = Colors.black54;
    static const Color lightDivider = Color(0xFFE0E0E0);
    static const Color lightIcon = Colors.black87;

    // Dark theme
    static const Color darkBackground = Color(0xFF121212);
    static const Color darkSurface = Color(0xFF1E1E1E);
    static const Color darkText = Colors.white;
    static const Color darkTextBlack = Colors.black;
    static const Color darkSecondaryText = Colors.white70;
    static const Color darkDivider = Color(0xFF424242);
    static const Color darkIcon = Colors.white;

    // Get colors based on theme
    static Color getBackgroundColor(bool isDarkMode) => isDarkMode ? darkBackground : lightBackground;
    static Color getSurfaceColor(bool isDarkMode) => isDarkMode ? darkSurface : lightSurface;
    static Color getTextColor(bool isDarkMode) => isDarkMode ? darkText : lightText;
    static Color getTextColorWhite(bool isDarkMode) => isDarkMode ? darkTextBlack : lightText;
    static Color getSecondaryTextColor(bool isDarkMode) => isDarkMode ? darkSecondaryText : lightSecondaryText;
    static Color getDividerColor(bool isDarkMode) => isDarkMode ? darkDivider : lightDivider;
    static Color getIconColor(bool isDarkMode) => isDarkMode ? darkIcon : lightIcon;
  }