//home screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mtquotes/screens/User_Home/components/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mtquotes/screens/User_Home/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "User";
  String greetings = "Good Morning";

  @override
  void initState() {
    super.initState();
    _fetchUserDisplayName();
    _updateGreeting();
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

  void _updateGreeting() {
    int hour = DateTime.now().hour;

    setState(() {
      if (hour >= 5 && hour < 12) {
        greetings = "Good Morning";
      } else if (hour >= 12 && hour < 17) {
        greetings = "Good Afternoon";
      } else if (hour >= 17 && hour < 21) {
        greetings = "Good Evening";
      } else {
        greetings = "Good Night";
      }
    });
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationsSheet(), // Show the bottom sheet
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents navigating back to the login screen
      onPopInvokedWithResult: (didPop, result) {
        // if (!didPop) {
        //   exit(0); // Exits the app when the back button is pressed
        // }
      },
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
                    child: 
                     Icon(LucideIcons.user, color: Colors.black)),
              ),
              SizedBox(width: 20),
              Text(
                "Hi, $userName\n$greetings",
                textAlign: TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent),
                        onPressed: () {},
                        child: Text(
                          "Share",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
      
                // Recent Quotes
                Text("Recents",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Everything requires hard work."),
                      quoteCard("Success comes from daily efforts."),
                      quoteCard("Believe in yourself."),
                      quoteCard("Believe in yourself."),
                      quoteCard("Believe in yourself."),
                    ],
                  ),
                ),
                SizedBox(height: 20),
      
                // Categories
                Text("Categories",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      categoryCard(Icons.lightbulb, "Motivational", Colors.green),
                      categoryCard(Icons.favorite, "Love", Colors.red),
                      categoryCard(Icons.emoji_emotions, "Funny", Colors.orange),
                      categoryCard(Icons.people, "Friendship", Colors.blue),
                      categoryCard(Icons.self_improvement, "Life", Colors.purple),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text("Trending Quotes",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      quoteCard("Everything requires hard work."),
                      quoteCard("Success comes from daily efforts."),
                      quoteCard("Believe in yourself."),
                      quoteCard("Believe in yourself."),
                      quoteCard("Believe in yourself."),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget quoteCard(String text) {
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
            style: GoogleFonts.poppins(fontSize: 12)),
      ),
    );
  }

  Widget categoryCard(IconData icon, String title, Color color) {
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
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
