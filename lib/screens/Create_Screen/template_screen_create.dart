import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/screens/User_Home/components/Categories/category_screen.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../Templates/components/festivals/festival_card.dart';
import '../Templates/components/festivals/festival_handler.dart';
import '../Templates/components/festivals/festival_post.dart';
import '../Templates/components/festivals/festival_service.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_service.dart';
import '../User_Home/components/templates_list.dart';
import 'edit_screen_create.dart';
import '../User_Home/components/Search/search_service.dart'; // Import the SearchService

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
  bool _loadingFestivals = false;
  List<FestivalPost> _festivalPosts = [];
  final FestivalService _festivalService = FestivalService();
  final SearchService _searchService = SearchService(); // Add SearchService
  
  bool _isSearching = false;
  List<QuoteTemplate> _searchResults = []; // Store search results

  @override
  void initState() {
    super.initState();
    initSpeech();
    _fetchFestivalPosts();
    _searchController.addListener(_onSearchChanged); // Add listener for search input
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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

  // Add a method to handle search text changes
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Add a method to perform the search
  Future<void> _performSearch(String query) async {
  setState(() {
    _isSearching = true;
  });

  try {
    // Use the search service to search across collections
    final searchResults = await _searchService.searchAcrossCollections(query);
    
    // Log raw results
    print('Raw search results count: ${searchResults.length}');
    for (var i = 0; i < searchResults.length; i++) {
      var result = searchResults[i];
      print('Result #${i+1} - ID: ${result.id}, Title: ${result.title}, ImageURL: ${result.imageUrl}');
    }
    
    // Use a map to deduplicate by ID AND filter out items with empty imageUrls
    Map<String, QuoteTemplate> uniqueTemplatesMap = {};

    for (var result in searchResults) {
      // Skip items with empty imageUrl
      if (result.imageUrl == null || result.imageUrl.trim().isEmpty) {
        print('Skipping result with ID: ${result.id} due to empty imageUrl');
        continue;
      }
      
      // Create a QuoteTemplate from SearchResult
      QuoteTemplate template = QuoteTemplate(
        id: result.id,
        title: result.title,
        imageUrl: result.imageUrl,
        category: result.type,
        avgRating: 0,
        isPaid: result.isPaid,
        createdAt: DateTime.now(),
      );

      uniqueTemplatesMap[result.id] = template;
    }

    // Convert map values back to list
    List<QuoteTemplate> templates = uniqueTemplatesMap.values.toList();

    setState(() {
      _searchResults = templates;
      _isSearching = false;
    });

    print('Found ${templates.length} valid, unique search results');
  } catch (e) {
    print('Error in search: $e');
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }
}
  Future<void> _fetchFestivalPosts() async {
    setState(() {
      _loadingFestivals = true;
    });

    try {
      final festivals = await _festivalService.fetchRecentFestivalPosts();

      if (mounted) {
        setState(() {
          // Use the new method to create multiple FestivalPosts from each Festival
          _festivalPosts = [];
          for (var festival in festivals) {
            _festivalPosts.addAll(FestivalPost.multipleFromFestival(festival));
          }

          // Debug prints
          for (var post in _festivalPosts) {
            print("Post: ${post.name}, Image URL: ${post.imageUrl}");
          }

          _loadingFestivals = false;
        });
      }
    } catch (e) {
      print("Error loading festival posts: $e");
      if (mounted) {
        setState(() {
          _loadingFestivals = false;
        });
      }
    }
  }

  void _handleFestivalPostSelection(FestivalPost festival) {
    FestivalHandler.handleFestivalSelection(
      context,
      festival,
      (selectedFestival) {
        // This is what happens when the user gets access to the festival
        // For example, you could navigate to an edit screen:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreen(
              title: 'Edit Festival Post',
              templateImageUrl: selectedFestival.imageUrl,
            ),
          ),
        );
      },
    );
  }

  void _handleTemplateSelection(QuoteTemplate template) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      bool isSubscribed = await _templateService.isUserSubscribed();

      // Hide loading indicator
      Navigator.pop(context);

      if (!template.isPaid || isSubscribed) {
        // Navigate to template editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditScreen(
              title: 'Edit Template',
              templateImageUrl: template.imageUrl,
            ),
          ),
        );
      } else {
        // Show subscription popup
        SubscriptionPopup.show(context);
      }
    } catch (e) {
      // Hide loading indicator in case of error
      Navigator.pop(context);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking subscription: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      // Hide loading indicator
      Navigator.pop(context);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Hide loading indicator in case of error
      Navigator.pop(context);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize tabs with localized strings
    tabs = [context.loc.category, context.loc.gallery, context.loc.customesize];

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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 16),
            
            // Show search results or tabs based on search state
            if (_isSearching)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: _buildSearchResultsSection(fontSize),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          ],
        ),
      ),
    );
  }

  // Add a method to build search results
  Widget _buildSearchResultsSection(double fontSize) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Search Results (${_searchResults.length})',
        style: GoogleFonts.poppins(
          fontSize: fontSize + 2,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 10),
      Expanded(
        child: _searchResults.isEmpty
            ? Center(child: Text('No results found'))
            : GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final template = _searchResults[index];

                  // Skip items with empty imageUrl (should be already filtered out)
                  if (template.imageUrl == null || template.imageUrl.trim().isEmpty) {
                    return SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () => _handleTemplateSelection(template),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Image with error handling
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              template.imageUrl,
                              height: double.infinity,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image for template ${template.id}: $error');
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.error, color: Colors.grey[500]),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Lock icon 
                          if (template.isPaid)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(Icons.lock, color: Colors.amber, size: 16),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ],
  );
}
  Widget _buildTabContent(int index) {
    final textSizeProvider =
        Provider.of<TextSizeProvider>(context); // Listen to changes
    double fontSize = textSizeProvider.fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Tab
        if (index == 0) ...[
          SizedBox(height: 10),
          Text(
            context.loc.categories,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                categoryCard(
                    Icons.lightbulb, context.loc.motivational, Colors.green),
                categoryCard(
                  Icons.favorite,
                  context.loc.love,
                  Colors.red,
                ),
                categoryCard(
                  Icons.emoji_emotions,
                  context.loc.funny,
                  Colors.orange,
                ),
                categoryCard(
                  Icons.people,
                  context.loc.friendship,
                  Colors.blue,
                ),
                categoryCard(
                  Icons.self_improvement,
                  context.loc.life,
                  Colors.purple,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Festival Posts Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.newtemplate,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemplatesListScreen(
                            title: context.loc.newtemplate,
                            listType: TemplateListType.festival,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        fontSize: fontSize - 2,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: _loadingFestivals
                    ? Center(child: CircularProgressIndicator())
                    : _festivalPosts.isEmpty
                        ? Center(
                            child: Text(
                              "No festival posts available",
                              style:
                                  GoogleFonts.poppins(fontSize: fontSize - 2),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _festivalPosts.length,
                            itemBuilder: (context, index) {
                              return FestivalCard(
                                festival: _festivalPosts[index],
                                fontSize: fontSize,
                                onTap: () => _handleFestivalPostSelection(
                                    _festivalPosts[index]),
                              );
                            },
                          ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],

        // Gallery Tab
        if (index == 1) ...[
          SizedBox(
            width: double.infinity,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditScreen(title: '')));
                },
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
                      fontSize: 16,
                    ),
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

        // Custom Size Tab
        if (index == 2) ...[
          SizedBox(
            height: 400, // Changed from 900 to make it more responsive
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
              itemBuilder: (context, gridIndex) {
                List<String> sizes = [
                  context.loc.sizeStandard,
                  context.loc.sizeWide,
                  context.loc.sizeCommon,
                  context.loc.sizeSquare,
                  context.loc.sizeNarrow,
                  context.loc.sizeVertical,
                  context.loc.sizeUltraWide,
                  context.loc.sizePortrait,
                  context.loc.sizePanoramic,
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
                    Text(
                      sizes[gridIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget categoryCard(IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: title,
              categoryColor: color,
              categoryIcon: icon,
            ),
          ),
        );
      },
      child: Padding(
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
            SizedBox(
              height: 5,
              width: 10,
            ),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
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