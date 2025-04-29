import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'components/Search/search_service.dart';
import 'components/tapp_effect.dart';


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
  List<FestivalPost> _festivalPosts = [];
  bool _loadingFestivals = false;


  bool _speechEnabled = false;
  bool _isListening = false;
  List<QuoteTemplate> _searchResults = [];
  bool _isSearching = false;


  @override
  void initState() {
    super.initState();
    initSpeech();
    _searchController.addListener(_onSearchChanged);
    _fetchFestivalPosts();
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
        // Add this check
        setState(() {
          _isListening = true;
        });
      }
    }
  }


  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      // Add this check
      setState(() {
        _isListening = false;
      });
    }
  }


  void _onSpeechResult(result) {
    if (mounted) {
      // Add this check
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
        // Add this check
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
          // Use the method to create multiple FestivalPosts from each Festival
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

// Add this handler method for festival post selection
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


  Future<void> _performSearch(String query) async {
    if (!mounted) return; // Add this early return


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


      if (mounted) {
        // Add this check before setState
        setState(() {
          _searchResults = templates;
          _isSearching = false;
        });
      }


      print('Found ${templates.length} valid, unique search results');
    } catch (e) {
      print('Error in search: $e');
      if (mounted) {
        // Add this check before setState
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
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
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          icon: Icon(Icons.clear,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
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
                            isDarkMode
                                ? Colors.grey[400]!
                                : Colors.grey[600]!,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: _toggleListening,
                      ),
                    ],
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
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextColor(isDarkMode),
                )),
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
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/love.svg',
                                        context.loc.love,
                                        Colors.red,
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/funny.svg',
                                        context.loc.funny,
                                        Colors.orange,
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/friendship.svg',
                                        context.loc.friendship,
                                        const Color(0xFF9E4282),
                                        isDarkMode),
                                    categoryCard(
                                        'assets/icons/sad.svg',
                                        context.loc.sad,
                                        const Color(0xFFAADA0D),
                                        isDarkMode),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.loc.trendingQuotes,
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    Material(
                      color: Colors.transparent, // Keep background transparent
                      borderRadius: BorderRadius.circular(8), // Adjust the roundness here
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TemplatesListScreen(
                                    title: context.loc.trendingQuotes,
                                    listType:
                                    TemplateListType.trending,
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
                    )],
                ),
                SizedBox(height: 10),
                FutureBuilder<List<QuoteTemplate>>(
                  future: _templateService.fetchRecentTemplates(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildHorizontalShimmer(isDarkMode);
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading templates'));
                    } else if (!snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return Center(
                          child: Text('No templates available'));
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
                              onTap: () =>
                                  _handleTemplateSelection(template),
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.black
                                          .withOpacity(0.3)
                                          : Colors.grey.shade300,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Using CachedNetworkImage for better performance and loading indicators
                                      CachedNetworkImage(
                                        imageUrl: template.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            _buildImageShimmer(
                                                isDarkMode),
                                        errorWidget:
                                            (context, url, error) =>
                                            Container(
                                              color: isDarkMode
                                                  ? Colors.grey[700]
                                                  : Colors.grey[200],
                                              child: Center(
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported,
                                                  color: isDarkMode
                                                      ? Colors.grey[500]
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                      ),
                                      // PRO badge if needed
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
                        fontWeight: FontWeight.w700,
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
                      ? _buildHorizontalShimmer(isDarkMode) // Reusing the existing shimmer
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
                                    placeholder: (context, url) =>
                                        _buildImageShimmer(isDarkMode),
                                    errorWidget: (context, url, error) {
                                      print("Image loading error: $error for URL: $url");
                                      return Container(
                                        color: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[300],
                                        child: Icon(Icons.error),
                                      );
                                    },
                                    cacheKey: "${_festivalPosts[index].id}_image",
                                    maxHeightDiskCache: 500,
                                    maxWidthDiskCache: 500,
                                  )
                                      : Container(
                                    color: isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: isDarkMode
                                            ? Colors.grey[500]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  if (_festivalPosts[index].isPaid)
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock,
                                                color: Colors.amber, size: 12),
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
              highlightColor:
              isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
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
              return SizedBox
                  .shrink(); // This will create an empty/invisible widget
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Using CachedNetworkImage with shimmer loading effect
                      CachedNetworkImage(
                        imageUrl: template.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildImageShimmer(isDarkMode),
                        errorWidget: (context, url, error) {
                          return Container(
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
      ],
    );
  }


  Widget categoryCard(
      String svgAssetPath, String title, Color color, bool isDarkMode) {
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
            SizedBox(
              height: 5,
            ),
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
