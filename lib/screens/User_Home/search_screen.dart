  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
  import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
  import 'package:mtquotes/screens/Templates/components/recent/recent_service.dart';
  import 'package:mtquotes/screens/User_Home/components/Categories/category_screen.dart';
import 'package:mtquotes/screens/User_Home/components/templates_list.dart';
  import 'package:mtquotes/screens/navbar_mainscreen.dart';
  import 'package:provider/provider.dart';
  import 'package:speech_to_text/speech_to_text.dart';
  import '../../l10n/app_localization.dart';
  import '../../providers/text_size_provider.dart';
  import '../../utils/app_colors.dart';
  import '../../utils/theme_provider.dart';
  import '../Create_Screen/edit_screen_create.dart';
  import '../Templates/components/template/quote_template.dart';
  import '../Templates/components/template/template_handler.dart';
  import '../Templates/components/template/template_service.dart';
  import '../Templates/components/template/template_section.dart';
  import 'components/Search/search_service.dart';

  class SearchScreen extends StatefulWidget {
    @override
    State<SearchScreen> createState() => _SearchScreenState();
  }

  class _SearchScreenState extends State<SearchScreen> {
    final TextEditingController _searchController = TextEditingController();
    final SpeechToText _speechToText = SpeechToText();
    final TemplateService _templateService = TemplateService();
    final SearchService _searchService = SearchService();

    bool _speechEnabled = false;
    bool _isListening = false;
    List<QuoteTemplate> _searchResults = [];
    bool _isSearching = false;

    @override
    void initState() {
      super.initState();
      initSpeech();
      _searchController.addListener(_onSearchChanged);
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
          print(
              'Result #${i + 1} - ID: ${result.id}, Title: ${result.title}, ImageURL: ${result.imageUrl}');
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

    void _handleTemplateSelection(QuoteTemplate template) async {
      bool isSubscribed = await _templateService.isUserSubscribed();

      // Add this line to track the template as recently used
      await RecentTemplateService.addRecentTemplate(template);

      if (!template.isPaid || isSubscribed) {
        TemplateHandler.showTemplateConfirmationDialog(
          context,
          template,
          isSubscribed, // Pass the subscription status
        );
      } else {
        SubscriptionPopup.show(context);
      }
    }

    @override
    Widget build(BuildContext context) {
      final textSizeProvider = Provider.of<TextSizeProvider>(context);
      final themeProvider = Provider.of<ThemeProvider>(context);
      final isDarkMode = themeProvider.isDarkMode;
      double fontSize = textSizeProvider.fontSize;

      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.loc.search,
            style: GoogleFonts.poppins(
              fontSize: fontSize + 6,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDarkMode),
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
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                      decoration: InputDecoration(
                        hintText: context.loc.searchquotes,
                        hintStyle: GoogleFonts.poppins(
                          fontSize: fontSize,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        ),
                        prefixIcon: Icon(
                            Icons.search,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                    Icons.clear,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening
                                    ? AppColors.primaryBlue
                                    : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              ),
                              onPressed: _toggleListening,
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                      context.loc.categories,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDarkMode),
                      )
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        categoryCard(Icons.lightbulb, context.loc.motivational, Colors.green, isDarkMode),
                        categoryCard(Icons.favorite, context.loc.love, Colors.red, isDarkMode),
                        categoryCard(Icons.emoji_emotions, context.loc.funny, Colors.orange, isDarkMode),
                        categoryCard(Icons.people, context.loc.friendship, Colors.blue, isDarkMode),
                        categoryCard(Icons.self_improvement, context.loc.life, Colors.purple, isDarkMode),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Conditional rendering based on search state
                  _isSearching
                      ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                      : _searchController.text.trim().isEmpty
                      ? Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.loc.trendingQuotes,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplatesListScreen(
                  title: context.loc.trendingQuotes,
                  listType: TemplateListType.trending,
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
    FutureBuilder<List<QuoteTemplate>>(
      future: _templateService.fetchRecentTemplates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading templates'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No templates available'));
        }
        
        final templates = snapshot.data!;
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Padding(
                padding: EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _handleTemplateSelection(template),
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.shade300,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            template.imageUrl,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (template.isPaid)
                          Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.amber, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  ],
)
                      : _searchResults.isNotEmpty
                      ? _buildSearchResultsSection(fontSize, isDarkMode)
                      : Center(
                    child: Text(
                      'No results found',
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ]),
          ),
        ),
      );
    }

    Widget _buildSearchResultsSection(double fontSize, bool isDarkMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results (${_searchResults.length})',
            style: GoogleFonts.poppins(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7, // Adjusted for better proportions
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final template = _searchResults[index];

              // Skip items with empty imageUrl to prevent the empty box issue
              if (template.imageUrl.isEmpty) {
                return SizedBox.shrink(); // This will create an empty/invisible widget
              }

              return GestureDetector(
                onTap: () => _handleTemplateSelection(template),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.shade300,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Image fills the entire container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          template.imageUrl,
                          height: double.infinity,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Lock icon positioned at the bottom right
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
        ],
      );
    }

    Widget categoryCard(IconData icon, String title, Color color, bool isDarkMode) {
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
                  color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(
                height: 5,
                width: 10,
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }