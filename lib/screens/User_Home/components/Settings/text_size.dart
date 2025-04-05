import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';

class TextSizeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double fontSize = context.watch<TextSizeProvider>().fontSize; // Get font size
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        leading: GestureDetector(
          child: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Text Size Adjuster",
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Text Size",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Set up your text size using slider",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.black54,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Ab",
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Ab",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                  Expanded(
                    child: Consumer<TextSizeProvider>(
                      builder: (context, textSizeProvider, child) {
                        return Slider(
                          value: textSizeProvider.fontSize,
                          min: 15,
                          max: 25,
                          divisions: 3,
                          activeColor: AppColors.primaryBlue,
                          inactiveColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                          onChanged: (value) {
                            textSizeProvider.setFontSize(value);
                          },
                        );
                      },
                    ),
                  ),
                  Text(
                    "Ab",
                    style: TextStyle(
                      fontSize: 30,
                      color: AppColors.getTextColor(isDarkMode),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}