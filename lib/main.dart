
import 'package:flutter/material.dart';
import 'package:mtquotes/screens/home_screen.dart';
import 'package:mtquotes/screens/main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen()
    );
  }
}