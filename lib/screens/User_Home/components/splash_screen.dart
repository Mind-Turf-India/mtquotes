// import 'package:animated_splash_screen/animated_splash_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:mtquotes/utils/theme_provider.dart';
// import 'package:provider/provider.dart';
//
// class GifSplashScreen extends StatelessWidget {
//   final Widget nextScreen;
//
//   const GifSplashScreen({Key? key, required this.nextScreen}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDarkMode = themeProvider.isDarkMode;
//
//     return AnimatedSplashScreen(
//       splash: Image.asset(
//         isDarkMode ? 'assets/dark.gif' : 'assets/light.gif',
//       ),
//       nextScreen: nextScreen,
//       splashIconSize: 250,
//       duration: 1000,
//       splashTransition: SplashTransition.fadeTransition,
//       backgroundColor: isDarkMode ? Colors.black : Colors.white,
//     );
//   }
// }