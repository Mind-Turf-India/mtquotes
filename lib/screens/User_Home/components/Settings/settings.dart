import 'package:flutter/material.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/text_language.dart';
import 'package:mtquotes/screens/User_Home/components/Settings/text_size.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:provider/provider.dart';

import '../../../../providers/text_size_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Divider(color: Colors.grey.shade300),
            _buildSettingsOption(Icons.brightness_6_outlined, context.loc.theme,fontSize, () {
              Navigator.pop(context);
            }),
            _buildSettingsOption(Icons.language, context.loc.language,fontSize, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsLanguage()),
              );
            }),
            _buildSettingsOption(Icons.text_fields, context.loc.textsize,fontSize, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TextSizeScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String title,double textSize, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: TextStyle(fontSize: textSize),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
