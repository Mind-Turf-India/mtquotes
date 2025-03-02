import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TemplatePage extends StatefulWidget {
  @override
  _TemplatePageState createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  int selectedTab = 0;
  final List<String> tabs = ["Category", "Gallery", "Custom Size"];
  final TextEditingController _searchController = TextEditingController();
  File? _image;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async{
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    } else {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _searchController.text = result.recognizedWords;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Template"),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
      ),
      body: Padding(
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.blue : Colors.grey[600],
                    ),
                    onPressed: _toggleListening,
                  ),
                  border: InputBorder.none, // Removed default border
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(tabs.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      tabs[index],
                      style: TextStyle(
                        color: selectedTab == index
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                    selected: selectedTab == index,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blueAccent),
                    showCheckmark: false,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _buildTabContent(selectedTab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (index == 0) ...[
        SizedBox(height: 10),
        Text(
          "Categories",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
              quoteCard("Cookie."),
              quoteCard("Happy"),
              quoteCard("August"),
              quoteCard("Believe in yourself."),
              quoteCard("Never give up."),
            ],
          ),
        ),
      ],
      SizedBox(height: 20),
      if (index == 1) ...[
        SizedBox(
          width: double.infinity,
          child: Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Select Image from Gallery',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,),
                ),
              ),
            ),
          ),
        ),

        if (_image != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Image.file(
              _image!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
      ],
      SizedBox(height: 20),
      if (index == 2) ...[
        SizedBox(
          height: 900,
          child: GridView.builder(
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 9,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                List<String> sizes = [
                  "Standard (4:3)",
                  "Wide (19:6)",
                  "Common (3:2)",
                  "Square (1:1)",
                  "Narrow (5:4)",
                  "Vertical (9:16)",
                  "Ultra Wide (21:9)",
                  "Portrait (10:16)",
                  "Panoramic (32:9)"
                ];
                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(sizes[index],
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                );
              }),
        )
      ]
    ]);
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

  Widget quoteCard(String quote) {
    return Container(
      width: 120,
      margin: EdgeInsets.symmetric(horizontal: 5),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          quote,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}