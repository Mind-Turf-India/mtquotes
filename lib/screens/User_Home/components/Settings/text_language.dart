import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/theme_provider.dart';

class SettingsLanguage extends StatefulWidget {
  const SettingsLanguage({Key? key}) : super(key: key);

  @override
  State<SettingsLanguage> createState() => _SettingsLanguageState();
}

class _SettingsLanguageState extends State<SettingsLanguage> {
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      setState(() {
        _currentLanguage = languageCode;
      });
    }
  }

  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);

    final context = this.context;
    MyAppState? appState = context.findRootAncestorStateOfType<MyAppState>();
    if (appState != null) {
      appState.setLocale(Locale(languageCode));
    }
  }

  @override
  Widget build(BuildContext context) {
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
          context.loc.chooseLanguage,
          style: TextStyle(color: AppColors.getTextColor(isDarkMode)),
        ),
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getIconColor(isDarkMode)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                context.loc.chooseLanguageHere,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildLanguageCard(
                      context: context,
                      title: 'हिन्दी',
                      symbol: 'अ',
                      topSymbol: 'अ',
                      languageCode: 'hi',
                      isSelected: _currentLanguage == 'hi',
                      isDarkMode: isDarkMode,
                    ),
                    _buildLanguageCard(
                      context: context,
                      title: 'English',
                      symbol: 'A',
                      topSymbol: 'a',
                      languageCode: 'en',
                      isSelected: _currentLanguage == 'en',
                      isDarkMode: isDarkMode,
                    ),
                    _buildLanguageCard(
                      context: context,
                      title: 'বাংলা',
                      symbol: 'অ',
                      topSymbol: 'অ',
                      languageCode: 'bn',
                      isSelected: _currentLanguage == 'bn',
                      isDarkMode: isDarkMode,
                    ),
                    _buildLanguageCard(
                      context: context,
                      title: 'తెలుగు',
                      symbol: 'తె',
                      topSymbol: 'తె',
                      languageCode: 'te',
                      isSelected: _currentLanguage == 'te',
                      isDarkMode: isDarkMode,
                    ),
                    _buildLanguageCard(
                      context: context,
                      title: 'ગુજરાતી',
                      symbol: 'ગુ',
                      topSymbol: 'ગુ',
                      languageCode: 'gu',
                      isSelected: _currentLanguage == 'gu',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String title,
    required String symbol,
    required String topSymbol,
    required String languageCode,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () {
        if (languageCode.isNotEmpty) {
          _saveLocale(languageCode);
          setState(() {
            _currentLanguage = languageCode;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.loc.languageChanged(title)),
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.getTextColor(isDarkMode)
                : isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? (isDarkMode
              ? AppColors.getTextColor(isDarkMode).withOpacity(0.15)
              : Colors.black.withOpacity(0.1))
              : (isDarkMode
              ? Colors.grey.shade800
              : Colors.white),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 8,
                  child: Text(
                    topSymbol,
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.primaryBlue.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}