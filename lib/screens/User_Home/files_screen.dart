import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'home_screen.dart';
import 'package:mtquotes/screens/User_Home/home_screen.dart';

class FilesPage extends StatefulWidget {
  @override
  _FilesPageState createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  int selectedTab = 0;
  final List<String> tabs = ["Download", "Drafts"];
  final TextEditingController _searchController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Files", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.blue : Colors.grey[600],
                    ),
                    onPressed: _toggleListening,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(tabs.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      tabs[index],
                      style: GoogleFonts.poppins(
                        color: selectedTab == index ? Colors.white : Colors.blueAccent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 1)
          SizedBox(height: 300,),
        //put drafts logic here
        if (index == 0)
          SizedBox(
            height: 900, // Set an appropriate height
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 0.6,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/sample_image.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(Icons.download, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
