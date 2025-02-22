import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Search",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search quotes...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Icon(Icons.mic, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              // Categories
              SizedBox(height: 30,),
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
              SizedBox(height: 30,),
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
              SizedBox(height: 30,),
              Text("New ✨",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    quoteCard("Cookie."),
                    quoteCard("Happy"),
                    quoteCard("August"),
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