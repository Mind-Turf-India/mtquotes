import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mtquotes/providers/text_size_provider.dart';
import 'package:mtquotes/screens/Auth_Screen/Login_Screen/login_screen.dart';
import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/Templates/components/template/quote_template.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_screen.dart';
import 'package:mtquotes/screens/Templates/components/template/template_handler.dart';
import 'package:mtquotes/screens/User_Home/components/Doc%20Scanner/doc_scanner.dart';
import 'package:mtquotes/screens/User_Home/components/Invoice/invoice_create.dart';
import 'package:mtquotes/screens/User_Home/components/Notifications/notification_service.dart';
import 'package:mtquotes/screens/User_Home/components/Resume/resume_dashboard.dart';
import 'package:mtquotes/screens/User_Home/components/splash_screen.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';
import 'package:mtquotes/utils/app_theme.dart';
import 'package:mtquotes/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:mtquotes/screens/Onboarding_Screen/onboarding_screen.dart';
import 'package:mtquotes/l10n/app_localization.dart';
import 'firebase_options.dart';

class FontSizeProvider extends ChangeNotifier {
  double _fontSize = 14.0;

  double get fontSize => _fontSize;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await TemplateHandler.initializeTemplatesIfNeeded();

  final prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
  String? savedLocale = prefs.getString('languageCode') ?? 'en';

  User? currentUser = FirebaseAuth.instance.currentUser;

  // Initialize notification service
  await NotificationService.instance.initialize();

  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    NotificationService.instance.handleUserChanged(user?.uid);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => TextSizeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(
        initialRoute: currentUser != null
            ? '/nav_bar'
            : (hasCompletedOnboarding ? 'login' : 'onboarding'),
        locale: Locale(savedLocale),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Locale locale;
  final String initialRoute;


  const MyApp({super.key, required this.initialRoute, required this.locale});

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
    return Consumer2<FontSizeProvider, ThemeProvider>(
      builder: (context, fontSizeProvider, themeProvider, child) {
        // Make sure fontSizeProvider.fontSize is never null by using null-aware access
        final fontSize = fontSizeProvider.fontSize;

        return MaterialApp(
          title: 'Vaky',
          debugShowCheckedModeBanner: false,
          // Start with the splash screen and pass the actual start screen
          //initialRoute: widget.initialRoute,
          locale: _locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: [
            ...localizationDelegates,
            //FlutterQuillLocalizations.delegate,
          ],
          theme: AppTheme.getLightTheme().copyWith(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: fontSize),
              bodyMedium: TextStyle(fontSize: fontSize * 0.9),
              bodySmall: TextStyle(fontSize: fontSize * 0.8),
            ),
          ),
          darkTheme: AppTheme.getDarkTheme().copyWith(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: fontSize),
              bodyMedium: TextStyle(fontSize: fontSize * 0.9),
              bodySmall: TextStyle(fontSize: fontSize * 0.8),
            ),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: SplashScreen(),
          routes: {
            'onboarding': (context) => OnboardingScreen(),
            'login': (context) => LoginScreen(),
            '/subscription': (context) => SubscriptionScreen(),
            '/home': (context) => HomeScreen(),
            '/nav_bar': (context) => MainScreen(),
            '/create_invoice':(context)=> InvoiceCreateScreen(),
            '/document_scanner': (context) => DocScanner(),
            '/resume': (context) => PersonalDetailsScreen(),
            '/invoice': (context) => InvoiceCreateScreen(),
            '/edit': (context) => EditScreen(imageFile: ModalRoute.of(context)!.settings.arguments as File),
            '/profile_details': (context) {
              final args = ModalRoute
                  .of(context)!
                  .settings
                  .arguments as Map<String, dynamic>;
              return DetailsScreen(
                template: args['template'] as QuoteTemplate,
                isPaidUser: args['isPaidUser'] as bool,
              );
            },
          },
        );
      },
    );
  }
}