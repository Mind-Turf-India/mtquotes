import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtquotes/screens/Create_Screen/components/details_screen.dart';
import 'package:mtquotes/screens/Payment_Screen/subscription_popup.dart';
import 'package:mtquotes/screens/Templates/components/recent/recent_service.dart';
import 'package:mtquotes/screens/User_Home/components/Categories/category_screen.dart';
import 'package:mtquotes/screens/User_Home/components/templates_list.dart';
import 'package:mtquotes/screens/navbar_mainscreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../l10n/app_localization.dart';
import '../../providers/text_size_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/theme_provider.dart';
import '../Create_Screen/edit_screen_create.dart';
import '../Templates/components/festivals/festival_handler.dart';
import '../Templates/components/festivals/festival_post.dart';
import '../Templates/components/festivals/festival_service.dart';
import '../Templates/components/template/quote_template.dart';
import '../Templates/components/template/template_handler.dart';
import '../Templates/components/template/template_service.dart';
import '../Templates/components/template/template_section.dart';
import 'components/Search/filter_screen.dart';
import 'components/Search/search_service.dart';
import 'components/tapp_effect.dart';

class TemplateFilters {
final bool? isPaid;  // null means both
final double minRating;
final String? language;

TemplateFilters({
  this.isPaid,
  this.minRating = 0.0,
  this.language,
});

Map<String, dynamic> toMap() {
  return {
    'isPaid': isPaid,
    'minRating': minRating,
    'language': language,
  };
}

bool get isActive => isPaid != null || minRating > 0 || language != null;

@override
String toString() {
  return 'TemplateFilters(isPaid: $isPaid, minRating: $minRating, language: $language)';
}
}

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final TemplateService _templateService = TemplateService();
  final SearchService _searchService = SearchService();
  final FestivalService _festivalService = FestivalService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FilterService _filterService = FilterService();

  List<FestivalPost> _festivalPosts = [];
  bool _loadingFestivals = false;

  bool _speechEnabled = false;
  bool _isListening = false;
  List<QuoteTemplate> _searchResults = [];
  bool _isSearching = false;

  // Filter state
  TemplateFilters _filters = TemplateFilters();
  bool _filtersActive = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
    _searchController.addListener(_onSearchChanged);
    _fetchFestivalPosts();
    // _addLanguageFieldToDocuments();
    _filters = TemplateFilters();
    _filtersActive = false;
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
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechResult(result) {
    if (mounted) {
      setState(() {
        _searchController.text = result.recognizedWords;
      });
    }
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
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
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
          _festivalPosts = [];
          for (var festival in festivals) {
            _festivalPosts.addAll(FestivalPost.multipleFromFestival(festival));
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

  // Updated to use Cloud Function for filtering
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {

      List<QuoteTemplate> templates = await _filterService.filterTemplates(query, _filters);

      if (mounted) {
        setState(() {
          _searchResults = templates;
          _isSearching = false;
        });
      }

      print('Found ${templates.length} search results');
    } catch (e) {
      print('Error in search: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  // Add this method to your SearchScreen class
  // Future<void> _addLanguageField() async {
  //   try {
  //     final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('addLanguageField');
  //     final result = await callable.call({
  //       'defaultLanguage': 'en'
  //     });
  //     print('Language field added result: ${result.data}');
  //   } catch (e) {
  //     print('Error adding language field: $e');
  //   }
  // }


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

  // Show filter bottom sheet
  void _showFilterBottomSheet() {
    print('Current filters: $_filters');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  // Build filter bottom sheet widget
  Widget _buildFilterBottomSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textSizeProvider = Provider.of<TextSizeProvider>(context, listen: false);
    double fontSize = textSizeProvider.fontSize;

    // Create a temporary copy of current filters
    TemplateFilters tempFilters = TemplateFilters(
      isPaid: _filters.isPaid,
      minRating: _filters.minRating,
      language: _filters.language,
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(isDarkMode),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDarkMode),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.getIconColor(isDarkMode),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        context.loc.filters,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize + 6,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              SizedBox(height: 20,),

              // Filter options
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free filter
                      _buildFilterOption(
                        title: context.loc.free,
                        isSelected: tempFilters.isPaid == false,
                        isDarkMode: isDarkMode,
                        fontSize: fontSize,
                        onTap: () {
                          setState(() {
                            tempFilters = TemplateFilters(
                              isPaid: tempFilters.isPaid == false ? null : false,
                              minRating: tempFilters.minRating,
                              language: tempFilters.language,
                            );
                          });
                        },
                      ),

                      // Premium filter
                      _buildFilterOption(
                        title: context.loc.premium,
                        isSelected: tempFilters.isPaid == true,
                        isDarkMode: isDarkMode,
                        fontSize: fontSize,
                        onTap: () {
                          setState(() {
                            tempFilters = TemplateFilters(
                              isPaid: tempFilters.isPaid == true ? null : true,
                              minRating: tempFilters.minRating,
                              language: tempFilters.language,
                            );
                          });
                        },
                      ),

                      // Ratings filter
                      _buildFilterOption(
                        title: context.loc.ratings,
                        subtitle: tempFilters.minRating > 0
                            ? '${tempFilters.minRating.toInt()} stars and above'
                            : null,
                        isSelected: tempFilters.minRating > 0,
                        isDarkMode: isDarkMode,
                        fontSize: fontSize,
                        onTap: () {
                          _showRatingPicker(context, tempFilters, (rating) {
                            setState(() {
                              tempFilters = TemplateFilters(
                                isPaid: tempFilters.isPaid,
                                minRating: rating,
                                language: tempFilters.language,
                              );
                            });
                          });
                        },
                      ),

                      // Language filter
                      _buildFilterOption(
                        title: context.loc.language,
                        subtitle: tempFilters.language != null
                            ? _getLanguageName(tempFilters.language!)
                            : null,
                        isSelected: tempFilters.language != null,
                        isDarkMode: isDarkMode,
                        fontSize: fontSize,
                        onTap: () {
                          _showLanguagePicker(context, tempFilters, (lang) {
                            setState(() {
                              tempFilters = TemplateFilters(
                                isPaid: tempFilters.isPaid,
                                minRating: tempFilters.minRating,
                                language: lang,
                              );
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getBackgroundColor(isDarkMode),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                          ),
                        ),
                        child: Text(
                          context.loc.discard,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getTextColor(isDarkMode),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Apply filters
                          _applyFilters(tempFilters);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          context.loc.apply,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Apply the filters and perform search
  void _applyFilters(TemplateFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _filtersActive = newFilters.isActive;
    });

    // If there's a search term, perform search with the new filters
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch(_searchController.text.trim());
    }
    // If no search term but filters are active, perform an empty search to apply filters
    else if (_filtersActive) {
      _performSearch("");
    }
    // If no search term and no filters, clear results
    else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  // Show rating picker dialog
  void _showRatingPicker(BuildContext context, TemplateFilters currentFilters, Function(double) onSelect) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        title: Text(
          context.loc.selectMinimumRating,
          style: GoogleFonts.poppins(
            color: AppColors.getTextColor(isDarkMode),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option to clear rating filter
            ListTile(
              title: Text(
                context.loc.allRatings,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextColor(isDarkMode),
                ),
              ),
              onTap: () {
                onSelect(0);
                Navigator.pop(context);
              },
            ),

            // Rating options (1-5 stars)
            for (int i = 1; i <= 5; i++)
              ListTile(
                title: Row(
                  children: List.generate(
                    i,
                        (index) => Icon(Icons.star, color: Colors.amber, size: 20),
                  ),
                ),
                onTap: () {
                  onSelect(i.toDouble());
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Show language picker dialog
  void _showLanguagePicker(BuildContext context, TemplateFilters currentFilters, Function(String?) onSelect) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    // Language options with codes
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'te': 'Telugu',
      'gu': 'Gujarati',
      'mr': 'Marathi',
      'or': 'Oridiya',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getBackgroundColor(isDarkMode),
        title: Text(
          context.loc.selectLanguage,
          style: GoogleFonts.poppins(
            color: AppColors.getTextColor(isDarkMode),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Option to clear language filter
              ListTile(
                title: Text(
                  context.loc.allLanguages,
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                onTap: () {
                  onSelect(null);
                  Navigator.pop(context);
                },
              ),

              // Language options
              ...languages.entries.map((entry) =>
                  ListTile(
                    title: Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      onSelect(entry.key);
                      Navigator.pop(context);
                    },
                  ),
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get language name from code
  String _getLanguageName(String languageCode) {
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'te': 'Telugu',
      'gu': 'Gujarati',
      'mr': 'Marathi',
      'or': 'Oridiya',
    };

    return languages[languageCode] ?? languageCode;
  }

  // Build a single filter option widget
  Widget _buildFilterOption({
    required String title,
    String? subtitle,
    required bool isSelected,
    required bool isDarkMode,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize - 2,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: AppColors.primaryBlue,
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        ),
      ],
    );
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.getIconColor(isDarkMode),
          ),
          onPressed: () {
            MainScreen.of(context)?.navigateBack(context);
          },
        ),
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
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        'assets/icons/search_button.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                          BlendMode.srcIn,
                        ),
                      ),
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
                                _filtersActive = false;
                                _filters = TemplateFilters();
                              });
                            },
                          ),
                        // New filter icon
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: _filtersActive
                                  ? AppColors.primaryBlue
                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            onPressed: _showFilterBottomSheet,
                          ),
                        IconButton(
                          icon: _isListening
                              ? SvgPicture.asset(
                            'assets/icons/microphone open.svg',
                            width: 20,
                            height: 34,
                            colorFilter: ColorFilter.mode(
                              AppColors.primaryBlue,
                              BlendMode.srcIn,
                            ),
                          )
                              : SvgPicture.asset(
                            'assets/icons/microphone close.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
                              BlendMode.srcIn,
                            ),
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

              // Filter indicator (only when filters are active)
              if (_filtersActive && !_isSearching && _searchResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_filters.isPaid != null)
                        _buildFilterChip(
                          label: _filters.isPaid! ? context.loc.premium : context.loc.free,
                          isDarkMode: isDarkMode,
                          onTap: () {
                            setState(() {
                              _filters = TemplateFilters(
                                isPaid: null,
                                minRating: _filters.minRating,
                                language: _filters.language,
                              );
                              _filtersActive = _filters.isActive;
                              _performSearch(_searchController.text.trim());
                            });
                          },
                        ),
                      if (_filters.minRating > 0)
                        _buildFilterChip(
                          label: '${_filters.minRating.toInt()}+ ${context.loc.ratings}',
                          isDarkMode: isDarkMode,
                          onTap: () {
                            setState(() {
                              _filters = TemplateFilters(
                                isPaid: _filters.isPaid,
                                minRating: 0,
                                language: _filters.language,
                              );
                              _filtersActive = _filters.isActive;
                              _performSearch(_searchController.text.trim());
                            });
                          },
                        ),
                      if (_filters.language != null)
                        _buildFilterChip(
                          label: _getLanguageName(_filters.language!),
                          isDarkMode: isDarkMode,
                          onTap: () {
                            setState(() {
                              _filters = TemplateFilters(
                                isPaid: _filters.isPaid,
                                minRating: _filters.minRating,
                                language: null,
                              );
                              _filtersActive = _filters.isActive;
                              _performSearch(_searchController.text.trim());
                            });
                          },
                        ),
                      // Clear all filters chip
                      _buildFilterChip(
                        label: context.loc.clearAll,
                        isDarkMode: isDarkMode,
                        isAction: true,
                        onTap: () {
                          setState(() {
                            _filters = TemplateFilters();
                            _filtersActive = false;
                            _performSearch(_searchController.text.trim());
                          });
                        },
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 30),

              // Conditional rendering based on search state
              _isSearching
                  ? _buildSearchShimmer(isDarkMode)
                  : _searchController.text.trim().isEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      context.loc.categories,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDarkMode),
                      )
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        categoryCard(
                            'assets/icons/motivation.svg',
                            context.loc.motivational,
                            Colors.green,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/love.svg',
                            context.loc.love,
                            Colors.red,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/funny.svg',
                            context.loc.funny,
                            Colors.orange,
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/friendship.svg',
                            context.loc.friendship,
                            const Color(0xFF9E4282),
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/sad.svg',
                            context.loc.sad,
                            const Color(0xFFAADA0D),
                            isDarkMode
                        ),
                        categoryCard(
                            'assets/icons/patriotic.svg',
                            context.loc.patriotic,
                            const Color(0xFF000088),
                            isDarkMode
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Trending Quotes section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.trendingQuotes,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
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
                            context.loc.viewall,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize - 2,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
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
                        return _buildHorizontalShimmer(isDarkMode);
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: template.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => _buildImageShimmer(isDarkMode),
                                          errorWidget: (context, url, error) => Container(
                                            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (template.isPaid)
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: SvgPicture.asset(
                                                'assets/icons/premium_1659060.svg',
                                                width: 24,
                                                height: 24,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30),

                  // New Template Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.newtemplate,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      TapEffectWidget(
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
                          context.loc.viewall,
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
                        ? _buildHorizontalShimmer(isDarkMode)
                        : _festivalPosts.isEmpty
                        ? Center(
                      child: Text(
                        context.loc.noFestivalsAvailable,
                        style: GoogleFonts.poppins(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                    )
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _festivalPosts.length,
                      itemBuilder: (context, index) {
                        return TapEffectWidget(
                          onTap: () => _handleFestivalPostSelection(_festivalPosts[index]),
                          scaleEffect: 0.92,
                          opacityEffect: 0.85,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _festivalPosts[index].imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                      imageUrl: _festivalPosts[index].imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => _buildImageShimmer(isDarkMode),
                                      errorWidget: (context, url, error) {
                                        print("Image loading error: $error for URL: $url");
                                        return Container(
                                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                          child: Icon(Icons.error),
                                        );
                                      },
                                      cacheKey: "${_festivalPosts[index].id}_image",
                                      maxHeightDiskCache: 500,
                                      maxWidthDiskCache: 500,
                                    )
                                        : Container(
                                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    if (_festivalPosts[index].isPaid)
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: SvgPicture.asset(
                                            'assets/icons/premium_1659060.svg',
                                            width: 24,
                                            height: 24,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
                  : _searchResults.isNotEmpty
                  ? _buildSearchResultsSection(fontSize, isDarkMode)
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    SizedBox(height: 16),
                    Text(
                      context.loc.noResultsFound,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    if (_filtersActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          context.loc.tryRemovingFilters,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize - 2,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for filter chips
  Widget _buildFilterChip({
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAction
              ? Colors.transparent
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
          border: isAction
              ? Border.all(color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isAction
                    ? (isDarkMode ? Colors.grey[400] : Colors.grey[700])
                    : AppColors.getTextColor(isDarkMode),
              ),
            ),
            if (!isAction) ...[
              SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Shimmer widget for loading state of horizontal templates
  Widget _buildHorizontalShimmer(bool isDarkMode) {
    return SizedBox(
      height: 160,
      child: Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.only(right: 12),
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer widget for search results grid
  Widget _buildSearchShimmer(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6, // Show 6 shimmer placeholders
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Shimmer widget for individual image loading
  Widget _buildImageShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildSearchResultsSection(double fontSize, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Search Results (${_searchResults.length})',
          style: GoogleFonts.poppins(
            fontSize: fontSize + 2,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(isDarkMode),
          ),
        ),
        if (_filtersActive && !_isSearching)
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 4),
                Text(
                  context.loc.filters,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize - 2,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
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
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.shade300,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Using CachedNetworkImage with shimmer loading effect
              CachedNetworkImage(
                imageUrl: template.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImageShimmer(isDarkMode),
                errorWidget: (context, url, error) {
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
              // PRO badge
              if (template.isPaid)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/premium_1659060.svg',
                      width: 24,
                      height: 24,
                      color: Colors.amber,
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
      ],
    );
  }

  Widget categoryCard(String svgAssetPath, String title, Color color, bool isDarkMode) {
    return TapEffectWidget(
      scaleEffect: 0.85, // Slightly more pronounced effect
      opacityEffect: 0.99,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              categoryName: title,
              categoryColor: color,
              categorySvgPath: svgAssetPath,
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgAssetPath,
                  width: 40,
                  height: 40,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 5),
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                Text(
                  context.loc.quotes,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
