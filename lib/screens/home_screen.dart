//home screen.dart
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      //App Bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.black),
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              "Hi, ABC\nGood Evening",
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 140,
            ),
            Icon(Icons.notifications_active_outlined, color: Colors.black),
          ],
        ),
      ),

      // App Body
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
                        backgroundColor: Colors.blueAccent
                      ),
                      onPressed: () {},
                      child: Text("Share",
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
              SizedBox(height: 20,),
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
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blueAccent,
        items: [
          CurvedNavigationBarItem(
              child: Icon(
                Icons.home_outlined,
                color: Colors.white,
              ),
              label: 'Home',
              labelStyle: TextStyle(color: Colors.white, fontSize: 12)),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.search,
                color: Colors.white,
              ),
              label: 'Search',
              labelStyle: TextStyle(color: Colors.white, fontSize: 12)),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: 'Create',
              labelStyle: TextStyle(color: Colors.white, fontSize: 12)),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.folder,
                color: Colors.white,
              ),
              label: 'Files',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 12,
              )),
          CurvedNavigationBarItem(
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
              label: 'Profile',
              labelStyle: TextStyle(color: Colors.white, fontSize: 12)),

          
        ],
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
        Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

}