import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryGreen,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightText,
        onSurface: AppColors.lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        iconTheme: IconThemeData(color: AppColors.lightIcon),
        titleTextStyle: TextStyle(color: AppColors.lightText, fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightDivider,
      ),
      iconTheme: IconThemeData(
        color: AppColors.lightIcon,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightText),
        bodySmall: TextStyle(color: AppColors.lightSecondaryText),
        titleLarge: TextStyle(color: AppColors.lightText),
        titleMedium: TextStyle(color: AppColors.lightText),
        titleSmall: TextStyle(color: AppColors.lightText),
        labelLarge: TextStyle(color: AppColors.lightText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: AppColors.lightText, fontSize: 12),
        ),
        iconTheme: MaterialStateProperty.all(
          IconThemeData(color: AppColors.lightIcon),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white, // Button text is always white for better visibility
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryGreen,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkText,
        onSurface: AppColors.darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        iconTheme: IconThemeData(color: AppColors.darkIcon),
        titleTextStyle: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkDivider,
      ),
      iconTheme: IconThemeData(
        color: AppColors.darkIcon,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkText),
        bodySmall: TextStyle(color: AppColors.darkSecondaryText),
        titleLarge: TextStyle(color: AppColors.darkText),
        titleMedium: TextStyle(color: AppColors.darkText),
        titleSmall: TextStyle(color: AppColors.darkText),
        labelLarge: TextStyle(color: AppColors.darkText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: AppColors.darkText, fontSize: 12),
        ),
        iconTheme: MaterialStateProperty.all(
          IconThemeData(color: AppColors.darkIcon),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white, // Button text is always white for better visibility
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
    );
  }
}