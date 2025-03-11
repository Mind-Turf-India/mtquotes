import 'package:flutter/material.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:mtquotes/screens/Templates/subscription_screen.dart';
import 'package:mtquotes/screens/Templates/template_handler.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/screens/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/User_Home/components/navbar_mainscreen.dart';
import 'package:mtquotes/screens/Onboarding_Screen/onboarding_screen.dart';
import 'package:mtquotes/l10n/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await TemplateHandler.initializeTemplatesIfNeeded();

  final prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
  String? savedLocale = prefs.getString('languageCode') ?? 'en';

  User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => TextSizeProvider()),
      ],
      child: MyApp(
        startScreen: currentUser != null
            ? MainScreen()
            : (hasCompletedOnboarding ? LoginScreen() : OnboardingScreen()),
        locale: Locale(savedLocale),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Widget startScreen;
  final Locale locale;

  const MyApp({super.key, required this.startScreen, required this.locale});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return MaterialApp(
          title: 'Vaky',
          debugShowCheckedModeBanner: false,
          home: widget.startScreen,
          locale: _locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: localizationDelegates,
          theme: ThemeData(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: fontSizeProvider.fontSize),
              bodyMedium: TextStyle(fontSize: fontSizeProvider.fontSize * 0.9),
              bodySmall: TextStyle(fontSize: fontSizeProvider.fontSize * 0.8),
            ),
          ),
          routes: {
            'onboarding': (context) => OnboardingScreen(),
            'login': (context) => LoginScreen(),
            'main': (context) => MainScreen(),
            '/subscription': (context) => SubscriptionScreen(),
            '/home': (context) => HomeScreen(),
          },
        );
      },
    );
  }
}
