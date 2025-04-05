import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextSizeProvider with ChangeNotifier {
  double _fontSize = 16.0; // Default font size

  double get fontSize => _fontSize;

  TextSizeProvider() {
    _loadFontSize();
  }

  void _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('font_size') ?? 16.0;
    notifyListeners();
  }

  void setFontSize(double size) async {
    _fontSize = size;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    notifyListeners();
  }
}
