import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_service.dart';
import '../Templates/subscription_popup.dart';
import 'edit_screen_create.dart';

class TemplatePage extends StatefulWidget {
  @override
  _TemplatePageState createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  int selectedTab = 0;
  List<String> tabs = [];
  final TextEditingController _searchController = TextEditingController();
  File? _image;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  final TemplateService _templateService = TemplateService();

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
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
        SnackBar(content: Text(context.loc.speechRecognitionNotAvailable)),
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
    // Initialize tabs with localized strings
    tabs = [
      context.loc.category,
      context.loc.gallery,
      context.loc.customesize
    ];

    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.loc.template),
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
                  hintText: context.loc.searchquotes,
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
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
    final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
    double fontSize = textSizeProvider.fontSize;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (index == 0) ...[
        SizedBox(height: 10),
        Text(
          context.loc.categories,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              categoryCard(Icons.lightbulb, context.loc.motivational, Colors.green, fontSize),
              categoryCard(Icons.favorite, context.loc.love, Colors.red, fontSize),
              categoryCard(Icons.emoji_emotions, context.loc.funny, Colors.orange, fontSize),
              categoryCard(Icons.people, context.loc.friendship, Colors.blue, fontSize),
              categoryCard(Icons.self_improvement, context.loc.life, Colors.purple, fontSize),
            ],
          ),
        ),
        SizedBox(height: 30),
        Text(
          context.loc.newtemplate + " ✨",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              quoteCard("Cookie.", fontSize),
              quoteCard("Happy", fontSize),
              quoteCard("August", fontSize),
              quoteCard("believeInYourself", fontSize),
              quoteCard("neverGiveUp", fontSize),
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
                  context.loc.selectImageFromGallery,
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
                  context.loc.sizeStandard,
                  context.loc.sizeWide,
                  context.loc.sizeCommon,
                  context.loc.sizeSquare,
                  context.loc.sizeNarrow,
                  context.loc.sizeVertical,
                  context.loc.sizeUltraWide,
                  context.loc.sizePortrait,
                  context.loc.sizePanoramic
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

  Widget categoryCard(IconData icon, String title, Color color, double fontSize) {
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
}