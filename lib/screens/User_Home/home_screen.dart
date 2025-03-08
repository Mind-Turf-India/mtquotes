import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/Create_Screen/edit_screen_create.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../Templates/quote_template.dart';
import '../Templates/subscription_popup.dart';
import '../Templates/template_section.dart';
import '../Templates/template_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String greetings = "";
  final TemplateService _templateService = TemplateService();

  @override
  void initState() {
    super.initState();
    _fetchUserDisplayName();
  }

  void _fetchUserDisplayName() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      setState(() {
        userName = user.displayName!;
      });
    }
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    bool isSubscribed = await _templateService.isUserSubscribed();

    if (!template.isPaid || isSubscribed) {
      // Navigate to template editor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(title: 'image',),
        ),
      );
    } else {
      // Show subscription popup
      SubscriptionPopup.show(context);
    }
  }


  String _getGreeting(BuildContext context) {
    int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return context.loc.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return context.loc.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return context.loc.goodEvening;
    } else {
      return context.loc.goodNight;
    }
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    greetings = _getGreeting(context);
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize; // Get font size

    return WillPopScope(
      onWillPop: () async => false, // Prevents navigating back to the login screen
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(LucideIcons.user, color: Colors.black)
                ),
              ),
              SizedBox(width: 20),
       Text(
                "Hi, $userName\n$greetings",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              GestureDetector(
                onTap: _showNotificationsSheet,
                child: Icon(
                  LucideIcons.bellRing,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Quote of the Day
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Mental growth is a never-ending journey, embrace it fully.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: fontSize, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent),
                        onPressed: () {},
                        child: Text(
                          context.loc.share,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Recent Quotes
                Text(context.loc.recents,
                    style: GoogleFonts.poppins(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Everything requires hard work.",fontSize),
                      quoteCard("Success comes from daily efforts.",fontSize),
                      quoteCard("Believe in yourself.",fontSize),
                      quoteCard("Believe in yourself.",fontSize),
                      quoteCard("Believe in yourself.",fontSize),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                SizedBox(height: 20),

                // Categories
                Text(context.loc.categories,
                    style: GoogleFonts.poppins(
                        fontSize: fontSize, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryCard(Icons.lightbulb, context.loc.motivational, Colors.green, fontSize),
                      categoryCard(Icons.favorite, context.loc.love, Colors.red,fontSize),
                      categoryCard(Icons.emoji_emotions, context.loc.funny, Colors.orange,fontSize),
                      categoryCard(Icons.people, context.loc.friendship, Colors.blue,fontSize),
                      categoryCard(Icons.self_improvement, context.loc.life, Colors.purple,fontSize),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),

                TemplateSection(
                  title: context.loc.trendingQuotes,
                  fetchTemplates: _templateService.fetchRecentTemplates,
                  fontSize: fontSize,
                  onTemplateSelected: _handleTemplateSelection,
                ),

                SizedBox(height: 30),
                Text(
                  "New ✨",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Cookie.",fontSize),
                      quoteCard("Happy",fontSize),
                      quoteCard("August",fontSize),
                      quoteCard("Believe in yourself.",fontSize),
                      quoteCard("Never give up.",fontSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget quoteCard(String text, double fontSize) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: fontSize - 2)),
      ),
    );
  }

  Widget categoryCard(IconData icon, String title, Color color,double fontSize) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 5),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: fontSize - 2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class FontSizeProvider with ChangeNotifier {
  double _fontSize = 14.0;

  double get fontSize => _fontSize;

  void setFontSize(double newSize) {
    _fontSize = newSize;
    notifyListeners();
  }
}
