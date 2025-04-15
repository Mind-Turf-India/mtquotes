import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/text_language.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/text_size.dart';
import 'package:provider/provider.dart';
import '../../../../providers/text_size_provider.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.getIconColor(isDarkMode)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.loc.settings,
          style: TextStyle(
              fontSize: fontSize,
              color: AppColors.getTextColor(isDarkMode)
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.getBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Divider(color: AppColors.getDividerColor(isDarkMode)),
            _buildThemeToggle(
                context,
                themeProvider,
                fontSize,
                isDarkMode
            ),
            _buildSettingsOption(
                'assets/icons/translate.svg',
                context.loc.language,
                fontSize,
                isDarkMode,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsLanguage()),
                  );
                }
            ),
            _buildSettingsOption(
                'assets/icons/text-size_5083742.svg',
                context.loc.textsize,
                fontSize,
                isDarkMode,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TextSizeScreen()),
                  );
                }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider, double fontSize, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/light-mode_8051800.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              AppColors.getIconColor(isDarkMode),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              context.loc.theme,
              style: TextStyle(
                  fontSize: fontSize,
                  color: AppColors.getTextColor(isDarkMode)
              ),
            ),
          ),
          Switch(
            value: isDarkMode,
            activeColor: AppColors.primaryBlue,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(String iconPath, String title, double textSize, bool isDarkMode, VoidCallback onTap) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          AppColors.getIconColor(isDarkMode),
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: textSize,
            color: AppColors.getTextColor(isDarkMode)
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.getIconColor(isDarkMode).withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }
}