import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/screens/User_Home/components/Categories/category_screen.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../Create_Screen/edit_screen_create.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_service.dart';
import '../Templates/components/template/template_section.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final TemplateService _templateService = TemplateService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    // Normalize the query for case-insensitive and partial matching
    final normalizedQuery = query.toLowerCase().trim();

    // Collect search results
    List<QuoteTemplate> results = [];

    // Debug: Print collection names to verify
    print('Attempting to search collections...');
    QuerySnapshot collectionsSnapshot = await _firestore.collection('templates').get();
    print('Number of template documents: ${collectionsSnapshot.docs.length}');

    // Search in Templates Collection
    final templateQuery = await _firestore
        .collection('templates')
        .get();

    print('Templates query results: ${templateQuery.docs.length} documents');

    // Search directly in Templates Collection
    for (var doc in templateQuery.docs) {
      final templateData = doc.data();
      print('Template Document Data: $templateData'); // Debug print full document data

      final title = (templateData['title'] as String? ?? '').toLowerCase();
      final description = (templateData['description'] as String? ?? '').toLowerCase();
      
      // More flexible search criteria
      if (title.contains(normalizedQuery) || 
          description.contains(normalizedQuery)) {
        try {
          QuoteTemplate template = QuoteTemplate.fromFirestore(doc);
          results.add(template);
          print('Found matching template: ${template.title}');
        } catch (e) {
          print('Error converting template: $e');
        }
      }
    }

    // Search in Categories and their template subcollections
    final categoriesSnapshot = await _firestore.collection('categories').get();
    print('Number of categories: ${categoriesSnapshot.docs.length}');

    for (var categoryDoc in categoriesSnapshot.docs) {
      try {
        final templatesSnapshot = await categoryDoc.reference
            .collection('templates')
            .get();

        print('Templates in category ${categoryDoc.id}: ${templatesSnapshot.docs.length}');

        for (var templateDoc in templatesSnapshot.docs) {
          final templateData = templateDoc.data();
          final title = (templateData['title'] as String? ?? '').toLowerCase();
          final description = (templateData['description'] as String? ?? '').toLowerCase();

          if (title.contains(normalizedQuery) || 
              description.contains(normalizedQuery)) {
            try {
              QuoteTemplate template = QuoteTemplate.fromFirestore(templateDoc);
              results.add(template);
              print('Found matching template in category: ${template.title}');
            } catch (e) {
              print('Error converting template in category: $e');
            }
          }
        }
      } catch (categoryError) {
        print('Error searching in category: $categoryError');
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    // Debug print final results
    print('Total search results: ${results.length}');
    if (results.isEmpty) {
      print('No results found for query: $query');
    }
  } catch (e) {
    print('Comprehensive search error: $e');
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }
}

  void _handleTemplateSelection(QuoteTemplate template) async {
    bool isSubscribed = await _templateService.isUserSubscribed();

    if (!template.isPaid || isSubscribed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditScreen(title: 'image'),
        ),
      );
    } else {
      SubscriptionPopup.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSizeProvider = Provider.of<TextSizeProvider>(context);
    double fontSize = textSizeProvider.fontSize;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.loc.search,
          style: GoogleFonts.poppins(
            fontSize: fontSize + 6,
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
                    hintText: context.loc.searchquotes,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: fontSize,
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
              SizedBox(height: 30),
              Text(context.loc.categories,
                  style: GoogleFonts.poppins(
                      fontSize: fontSize + 2, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    categoryCard(Icons.lightbulb, context.loc.motivational,
                        Colors.green),
                    categoryCard(Icons.favorite, context.loc.love, Colors.red),
                    categoryCard(
                        Icons.emoji_emotions, context.loc.funny, Colors.orange),
                    categoryCard(
                        Icons.people, context.loc.friendship, Colors.blue),
                    categoryCard(Icons.self_improvement, context.loc.life,
                        Colors.purple),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Conditional rendering based on search state
              _isSearching
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                      ? _buildSearchResultsSection(fontSize)
                      : _searchController.text.isNotEmpty
                          ? Center(child: Text('No results found'))
                          : TemplateSection(
                              title: context.loc.trendingQuotes,
                              fetchTemplates:
                                  _templateService.fetchRecentTemplates,
                              fontSize: fontSize,
                              onTemplateSelected: _handleTemplateSelection,
                            ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the _buildSearchResultsSection method to use new fields
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
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final template = _searchResults[index];
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        template.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                template.category,
                                style: GoogleFonts.poppins(
                                  fontSize: fontSize - 2,
                                  color: Colors.grey,
                                ),
                              ),
                              if (template.avgRating > 0)
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    Text(
                                      template.avgRating.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: fontSize - 2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
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
